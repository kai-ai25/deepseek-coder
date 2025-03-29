import ast
import tempfile
from pathlib import Path
import os

SAFE_DIR = Path(os.getenv("SAFE_DIR"))

def validate_code(code: str):
    tree = ast.parse(code)
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            raise ValueError("Imports disabled for security")
        if isinstance(node, ast.Call) and getattr(node.func, "id", None) == "eval":
            raise ValueError("eval() not allowed")

def execute_code(code: str) -> str:
    validate_code(code)
    try:
        # Sandboxed execution logic
        return "Execution succeeded"
    except Exception as e:
        return f"Error: {str(e)}"
