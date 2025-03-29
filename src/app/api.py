from fastapi import FastAPI
from src.core.model import load_model
import torch

app = FastAPI()

# Load model with error handling
try:
    model, tokenizer = load_model()
except Exception as e:
    raise RuntimeError(f"Model loading failed: {str(e)}")

@app.get("/health")
async def health_check():
    return {"status": "ok"}

@app.get("/generate")
async def generate(prompt: str, max_tokens: int = 500):
    inputs = tokenizer(prompt, return_tensors="pt").to(model.device)
    outputs = model.generate(
        **inputs,
        max_new_tokens=max_tokens,
        temperature=0.7,
        do_sample=True
    )
    return {"response": tokenizer.decode(outputs[0], skip_special_tokens=True)}
