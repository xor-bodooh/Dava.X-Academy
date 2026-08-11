from typing import Optional

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.chat_service import recommend_book
from app.config import is_openai_configured


app = FastAPI(
    title="Smart Librarian API",
    description="Backend API for the Smart Librarian chatbot",
    version="1.0.0",
)


app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    recommendation: str
    summary: Optional[str]
    retrieved_books: list[str]


@app.get("/health")
def health_check() -> dict[str, object]:
    """Return the current backend status."""
    return {
        "status": "ok",
        "openai_configured": is_openai_configured(),
    }


@app.post("/api/chat", response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    """Process a user message and return a book recommendation."""
    result = recommend_book(request.message)
    return ChatResponse(**result)