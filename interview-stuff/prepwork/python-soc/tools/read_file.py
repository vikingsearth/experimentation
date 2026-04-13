"""File-reading tool for the AI agent.

DECISIONS:
- Each tool is a standalone module in tools/ so new tools can be added by
  dropping a file — no need to modify agent logic or runtime.
- Path traversal protection: resolve + startswith check prevents the LLM
  from being tricked into reading ../../etc/passwd.
- Returns full file content for small knowledge base files. For large files
  you'd add chunking or pagination.
- The tool factory (create_read_file_tool) takes data_dir as a parameter so
  it's testable and doesn't depend on global state.
"""

from pathlib import Path

from langchain_core.tools import tool


def create_read_file_tool(data_dir: Path):
    """Create a read_file tool bound to the given data directory."""
    resolved_data_dir = data_dir.resolve()

    @tool
    def read_file(path: str) -> str:
        """Read the contents of a file in the data/ directory.

        Use this tool to look up information from local knowledge base files.
        Available files: company-faq.txt, product-docs.txt

        Args:
            path: Filename inside the data/ directory, e.g. "company-faq.txt"
        """
        target = (resolved_data_dir / path).resolve()
        if not str(target).startswith(str(resolved_data_dir)):
            return "Error: access denied — path outside data directory."
        if not target.is_file():
            return f"Error: file not found — {path}"
        return target.read_text(encoding="utf-8")

    return read_file
