package com.techvista;

import dev.langchain4j.model.openai.OpenAiChatModel;
import dev.langchain4j.service.AiServices;
import dev.langchain4j.service.SystemMessage;
import io.github.cdimascio.dotenv.Dotenv;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.cert.X509Certificate;

/**
 * Java agent — LangChain4J + Azure AI Foundry
 * ---------------------------------------------
 * Minimal AI agent: takes a user question, uses a file-read tool
 * to ground its answer in local data files, and returns a cited response.
 *
 * DECISIONS & REASONING (for walkthrough / interview explainability):
 *
 * 1. Framework: LangChain4J
 *    - The task lists LangChain4J as a preferred framework for Java.
 *    - LangChain4J's AiServices pattern is clean: define an interface,
 *      annotate with @SystemMessage, attach tools, and the framework
 *      handles the tool-calling loop automatically.
 *
 * 2. LLM provider: Azure AI Foundry via LangChain4J's OpenAI integration.
 *    - We use OpenAiChatModel (not AzureOpenAiChatModel) because the Foundry
 *      endpoint is OpenAI-compatible and because the OpenAI module uses OkHttp
 *      which respects JVM SSL settings (important behind corporate proxies).
 *    - Config loaded from ../.env using dotenv-java.
 *
 * 3. Tool: FileReadTool.readFile — reads files from the data/ directory.
 *    - @Tool annotation exposes it to the LLM with a description.
 *    - @P annotation describes each parameter for the function schema.
 *    - Path traversal protection is built in.
 *
 * 4. Agent pattern: AiServices + tool.
 *    - AiServices.builder() creates a proxy that implements our Assistant interface.
 *    - When the LLM returns a tool_call, LangChain4J automatically invokes the
 *      matching @Tool method, feeds the result back, and loops until the LLM
 *      produces a final text response.
 *
 * 5. No Spring Boot: Keeping it minimal — a single main() with no framework
 *    overhead. This is deliberate for an interview demo: less magic, every
 *    line is explainable.
 */
public class Agent {

    // ── AI Service interface ────────────────────────────────────────────────

    interface Assistant {
        @SystemMessage("""
            You are a helpful assistant for TechVista Inc.

            You have access to a readFile tool that can read files in the local data/ directory.
            Available files:
            - company-faq.txt  (company background, leadership, policies)
            - product-docs.txt (CodeLens product documentation, pricing, API)

            RULES:
            1. ALWAYS use the readFile tool to look up information before answering.
               Do not rely on prior knowledge — ground every answer in the file contents.
            2. After reading, cite your source: mention the filename and quote the relevant passage.
            3. If the files don't contain the answer, say so honestly.
            4. Keep answers concise and factual.
            """)
        String chat(String userMessage);
    }

    // ── Main ────────────────────────────────────────────────────────────────

    public static void main(String[] args) {
        // ── SSL workaround for corporate proxy (Netskope) ──────────────────
        // The proxy intercepts HTTPS traffic with a self-signed certificate.
        // Remove this block if not behind a corporate proxy.
        try {
            TrustManager[] trustAll = new TrustManager[]{
                new X509TrustManager() {
                    public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[0]; }
                    public void checkClientTrusted(X509Certificate[] c, String a) {}
                    public void checkServerTrusted(X509Certificate[] c, String a) {}
                }
            };
            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, trustAll, new java.security.SecureRandom());
            SSLContext.setDefault(sc);
        } catch (Exception e) {
            System.err.println("Warning: could not set up SSL workaround: " + e.getMessage());
        }

        // Load config from ../.env
        Path projectRoot = Paths.get("").toAbsolutePath();
        // When run from java/ dir, parent is prepwork/; when run from prepwork/, look for .env there
        Path envDir = projectRoot.getFileName().toString().equals("java")
                ? projectRoot.getParent()
                : projectRoot;

        Dotenv dotenv = Dotenv.configure()
                .directory(envDir.toString())
                .load();

        String baseUrl = dotenv.get("AZURE_AI_BASE_URL");
        String apiKey = dotenv.get("AZURE_AI_API_KEY");

        // Build the chat model pointing at Azure AI Foundry's OpenAI-compatible endpoint.
        // Using OpenAiChatModel (OkHttp) instead of AzureOpenAiChatModel (Netty)
        // because Netty's BoringSSL ignores JVM SSL context settings.
        OpenAiChatModel model = OpenAiChatModel.builder()
                .baseUrl(baseUrl + "/models/")
                .apiKey(apiKey)
                .modelName("gpt-5-4")
                .temperature(0.0)
                .maxCompletionTokens(1024)
                .logRequests(true)
                .logResponses(true)
                .customHeaders(java.util.Map.of("api-key", apiKey))
                .build();

        // Create tool instance pointing at the shared data/ directory
        Path dataDir = envDir.resolve("data");
        FileReadTool fileReadTool = new FileReadTool(dataDir);

        // Wire up the agent: LLM + tool + system prompt → Assistant proxy
        Assistant assistant = AiServices.builder(Assistant.class)
                .chatLanguageModel(model)
                .tools(fileReadTool)
                .build();

        // Get the question
        String question = args.length > 0
                ? String.join(" ", args)
                : "Who founded TechVista and when?";

        System.out.println("\n" + "─".repeat(60));
        System.out.println("Question: " + question);
        System.out.println("─".repeat(60) + "\n");

        // Run the agent — LangChain4J handles the tool loop internally
        String answer = assistant.chat(question);

        System.out.println("\nAnswer:\n" + answer);
        System.out.println("\n" + "─".repeat(60));
    }
}
