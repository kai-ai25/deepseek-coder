import gradio as gr
from src.core.model import load_model
from src.core.executor import execute_code  # 👈 MAKE SURE THIS IMPORT EXISTS

# 🔄 VERIFY MODEL PATH MATCHES YOUR .env
model, tokenizer = load_model()

def respond(message, history):
    # Code execution
    if "```python" in message:
        try:
            result = execute_code(message)
            message += f"\n\nExecution Result:\n{result}"
        except Exception as e:
            message += f"\n⚠️ Execution Error: {str(e)}"
    
    # Generate response
    inputs = tokenizer(message, return_tensors="pt").to(model.device)
    outputs = model.generate(**inputs, max_new_tokens=500)
    return tokenizer.decode(outputs[0], skip_special_tokens=True)

gr.ChatInterface(respond).launch(
    server_port=int(os.getenv("UI_PORT", 7860)),  # 👈 VERIFY PORT
    server_name="0.0.0.0"
)
