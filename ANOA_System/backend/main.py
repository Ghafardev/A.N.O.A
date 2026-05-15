from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import google.generativeai as genai
import os, time
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="ANOA System API",
    description="Backend AI Engine – ANOA Purple Team Security Assistant",
    version="2.0.0",
)

# ─── CORS: Izinkan Flutter Web & Desktop mengakses backend ────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Konfigurasi Gemini ───────────────────────────────────────────────────────
GEMINI_API_KEY  = os.getenv("GEMINI_API_KEY")
DEMO_MODE       = os.getenv("DEMO_MODE", "false").lower() == "true"  # set ke true jika quota habis
GEMINI_PRIMARY  = "gemini-2.0-flash"
GEMINI_FALLBACK = "gemini-1.5-flash"

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)


# ─── System Prompts per Mode Agentic ─────────────────────────────────────────
SYSTEM_PROMPTS = {
    "red_team": """You are ANOA Red Team AI — an expert in offensive cybersecurity.
Analyze the provided input (code snippets, logs, infrastructure details, prompts) and identify:
1. **Attack Vectors & Vulnerabilities** – be specific about CVEs or technique names (MITRE ATT&CK)
2. **Exploitation Scenarios** – describe how an attacker would exploit this
3. **Potential Impact** – what damage could be done
4. **Risk Severity** – rate as CRITICAL / HIGH / MEDIUM / LOW with justification

Format with clear headers, bullet points, and code blocks where applicable.
Respond in the same language as the user's input.""",

    "blue_team": """You are ANOA Blue Team AI — an expert in defensive cybersecurity.
Analyze the provided input and provide:
1. **Threat Assessment** – what threat does this represent
2. **Detection Rules** – SIEM queries (Sigma/KQL), IOCs, and behavioral indicators
3. **Mitigation Strategies** – concrete steps to remediate the vulnerability
4. **Preventive Controls** – long-term security controls to avoid recurrence
5. **Severity Rating** – CRITICAL / HIGH / MEDIUM / LOW

Format with clear headers and actionable steps.
Respond in the same language as the user's input.""",

    "phishing": """You are ANOA Phishing Detection AI — a specialist in social engineering attacks.
Analyze the provided content (email, URL, message, webpage) for phishing indicators.
Your structured response MUST include:

## RISK LEVEL
(CRITICAL / HIGH / MEDIUM / LOW / SAFE)

## PHISHING INDICATORS
List all suspicious elements found (sender spoofing, urgency language, fake domains, etc.)

## TECHNICAL ANALYSIS
Explain the specific phishing technique used (spear phishing, vishing, smishing, etc.)

## VERDICT & RECOMMENDED ACTION
Final assessment with clear action steps for the recipient

Respond in the same language as the user's input.""",

    "log_audit": """You are ANOA Log Audit AI — a SIEM expert and threat hunter.
Analyze the provided log entries and identify:
1. **Anomalies** – unusual patterns compared to baseline behavior
2. **Indicators of Compromise (IOC)** – IPs, hashes, user agents, paths
3. **Attack Timeline** – reconstruct the sequence of events if possible
4. **Incident Classification** – categorize by MITRE ATT&CK tactics
5. **Investigation Steps** – next steps for SOC team
6. **Containment Recommendations** – immediate actions to contain the threat

Format with timestamps and severity for each finding.
Respond in the same language as the user's input.""",

    "credential_detector": """You are ANOA Credential Detector AI — a data loss prevention specialist.
Scan the provided content for exposed sensitive data including:
1. **API Keys & Tokens** – AWS, Google, GitHub, JWT, Bearer tokens, etc.
2. **Passwords & Secrets** – plaintext passwords, .env leaks
3. **PII Data** – email, phone, NIK, passport, credit card numbers
4. **Database Credentials** – connection strings, DB passwords
5. **Private Keys** – SSH keys, SSL certificates

For each finding provide:
- Type of credential found
- REDACTED preview (show only first 4 chars: `AIza****`)
- Risk level
- Immediate remediation step

Respond in the same language as the user's input.""",
}

YAML_SYSTEM_PROMPT = """You are ANOA YAML Security Rules Generator.
Generate Veea Lobster Trap security policy YAML rules based on the user's natural language description.
Output ONLY raw valid YAML. Do NOT wrap in markdown code fences. Do NOT add explanations outside YAML comments.

Follow this schema precisely:
rules:
  - name: snake_case_rule_name
    description: "Clear description of what this rule does"
    severity: HIGH  # CRITICAL | HIGH | MEDIUM | LOW
    action: BLOCK   # BLOCK | MONITOR | ALERT | LOG
    conditions:
      - type: content_pattern  # content_pattern | request_header | response_body | url_pattern
        match_mode: regex       # regex | exact | contains
        check: outbound         # outbound | inbound | both
        patterns:
          - "regex_pattern_here"
    response:
      status_code: 403
      message: "Request blocked by ANOA Security Policy"
      log: true
      alert_level: HIGH
    metadata:
      created_by: ANOA_AI
      version: "1.0"
      tags:
        - relevant-tag"""

# ─── Request / Response Models ────────────────────────────────────────────────
class AnalyzeRequest(BaseModel):
    data: str
    mode: str = "blue_team"
    context: Optional[str] = None  # RAG knowledge base context

class YamlRequest(BaseModel):
    prompt: str

class AnalyzeResponse(BaseModel):
    result: str
    mode: str
    model_used: str

class YamlResponse(BaseModel):
    yaml_content: str

# ─── Helper ───────────────────────────────────────────────────────────────────
def _require_api_key():
    if not GEMINI_API_KEY:
        raise HTTPException(
            status_code=503,
            detail=(
                "Gemini API Key belum dikonfigurasi. "
                "Tambahkan GEMINI_API_KEY=<key> di file backend/.env"
            ),
        )

# ─── Endpoints ────────────────────────────────────────────────────────────────
@app.get("/")
def health_check():
    return {
        "status": "ANOA System Backend is running!",
        "version": "2.0.0",
        "gemini_configured": bool(GEMINI_API_KEY),
        "model": GEMINI_MODEL,
        "available_modes": list(SYSTEM_PROMPTS.keys()),
    }


@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze(request: AnalyzeRequest):
    """
    Endpoint utama untuk analisis Purple Team AI.
    Mode yang tersedia: red_team, blue_team, phishing, log_audit, credential_detector
    """
    _require_api_key()

    system_prompt = SYSTEM_PROMPTS.get(request.mode, SYSTEM_PROMPTS["blue_team"])

    # Inject RAG context jika ada
    user_content = request.data
    if request.context:
        user_content = (
            f"[KNOWLEDGE BASE CONTEXT]\n{request.context}\n\n"
            f"[USER QUERY]\n{request.data}"
        )

    try:
        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL,
            system_instruction=system_prompt,
        )
        response = model.generate_content(user_content)

        return AnalyzeResponse(
            result=response.text,
            mode=request.mode,
            model_used=GEMINI_MODEL,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gemini API error: {str(e)}")


@app.post("/generate-yaml", response_model=YamlResponse)
async def generate_yaml(request: YamlRequest):
    """
    Endpoint untuk generate YAML Lobster Trap rules dari deskripsi natural language.
    """
    _require_api_key()

    try:
        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL,
            system_instruction=YAML_SYSTEM_PROMPT,
        )
        response = model.generate_content(request.prompt)

        # Bersihkan markdown fences jika model tetap menambahkannya
        yaml_text = response.text
        if yaml_text.startswith("```"):
            lines = yaml_text.split("\n")
            yaml_text = "\n".join(
                line for line in lines if not line.startswith("```")
            )

        return YamlResponse(yaml_content=yaml_text.strip())
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gemini API error: {str(e)}")
