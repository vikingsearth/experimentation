"""Application configuration loaded from environment variables.

DECISIONS:
- Uses a dataclass for typed, validated config — fail fast on startup if .env is wrong.
- Loads from ../.env (shared across all language implementations).
- SSL: Uses the Netskope combined CA cert bundle for proper certificate
  verification instead of disabling SSL. This is set via environment variables
  that httpx/requests/urllib3 all respect (REQUESTS_CA_BUNDLE, SSL_CERT_FILE).
  The cert lives at a well-known Netskope path on all corporate macOS machines.
"""

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

# Resolve paths relative to this file's location
_PROJECT_ROOT = Path(__file__).resolve().parent.parent  # prepwork/
_PREPWORK_ROOT = _PROJECT_ROOT

# ── Netskope CA cert (corporate proxy) ──────────────────────────────────────
# Instead of disabling SSL verification, we point Python's HTTP stack at the
# Netskope combined CA bundle. This bundle includes both the proxy's own CA
# and all standard root CAs, so it works for all HTTPS destinations.
#
# These env vars are respected by: httpx, requests, urllib3, aiohttp, openai SDK.
# Must be set BEFORE any HTTP client is created.
NETSKOPE_CERT = Path("/Library/Application Support/Netskope/STAgent/download/nscacert_combined.pem")

if NETSKOPE_CERT.is_file():
    os.environ.setdefault("REQUESTS_CA_BUNDLE", str(NETSKOPE_CERT))
    os.environ.setdefault("SSL_CERT_FILE", str(NETSKOPE_CERT))


@dataclass(frozen=True)
class Settings:
    """Immutable application settings validated at construction time."""

    azure_base_url: str
    azure_api_key: str
    model_name: str
    data_dir: Path

    def __post_init__(self):
        if not self.azure_base_url:
            raise ValueError("AZURE_AI_BASE_URL is required in .env")
        if not self.azure_api_key:
            raise ValueError("AZURE_AI_API_KEY is required in .env")
        if not self.data_dir.is_dir():
            raise ValueError(f"Data directory not found: {self.data_dir}")


def load_settings() -> Settings:
    """Load settings from the shared .env file."""
    load_dotenv(_PREPWORK_ROOT / ".env")

    return Settings(
        azure_base_url=os.environ.get("AZURE_AI_BASE_URL", ""),
        azure_api_key=os.environ.get("AZURE_AI_API_KEY", ""),
        model_name=os.environ.get("MODEL_NAME", "gpt-5-4"),
        data_dir=_PREPWORK_ROOT / "data",
    )
