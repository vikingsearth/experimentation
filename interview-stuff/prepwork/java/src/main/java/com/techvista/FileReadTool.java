package com.techvista;

import dev.langchain4j.agent.tool.P;
import dev.langchain4j.agent.tool.Tool;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * File-reading tool for the AI agent.
 *
 * DECISIONS & REASONING:
 *
 * 1. LangChain4J uses @Tool annotations to expose methods to the LLM.
 *    The framework automatically generates the JSON schema for tool calling
 *    from the method signature + @P parameter descriptions.
 *
 * 2. Security: we resolve the requested path against DATA_DIR and verify
 *    the result stays inside it. This prevents path traversal attacks
 *    (e.g. "../../etc/passwd").
 *
 * 3. We return the full file content as a String. For small knowledge base
 *    files this is fine; for large files you'd want chunking or pagination.
 */
public class FileReadTool {

    private final Path dataDir;

    public FileReadTool(Path dataDir) {
        this.dataDir = dataDir.toAbsolutePath().normalize();
    }

    @Tool("Read the contents of a file in the data/ directory. " +
          "Use this to look up information from local knowledge base files. " +
          "Available files: company-faq.txt, product-docs.txt")
    public String readFile(
            @P("Filename inside the data/ directory, e.g. 'company-faq.txt'") String path
    ) {
        // Resolve and security-check
        Path target = dataDir.resolve(path).toAbsolutePath().normalize();
        if (!target.startsWith(dataDir)) {
            return "Error: access denied — path outside data directory.";
        }
        if (!Files.isRegularFile(target)) {
            return "Error: file not found — " + path;
        }
        try {
            return Files.readString(target);
        } catch (IOException e) {
            return "Error reading file: " + e.getMessage();
        }
    }
}
