import gradio as gr
from src.core.model import load_model
from src.core.executor import execute_code
import os

model, tokenizer = load_model()

def respond(message, history):
    # Code execution
    if "```python" in message:
        result = execute_code(message)
        message += f"\n\nExecution Result:\n{result}"
    
    # Generate response
    inputs = tokenizer(message, return_tensors="pt").to(model.device)
    outputs = model.generate(**inputs, max_new_tokens=500)
    return tokenizer.decode(outputs[0], skip_special_tokens=True)

gr.ChatInterface(
    respond,
    examples=[
        "How to optimize this Python function?",
        "Explain gradient descent in PyTorch",
        "Debug this code: [paste snippet]"
    ]
).launch(
    server_port=int(os.getenv("UI_PORT")),
    server_name="0.0.0.0"
)
