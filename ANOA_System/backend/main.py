from fastapi import FastAPI
from pydantic import BaseModel
import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="ANOA System API", 
    description="Backend for ANOA System Purple Team Assistant"
)

# Konfigurasi Gemini API Key (menggunakan Free Tier)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

class Payload(BaseModel):
    data: str
    mode: str = "red_team" # red_team, blue_team, dll

@app.get("/")
def read_root():
    return {"status": "ANOA System Backend is running!"}

@app.post("/analyze")
def analyze_payload(payload: Payload):
    # Endpoint ini nantinya akan berinteraksi dengan Gemini 
    # melalui proxy Veea Lobster Trap.
    return {
        "message": "Endpoint is ready",
        "received_data": payload.data,
        "mode": payload.mode
    }
