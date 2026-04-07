from fastapi import FastAPI
from pydantic import BaseModel
import time

app = FastAPI(title="LLM Serving Platform")

class InferenceRequest(BaseModel):
    prompt: str
    max_tokens: int = 256
    temperature: float = 0.7

class InferenceResponse(BaseModel):
    text: str
    tokens_generated: int
    latency_ms: float

@app.post("/v1/generate", response_model=InferenceResponse)
async def generate(request: InferenceRequest):
    start = time.time()
    response_text = f"[CPU stub] Echo: {request.prompt[:50]}..."
    latency = (time.time() - start) * 1000
    return InferenceResponse(
        text=response_text,
        tokens_generated=len(response_text.split()),
        latency_ms=round(latency, 2)
    )

@app.get("/healthz")
async def health():
    return {"status": "ok"}