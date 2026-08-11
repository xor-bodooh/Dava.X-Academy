import json
from pathlib import Path

import chromadb
from openai import OpenAI

from app.config import OPENAI_API_KEY


BACKEND_DIR = Path(__file__).resolve().parent.parent
DATA_FILE = BACKEND_DIR / "data" / "book_summaries.json"
CHROMA_PATH = BACKEND_DIR / "chroma_db"

EMBEDDING_MODEL = "text-embedding-3-small"
COLLECTION_NAME = "book_summaries"


def load_books() -> list[dict]:
    """Load book records from the JSON file."""
    with DATA_FILE.open("r", encoding="utf-8") as file:
        return json.load(file)


def create_embeddings(client: OpenAI, documents: list[str]) -> list[list[float]]:
    """Generate one embedding vector for each document."""
    response = client.embeddings.create(
        model=EMBEDDING_MODEL,
        input=documents,
    )

    return [item.embedding for item in response.data]


def main() -> None:
    """Create or update the ChromaDB collection."""
    if not OPENAI_API_KEY or OPENAI_API_KEY == "your_api_key_here":
        raise RuntimeError(
            "OPENAI_API_KEY is missing or still uses the placeholder value."
        )

    books = load_books()

    documents = [
        f"Title: {book['title']}\n"
        f"Themes: {', '.join(book['themes'])}\n"
        f"Summary: {book['summary']}"
        for book in books
    ]

    ids = [
        f"book-{index}"
        for index in range(len(books))
    ]

    embeddings_client = OpenAI(api_key=OPENAI_API_KEY)
    embeddings = create_embeddings(embeddings_client, documents)

    chroma_client = chromadb.PersistentClient(path=str(CHROMA_PATH))
    collection = chroma_client.get_or_create_collection(
        name=COLLECTION_NAME
    )

    collection.upsert(
        ids=ids,
        documents=documents,
        embeddings=embeddings,
        metadatas=[
            {
                "title": book["title"],
                "themes": ", ".join(book["themes"]),
            }
            for book in books
        ],
    )

    print(f"Stored {len(books)} books in ChromaDB.")
    print(f"Database location: {CHROMA_PATH}")


if __name__ == "__main__":
    main()