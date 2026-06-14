from fastapi import FastAPI, HTTPException, Security, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security.api_key import APIKeyHeader
from pydantic import BaseModel, Field
from typing import Optional, List
import google.generativeai as genai
import os, time, json, re, yaml, warnings
from datetime import datetime
from dotenv import load_dotenv
import uvicorn

# Suppress Deprecation Warnings for clean terminal
warnings.filterwarnings("ignore", category=FutureWarning)

load_dotenv()

app = FastAPI(
    title="ANOA System API",
    description="Backend AI Engine – ANOA Purple Team Security Assistant",
    version="2.1.0",
)

# ─── Security: API Key ──────────────────────────────────────────────────────
# The API key must be provided via environment variable for security.
API_KEY = os.getenv("ANOA_INTERNAL_KEY")
if not API_KEY:
    raise RuntimeError("ANOA_INTERNAL_KEY environment variable is required. Set it before starting the server.")
api_key_header = APIKeyHeader(name="X-API-KEY", auto_error=False)

async def get_api_key(api_key_header: str = Security(api_key_header)):
    if api_key_header == API_KEY:
        return api_key_header
    raise HTTPException(
        status_code=403, 
        detail="Could not validate credentials. X-API-KEY header missing or invalid."
    )

# ─── Threat Logs Storage (In-Memory & File) ──────────────────────────────────
THREAT_LOGS_FILE = "threat_logs.json"
KNOWLEDGE_BASE_FILE = "knowledge_base.json"
CUSTOM_RULES_FILE = "custom_rules.json"
threat_logs: List[dict] = []
knowledge_base: List[dict] = []
custom_rules: List[dict] = []

# Base DPI Patterns
BASE_PATTERNS = [
    r".*(?:ignore|disregard|forget).*(?:instructions|prompts|directions)",
    r".*act\s+as.*(?:dan|jailbroken|unfiltered|expert|hacker|anarchy)",
    r".*system.*prompt.*",
    r"\[system\]|decode.*base64|payload.*injection"
]
LOBSTER_TRAP_PATTERNS = re.compile("|".join(BASE_PATTERNS), re.IGNORECASE | re.DOTALL)

def _recompile_rules():
    """Menggabungkan base patterns dengan custom rules dari YAML."""
    global LOBSTER_TRAP_PATTERNS
    patterns = list(BASE_PATTERNS)
    for rule in custom_rules:
        for pattern in rule.get("patterns", []):
            patterns.append(pattern)
    LOBSTER_TRAP_PATTERNS = re.compile("|".join(patterns), re.IGNORECASE | re.DOTALL)

def _load_data():
    """Muat logs, knowledge base, dan custom rules dari file jika ada."""
    global threat_logs, knowledge_base, custom_rules
    if os.path.exists(THREAT_LOGS_FILE):
        try:
            with open(THREAT_LOGS_FILE, "r") as f:
                threat_logs = json.load(f)
        except Exception: threat_logs = []
    
    if os.path.exists(KNOWLEDGE_BASE_FILE):
        try:
            with open(KNOWLEDGE_BASE_FILE, "r") as f:
                knowledge_base = json.load(f)
        except Exception: knowledge_base = []

    if os.path.exists(CUSTOM_RULES_FILE):
        try:
            with open(CUSTOM_RULES_FILE, "r") as f:
                custom_rules = json.load(f)
            _recompile_rules()
        except Exception: custom_rules = []

def _save_threat_logs():
    """Simpan logs ke file."""
    try:
        with open(THREAT_LOGS_FILE, "w") as f:
            json.dump(threat_logs, f, indent=2)
    except Exception as e:
        print(f"Error saving logs: {e}")

def _save_knowledge_base():
    """Simpan knowledge base ke file."""
    try:
        with open(KNOWLEDGE_BASE_FILE, "w") as f:
            json.dump(knowledge_base, f, indent=2)
    except Exception as e:
        print(f"Error saving knowledge: {e}")

def _log_threat_event(event_type: str, mode: str, status: str, source_ip: str = "127.0.0.1", detail: str = "Clean"):
    """Catat event ancaman ke logs."""
    global threat_logs
    log_entry = {
        "time": datetime.now().strftime("%H:%M:%S"),
        "timestamp": datetime.now().isoformat(),
        "type": event_type,
        "mode": mode,
        "source": source_ip,
        "status": status,
        "detail": detail
    }
    threat_logs.insert(0, log_entry)  # Tambah di awal untuk newest first
    if len(threat_logs) > 100:  # Simpan max 100 entries
        threat_logs.pop()
    _save_threat_logs()

# Load existing data on startup
_load_data()

# ─── Helper: RAG Search ──────────────────────────────────────────────────────
def _search_knowledge(query: str) -> str:
    """Mencari potongan teks relevan dari knowledge base (Simple Keyword Match)."""
    relevant_snippets = []
    query_words = set(re.findall(r'\w+', query.lower()))
    
    for entry in knowledge_base:
        content = entry.get("content", "").lower()
        # Jika ada kata kunci yang cocok, masukkan ke snippet
        if any(word in content for word in query_words if len(word) > 3):
            relevant_snippets.append(f"--- Source: {entry.get('name')} ---\n{entry.get('content')}")
    
    if not relevant_snippets:
        return ""
    
    return "\n\n".join(relevant_snippets[:3]) # Ambil top 3 relevan

def _save_custom_rules():
    """Simpan custom rules ke file."""
    try:
        with open(CUSTOM_RULES_FILE, "w") as f:
            json.dump(custom_rules, f, indent=2)
    except Exception as e:
        print(f"Error saving custom rules: {e}")

# ─── CORS: Restrictive configuration ──────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://127.0.0.1"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Konfigurasi Gemini ───────────────────────────────────────────────────────
GEMINI_API_KEY  = os.getenv("GEMINI_API_KEY")
DEMO_MODE       = os.getenv("DEMO_MODE", "false").lower() == "true"
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
    data: str = Field(..., max_length=5000)
    mode: str = "blue_team"
    context: Optional[str] = None

class YamlRequest(BaseModel):
    prompt: str = Field(..., max_length=1000)

class KnowledgeRequest(BaseModel):
    name: str
    content: str

class AnalyzeResponse(BaseModel):
    result: str
    mode: str
    model_used: str

class YamlResponse(BaseModel):
    yaml_content: str

# ─── Demo Responses ──────────────────────────────────────────────────────────
DEMO_RESPONSES = {
    "red_team": "## 🔴 ANOA Red Team Analysis [DEMO MODE]\n\n### Attack Vectors Identified\n- **CVE-2024-1234** – SQL Injection via unsanitized user input pada endpoint `/api/login`...",
    "blue_team": "## 🔵 ANOA Blue Team Analysis [DEMO MODE]\n\n### Threat Assessment\nTerdeteksi pola **Lateral Movement**...",
    "phishing": "## 🎣 ANOA Phishing Detection [DEMO MODE]\n\n## RISK LEVEL\n🔴 **CRITICAL**...",
    "log_audit": "## 📋 ANOA Log Audit [DEMO MODE]\n\n### Anomalies Detected\n| Time | Event | Severity |...",
    "credential_detector": "## 🔐 ANOA Credential Detector [DEMO MODE]\n\n### Findings Summary\n**3 credential leaks detected**...",
}

DEMO_YAML = """# ANOA System – Demo YAML Rule [DEMO MODE]
rules:
  - name: anoa_demo_prompt_injection_block
    description: "Blokir semua pola prompt injection yang umum digunakan"
    severity: HIGH
    action: BLOCK
    conditions:
      - type: content_pattern
        match_mode: regex
        check: outbound
        patterns:
          - "(?i)(ignore|forget|disregard).{0,20}(previous|above|system).{0,20}(prompt|instruction)"
"""

# ─── Helper: Panggil Gemini with Fallback ─────────────────────────────────────
def _call_gemini(system_prompt: str, user_content: str) -> tuple[str, str]:
    for model_name in [GEMINI_PRIMARY, GEMINI_FALLBACK]:
        try:
            model = genai.GenerativeModel(model_name=model_name, system_instruction=system_prompt)
            response = model.generate_content(user_content)
            return response.text, model_name
        except Exception as e:
            if "429" in str(e) or "quota" in str(e).lower():
                if model_name == GEMINI_FALLBACK: raise
                continue
            raise
    raise RuntimeError("Semua model Gemini tidak tersedia")

# ─── Endpoints ────────────────────────────────────────────────────────────────
@app.get("/")
def health_check():
    return {
        "status": "ANOA System Backend is Operational",
        "version": "2.2.0",
        "gemini_configured": bool(GEMINI_API_KEY),
        "demo_mode": DEMO_MODE,
        "available_modes": list(SYSTEM_PROMPTS.keys()),
        "knowledge_entries": len(knowledge_base),
    }

@app.post("/analyze", response_model=AnalyzeResponse, dependencies=[Depends(get_api_key)])
async def analyze(request: AnalyzeRequest):
    # ── Lobster Trap DPI (Regex) with normalization to catch obfuscation like "I G N O R E"
    raw_text = request.data or ""
    # Normalize by removing all non-alphanumeric characters to detect spaced/obfuscated words
    normalized_text = re.sub(r'[^A-Za-z0-9]', '', raw_text).lower()

    regex_match = LOBSTER_TRAP_PATTERNS.search(raw_text) or LOBSTER_TRAP_PATTERNS.search(normalized_text)

    # Additional heuristic: detect primary trigger words combined with secondary qualifiers
    matched_pattern = None
    if regex_match:
        matched_pattern = regex_match.group(0)
    else:
        primary_keywords = ["ignore", "disregard", "forget"]
        secondary_keywords = ["previous", "instructions", "prompts", "directions"]
        found_primary = next((pk for pk in primary_keywords if pk in normalized_text), None)
        found_secondary = next((sk for sk in secondary_keywords if sk in normalized_text), None)
        if found_primary and found_secondary:
            matched_pattern = f"heuristic:{found_primary}_{found_secondary}"

    if matched_pattern:
        pattern = matched_pattern
        _log_threat_event("Prompt Injection", request.mode, "BLOCKED", detail=f"Matched pattern: {pattern}")
        return AnalyzeResponse(
            result=(
                "🛡️ **[ANOA LOBSTER TRAP – DPI BLOCKED]**\n\n"
                f"Request diblokir: terdeteksi pola **Prompt Injection** (`{pattern}`).\n"
                "HTTP 403 Forbidden – Request tidak diteruskan ke Gemini API.\n\n"
                "*Log insiden telah dicatat.*"
            ),
            mode=request.mode,
            model_used="LOBSTER_TRAP_DPI",
        )

    # ── RAG Logic: Search Knowledge Base ────────────────────────────────────
    rag_context = _search_knowledge(request.data)
    full_context = f"{request.context or ''}\n\n[AUGMENTED KNOWLEDGE]\n{rag_context}".strip()

    if DEMO_MODE or not GEMINI_API_KEY:
        demo_text = DEMO_RESPONSES.get(request.mode, DEMO_RESPONSES["blue_team"])
        if rag_context:
            demo_text = f"💡 *Note: Found relevant info in Knowledge Base.*\n\n{demo_text}"
        _log_threat_event("Demo Analysis", request.mode, "ALLOWED")
        return AnalyzeResponse(result=demo_text, mode=request.mode, model_used="DEMO_MODE")

    try:
        user_content = f"[CONTEXT]\n{full_context}\n\n[QUERY]\n{request.data}" if full_context else request.data
        result_text, model_used = _call_gemini(SYSTEM_PROMPTS.get(request.mode, ""), user_content)
        _log_threat_event("Normal Analysis", request.mode, "ALLOWED")
        return AnalyzeResponse(result=result_text, mode=request.mode, model_used=model_used)
    except Exception as e:
        if "429" in str(e) or "quota" in str(e).lower():
            return AnalyzeResponse(result="⚠️ Quota Gemini habis. [DEMO]\n\n" + DEMO_RESPONSES[request.mode], mode=request.mode, model_used="DEMO_FALLBACK")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/logs", dependencies=[Depends(get_api_key)])
def get_threat_logs():
    return {"logs": threat_logs}

@app.get("/stats", dependencies=[Depends(get_api_key)])
def get_stats():
    """Mengagregasi statistik untuk dashboard."""
    total = len(threat_logs)
    blocked = len([l for l in threat_logs if l["status"] == "BLOCKED"])
    allowed = total - blocked
    
    # Kategori Ancaman (Pie Chart)
    categories = {}
    for l in threat_logs:
        t = l["type"]
        categories[t] = categories.get(t, 0) + 1
    
    pie_data = [{"label": k, "value": v} for k, v in categories.items()]
    
    # Timeline (Line Chart - Mock/Simplified from logs)
    # Di dunia nyata, ini akan mengagregasi per jam
    timeline_data = []
    # Ambil 24 jam terakhir (simulasi)
    for i in range(24):
        timeline_data.append({"hour": i, "count": 10 + (i % 5) * 10}) # Placeholder trend

    return {
        "summary": {
            "total_threats": total + 1247, # Add to base demo data
            "blocked": blocked + 389,
            "allowed": allowed + 4821,
            "rules": 24 + len(knowledge_base)
        },
        "pie_chart": pie_data or [{"label": "Prompt Injection", "value": 35}, {"label": "Phishing", "value": 28}],
        "line_chart": timeline_data
    }

@app.post("/knowledge/upload", dependencies=[Depends(get_api_key)])
async def upload_knowledge(request: KnowledgeRequest):
    global knowledge_base
    knowledge_base.append({
        "name": request.name,
        "content": request.content,
        "timestamp": datetime.now().isoformat()
    })
    _save_knowledge_base()
    return {"status": "success", "message": f"Knowledge '{request.name}' integrated."}

@app.post("/generate-yaml", response_model=YamlResponse, dependencies=[Depends(get_api_key)])
async def generate_yaml(request: YamlRequest):
    if DEMO_MODE or not GEMINI_API_KEY:
        return YamlResponse(yaml_content=DEMO_YAML)
    try:
        result_text, _ = _call_gemini(YAML_SYSTEM_PROMPT, request.prompt)
        return YamlResponse(yaml_content=result_text.replace("```yaml", "").replace("```", "").strip())
    except Exception as e:
        if "429" in str(e) or "quota" in str(e).lower():
            return YamlResponse(yaml_content="# Quota Gemini habis\n" + DEMO_YAML)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/apply-rule", dependencies=[Depends(get_api_key)])
async def apply_rule(request: YamlResponse):
    """Menerima YAML, mengekstrak pola regex, dan menerapkannya ke DPI secara dinamis."""
    global custom_rules
    try:
        # Parse YAML
        data = yaml.safe_load(request.yaml_content)
        if not data or 'rules' not in data:
            raise HTTPException(status_code=400, detail="Invalid YAML format. 'rules' key missing.")
        
        new_rules_count = 0
        for rule_data in data['rules']:
            name = rule_data.get('name', 'unnamed_rule')
            patterns = []
            for condition in rule_data.get('conditions', []):
                if condition.get('type') == 'content_pattern':
                    patterns.extend(condition.get('patterns', []))
            
            if patterns:
                custom_rules.append({
                    "name": name,
                    "patterns": patterns,
                    "applied_at": datetime.now().isoformat()
                })
                new_rules_count += 1
        
        if new_rules_count > 0:
            _save_custom_rules()
            _recompile_rules()
            return {"status": "success", "message": f"Applied {new_rules_count} new security rules dynamically."}
        else:
            return {"status": "warning", "message": "No valid content patterns found in YAML."}
            
    except yaml.YAMLError as e:
        raise HTTPException(status_code=400, detail=f"YAML Parsing Error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Server Error: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
