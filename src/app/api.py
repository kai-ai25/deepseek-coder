from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from src.core.model import load_model
import torch

app = FastAPI()
model, tokenizer = load_model()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
)

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
