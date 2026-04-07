/**
 * TypeScript agent — LangGraph.js + Azure AI Foundry
 * ---------------------------------------------------
 * Minimal AI agent: takes a user question, uses a file-read tool
 * to ground its answer in local data files, and returns a cited response.
 *
 * DECISIONS & REASONING (for walkthrough / interview explainability):
 *
 * 1. Framework: @langchain/langgraph (LangGraph.js)
 *    - Same mental model as the Python LangGraph version — explicit graph-based agent loop.
 *    - createReactAgent gives us: LLM → tool calls → tool execution → LLM → done.
 *    - Easy to explain: one function builds the entire agent graph.
 *
 * 2. LLM provider: Azure AI Foundry via @langchain/openai's AzureChatOpenAI.
 *    - The Foundry endpoint is OpenAI-compatible, so AzureChatOpenAI works directly.
 *    - Config loaded from ../.env (shared across all three language implementations).
 *
 * 3. Tool: readFile — reads files from the data/ directory.
 *    - Restricted to data/ via path resolution to prevent path traversal.
 *    - Returns full file content so the LLM can cite specific passages.
 *
 * 4. Grounding: System prompt requires the model to always read files first,
 *    then cite the filename and quote relevant text.
 *
 * 5. Why tsx? Lets us run .ts files directly without a build step — ideal
 *    for a demo/interview setting where speed matters.
 */

import { readFileSync, existsSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import { config } from "dotenv";
import { z } from "zod";
import { tool } from "@langchain/core/tools";
import { ChatOpenAI } from "@langchain/openai";
import { createReactAgent } from "@langchain/langgraph/prebuilt";

// ── Config ──────────────────────────────────────────────────────────────────

const __dirname = dirname(fileURLToPath(import.meta.url));
config({ path: resolve(__dirname, "..", ".env") });

const AZURE_BASE_URL = process.env.AZURE_AI_BASE_URL!;
const AZURE_API_KEY = process.env.AZURE_AI_API_KEY!;
const MODEL_NAME = "gpt-5-4";
const DATA_DIR = resolve(__dirname, "..", "data");

// ── Tool definition ─────────────────────────────────────────────────────────

const readFileTool = tool(
  async ({ path }: { path: string }): Promise<string> => {
    // Security: resolve and verify the file stays within DATA_DIR
    const target = resolve(DATA_DIR, path);
    if (!target.startsWith(resolve(DATA_DIR))) {
      return "Error: access denied — path outside data directory.";
    }
    if (!existsSync(target)) {
      return `Error: file not found — ${path}`;
    }
    return readFileSync(target, "utf-8");
  },
  {
    name: "read_file",
    description:
      "Read the contents of a file in the data/ directory. " +
      "Use this to look up information from local knowledge base files. " +
      "Available files: company-faq.txt, product-docs.txt",
    schema: z.object({
      path: z
        .string()
        .describe('Filename inside the data/ directory, e.g. "company-faq.txt"'),
    }),
  }
);

// ── LLM setup ──────────────────────────────────────────────────────────────

// Azure AI Foundry uses /models/chat/completions (not /openai/deployments/).
// We use ChatOpenAI with a custom base URL to hit the Foundry inference endpoint.
const llm = new ChatOpenAI({
  configuration: {
    baseURL: `${AZURE_BASE_URL}/models`,
    defaultHeaders: { "api-key": AZURE_API_KEY },
  },
  apiKey: AZURE_API_KEY,
  modelName: MODEL_NAME,
  temperature: 0,
  modelKwargs: { max_completion_tokens: 1024 },
});

// ── System prompt ──────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `You are a helpful assistant for TechVista Inc.

You have access to a read_file tool that can read files in the local data/ directory.
Available files:
- company-faq.txt  (company background, leadership, policies)
- product-docs.txt (CodeLens product documentation, pricing, API)

RULES:
1. ALWAYS use the read_file tool to look up information before answering.
   Do not rely on prior knowledge — ground every answer in the file contents.
2. After reading, cite your source: mention the filename and quote the relevant passage.
3. If the files don't contain the answer, say so honestly.
4. Keep answers concise and factual.`;

// ── Agent ──────────────────────────────────────────────────────────────────

const agent = createReactAgent({
  llm,
  tools: [readFileTool],
  prompt: SYSTEM_PROMPT,
});

// ── Main ───────────────────────────────────────────────────────────────────

async function main() {
  const question =
    process.argv.slice(2).join(" ") ||
    "Who founded TechVista and when?";

  console.log(`\n${"─".repeat(60)}`);
  console.log(`Question: ${question}`);
  console.log(`${"─".repeat(60)}\n`);

  const stream = await agent.stream({
    messages: [{ role: "user", content: question }],
  });

  for await (const step of stream) {
    for (const [nodeName, output] of Object.entries(step) as [string, any][]) {
      if (nodeName === "tools") {
        for (const msg of output.messages ?? []) {
          console.log(`[tool: ${msg.name}] returned ${msg.content.length} chars`);
        }
      } else if (nodeName === "agent") {
        for (const msg of output.messages ?? []) {
          if (msg.content) {
            console.log(`\nAnswer:\n${msg.content}`);
          }
          if (msg.tool_calls?.length) {
            for (const tc of msg.tool_calls) {
              console.log(`[calling tool: ${tc.name}(${JSON.stringify(tc.args)})]`);
            }
          }
        }
      }
    }
  }

  console.log(`\n${"─".repeat(60)}`);
}

main().catch(console.error);
