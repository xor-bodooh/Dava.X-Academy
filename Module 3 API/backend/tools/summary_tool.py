import json
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = BACKEND_DIR / "data" / "book_summaries.json"


def _load_book_summaries() -> list[dict]:
    """Load all book summaries from the JSON file."""
    with DATA_FILE.open("r", encoding="utf-8") as file:
        return json.load(file)


def get_summary_by_title(title: str) -> str:
    """Return the complete summary for a book title."""
    requested_title = title.strip().casefold()

    for book in _load_book_summaries():
        stored_title = book["title"].strip().casefold()

        if stored_title == requested_title:
            return book["summary"]
        # Casefold for case sensitive
        # The
        # Hobbit
        # the
        # hobbit
        # THE
        # HOBBIT
    return f"No complete summary was found for the title '{title}'."