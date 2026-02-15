from app.services.arcee_service import ask_ai
import os

# Ensure API key is loaded
from dotenv import load_dotenv
load_dotenv()

print("Testing ask_ai with 'hello'...")
try:
    response = ask_ai("hello")
    print("Response:", response)
except Exception as e:
    print("Error:", e)

print("\nTesting ask_ai with 'What is Python?'...")
try:
    response = ask_ai("What is Python?")
    print("Response:", response)
except Exception as e:
    print("Error:", e)
