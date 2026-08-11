import { FormEvent, useState } from "react";
import "./App.css";

type Sender = "user" | "assistant";

type ChatMessage = {
  sender: Sender;
  text: string;
  summary?: string | null;
};

type ChatResponse = {
  recommendation: string;
  summary: string | null;
  retrieved_books: string[];
};

function App() {
  const [message, setMessage] = useState("");
  const [darkMode, setDarkMode] = useState(true);
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      sender: "assistant",
      text: "Hello! Tell me what kind of book you would like to read.",
    },
  ]);
  const [isLoading, setIsLoading] = useState(false);
function speakMessage(text: string, summary?: string | null) {
  window.speechSynthesis.cancel();

  const content = summary
    ? `${text}. Complete summary: ${summary}`
    : text;

  const utterance = new SpeechSynthesisUtterance(content);
  utterance.lang = "en-US";
  utterance.rate = 0.95;
  utterance.pitch = 1;

  window.speechSynthesis.speak(utterance);
}
  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const trimmedMessage = message.trim();

    if (!trimmedMessage || isLoading) {
      return;
    }

    setMessages((currentMessages) => [
      ...currentMessages,
      { sender: "user", text: trimmedMessage },
    ]);
    setMessage("");
    setIsLoading(true);

    try {
      const response = await fetch("http://127.0.0.1:8000/api/chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ message: trimmedMessage }),
      });

      if (!response.ok) {
        throw new Error("The backend returned an error.");
      }

      const data = (await response.json()) as ChatResponse;

      setMessages((currentMessages) => [
        ...currentMessages,
        {
          sender: "assistant",
          text: data.recommendation,
          summary: data.summary,
        },
      ]);
    } catch (error) {
      setMessages((currentMessages) => [
        ...currentMessages,
        {
          sender: "assistant",
          text:
            error instanceof Error
              ? `Sorry, something went wrong: ${error.message}`
              : "Sorry, something went wrong.",
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <main className={`page ${darkMode ? "dark" : "light"}`}>
      <section className="chat-card">
        <header className="chat-header">
          <button
          className="theme-button"
          onClick={() => setDarkMode((current) => !current)}
          aria-label="Toggle dark mode"
          >
          {darkMode ? "☀︎" : "☾"}
        </button>
          <div>
            <p className="eyebrow">SMART LIBRARIAN</p>
            <h1>Find your next great book.</h1>
            <p className="subtitle">
              Describe a story, theme, or feeling, and I’ll recommend a book.
            </p>
          </div>
          <div className="status">
            <span className="status-dot" />
            Online
          </div>
        </header>

        <section className="messages" aria-live="polite">
          {messages.map((item, index) => (
            <article
              className={`message-row ${item.sender}`}
              key={`${item.sender}-${index}`}
            >

              <div className="message-bubble">
                <p>{item.text}</p>

                {item.summary && (
                  <div className="summary">
                    <h2>Complete summary</h2>
                    <p>{item.summary}</p>
                  </div>
                )}
              </div>
              {item.sender === "assistant" && (
  <button
    className="speak-button"
    onClick={() => speakMessage(item.text, item.summary)}
    type="button"
  >
    🔊 Read aloud
  </button>
)}
            </article>
          ))}

          {isLoading && (
            <article className="message-row assistant">
              <div className="message-bubble loading">
                Searching the library and thinking...
              </div>
            </article>
          )}
        </section>

        <form className="message-form" onSubmit={handleSubmit}>
          <input
            value={message}
            onChange={(event) => setMessage(event.target.value)}
            placeholder="Try: I want a story about friendship and magic"
            aria-label="Your book request"
            disabled={isLoading}
          />
          <button type="submit" disabled={isLoading || !message.trim()}>
            Send
          </button>
        </form>
      </section>
    </main>
  );
}

export default App;