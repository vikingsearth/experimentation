import uuid

from fastapi import FastAPI
from pydantic import BaseModel

from agents import run

app = FastAPI()


class ChatRequest(BaseModel):
    prompt: str
    session_id: str | None = None


class ChatResponse(BaseModel):
    result: str
    session_id: str


@app.post("/chat")
def chat(request: ChatRequest) -> ChatResponse:
    session_id = request.session_id or str(uuid.uuid4())
    result = run(request.prompt, session_id)
    return ChatResponse(result=result, session_id=session_id)
