"""
SSL workaround for corporate environments with self-signed certificates.

Import this module BEFORE any HuggingFace/httpx imports to disable SSL
verification. This is only needed in environments where a corporate proxy
intercepts HTTPS traffic with a self-signed certificate.

Remove this file if you are not behind a corporate proxy.
"""

import os
import ssl
import warnings

# Suppress SSL warnings
warnings.filterwarnings("ignore", message=".*SSL.*")
warnings.filterwarnings("ignore", message=".*Unverified HTTPS.*")

# Disable default SSL verification
ssl._create_default_https_context = ssl._create_unverified_context

# Patch httpx to disable SSL verification (used by huggingface_hub)
try:
    import httpx

    _OriginalClient = httpx.Client

    class _PatchedClient(_OriginalClient):
        def __init__(self, *args, **kwargs):
            kwargs["verify"] = False
            super().__init__(*args, **kwargs)

    httpx.Client = _PatchedClient
except ImportError:
    pass

# Environment variables
os.environ["CURL_CA_BUNDLE"] = ""
os.environ["HF_HUB_DISABLE_TELEMETRY"] = "1"
