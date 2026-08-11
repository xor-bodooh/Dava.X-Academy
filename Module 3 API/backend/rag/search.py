from pathlib import Path

import chromadb
from openai import OpenAI

from app.config import OPENAI_API_KEY


BACKEND_DIR = Path(__file__).resolve().parent.parent
CHROMA_PATH = BACKEND_DIR / "chroma_db"

COLLECTION_NAME = "book_summaries"
EMBEDDING_MODEL = "text-embedding-3-small"


def search_books(
    query: str,
    number_of_results: int = 3,
) -> list[dict]:
    """Find books that are semantically related to the user's query."""
    if not OPENAI_API_KEY or OPENAI_API_KEY == "your_api_key_here":
        raise RuntimeError("OPENAI_API_KEY is not configured.")

    openai_client = OpenAI(api_key=OPENAI_API_KEY)

    embedding_response = openai_client.embeddings.create(
        model=EMBEDDING_MODEL,
        input=query,
    )

    query_embedding = embedding_response.data[0].embedding

    chroma_client = chromadb.PersistentClient(path=str(CHROMA_PATH))
    collection = chroma_client.get_collection(name=COLLECTION_NAME)

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=number_of_results,
        include=["documents", "metadatas", "distances"],
    )

    documents = results["documents"][0]
    metadatas = results["metadatas"][0]
    distances = results["distances"][0]

    return [
        {
            "title": metadata["title"],
            "themes": metadata["themes"],
            "document": document,
            "distance": distance,
        }
        for document, metadata, distance in zip(
            documents,
            metadatas,
            distances,
        )
    ]