import os
from pathlib import Path

from dotenv import load_dotenv


BACKEND_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = BACKEND_DIR / ".env"

load_dotenv(ENV_FILE)

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")


def is_openai_configured() -> bool:
    """Return True only when a real API key has been configured."""
    return bool(
        OPENAI_API_KEY
        and OPENAI_API_KEY != "your_api_key_here"
    )