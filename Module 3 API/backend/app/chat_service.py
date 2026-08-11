import json
import os

from openai import OpenAI

from app.config import OPENAI_API_KEY
from rag.search import search_books
from tools.summary_tool import get_summary_by_title


CHAT_MODEL = os.getenv("OPENAI_CHAT_MODEL", "gpt-4o-mini")


SUMMARY_TOOL = {
    "type": "function",
    "function": {
        "name": "get_summary_by_title",
        "description": (
            "Return the complete summary for an exact book title "
            "from the local book database."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "title": {
                    "type": "string",
                    "description": "The exact title of the recommended book.",
                }
            },
            "required": ["title"],
            "additionalProperties": False,
        },
    },
}


def _build_context(matches: list[dict]) -> str:
    """Convert retrieved books into context for the language model."""
    return "\n\n".join(
        (
            f"Title: {match['title']}\n"
            f"Themes: {match['themes']}\n"
            f"Information: {match['document']}"
        )
        for match in matches
    )


def recommend_book(user_message: str) -> dict:
    """Recommend one book and retrieve its complete summary."""
    if not OPENAI_API_KEY or OPENAI_API_KEY == "your_api_key_here":
        raise RuntimeError("OPENAI_API_KEY is not configured.")

    matches = search_books(user_message, number_of_results=3)
    context = _build_context(matches)

    openai_client = OpenAI(api_key=OPENAI_API_KEY)

    messages = [
        {
            "role": "system",
            "content": (
                "You are a helpful book recommendation assistant. "
                "Recommend exactly one book from the provided context. "
                "Do not invent books or information. "
                "After choosing a book, call get_summary_by_title using "
                "the exact title from the context. "
                "After receiving the tool result, give a friendly explanation "
                "of why the book matches the user's interests."
            ),
        },
        {
            "role": "user",
            "content": (
                f"User request:\n{user_message}\n\n"
                f"Retrieved book context:\n{context}"
            ),
        },
    ]

    first_response = openai_client.chat.completions.create(
        model=CHAT_MODEL,
        messages=messages,
        tools=[SUMMARY_TOOL],
        tool_choice="auto",
    )

    assistant_message = first_response.choices[0].message
    tool_calls = assistant_message.tool_calls or []

    if not tool_calls:
        return {
            "recommendation": assistant_message.content or "",
            "summary": None,
            "retrieved_books": [match["title"] for match in matches],
        }

    messages.append(
        {
            "role": "assistant",
            "content": assistant_message.content,
            "tool_calls": [
                {
                    "id": tool_call.id,
                    "type": "function",
                    "function": {
                        "name": tool_call.function.name,
                        "arguments": tool_call.function.arguments,
                    },
                }
                for tool_call in tool_calls
            ],
        }
    )

    summary = None

    for tool_call in tool_calls:
        if tool_call.function.name != "get_summary_by_title":
            continue

        arguments = json.loads(tool_call.function.arguments)
        title = arguments["title"]
        summary = get_summary_by_title(title)

        messages.append(
            {
                "role": "tool",
                "tool_call_id": tool_call.id,
                "content": summary,
            }
        )

    final_response = openai_client.chat.completions.create(
        model=CHAT_MODEL,
        messages=messages,
    )

    return {
        "recommendation": final_response.choices[0].message.content or "",
        "summary": summary,
        "retrieved_books": [match["title"] for match in matches],
    }