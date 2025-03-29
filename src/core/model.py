from transformers import AutoModelForCausalLM, AutoTokenizer
import torch
import os

def load_model():
    kwargs = {
        "device_map": "auto",
        "torch_dtype": torch.float16 if os.getenv("MODEL_PRECISION") == "fp16" else torch.bfloat16
    }

    if os.getenv("USE_FLASH_ATTN") == "true":
        kwargs["attn_implementation"] = "flash_attention_2"

    model = AutoModelForCausalLM.from_pretrained(
        "/workspace/models",
        **kwargs
    )
    tokenizer = AutoTokenizer.from_pretrained("/workspace/models")
    return model, tokenizer
