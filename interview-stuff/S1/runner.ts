import { execFile } from "child_process";
import { config } from "dotenv";
import { resolve } from "path";

// Load .env from parent dir (interview-stuff/.env) for local dev.
// In Docker, env vars are passed at runtime instead.
config({ path: resolve(__dirname, "..", ".env") });

export interface RunnerRequest {
  prompt: string;
  sessionId?: string;
}

export interface RunnerResponse {
  result: string;
  sessionId?: string;
}

export function runClaude(request: RunnerRequest): Promise<RunnerResponse> {
  const { prompt, sessionId } = request;

  const args = ["-p", "--model", "claude-haiku-4-5", "--output-format", "json"];

  if (sessionId) {
    args.push("--resume", sessionId);
  }

  args.push(prompt);

  const env = {
    ...process.env,
    ANTHROPIC_BASE_URL: process.env.AZURE_AI_BASE_URL,
    ANTHROPIC_API_KEY: process.env.AZURE_AI_API_KEY,
  };

  return new Promise((resolve, reject) => {
    execFile(
      "claude",
      args,
      { env, maxBuffer: 10 * 1024 * 1024 },
      (error, stdout, stderr) => {
        if (error) {
          reject(new Error(`Claude CLI error: ${stderr || error.message}`));
          return;
        }

        try {
          const parsed = JSON.parse(stdout);
          resolve({
            result: parsed.result ?? stdout.trim(),
            sessionId: parsed.session_id,
          });
        } catch {
          resolve({ result: stdout.trim() });
        }
      }
    );
  });
}
