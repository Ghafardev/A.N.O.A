# Rangkuman Tahap 4: Backend & Agentic Workflow Integration

Pada Tahap 4, fokus utama adalah membangun logika inti backend dan menghubungkan
seluruh komponen frontend ke **Gemini AI** secara nyata melalui FastAPI.

---

## 1. Upgrade Backend (FastAPI + Gemini)
**File:** `backend/main.py` — Full rewrite

### Perubahan Utama:
- **CORS Middleware** ditambahkan agar Flutter Web & Desktop bisa mengakses backend tanpa error.
- **5 Mode Agentic** diimplementasikan masing-masing dengan *system prompt* yang unik dan spesifik:

  | Mode ID | Nama | Fungsi |
  |---|---|---|
  | `red_team` | Red Team AI | Analisis kerentanan, vektor serangan, MITRE ATT&CK |
  | `blue_team` | Blue Team AI | Deteksi ancaman, SIEM rules, mitigasi, preventive controls |
  | `phishing` | Phishing Detector | Analisis email/URL, indikator phishing, verdict & action |
  | `log_audit` | Log Audit AI | Parsing log, IOC detection, timeline rekonstruksi |
  | `credential_detector` | Credential Detector | Deteksi API key, password, PII, private key bocor |

- **Endpoint `/analyze`** — Menerima `data`, `mode`, dan optional `context` (RAG).
- **Endpoint `/generate-yaml`** — Menerima prompt natural language, menghasilkan YAML rules Lobster Trap via Gemini.
- **Endpoint `GET /`** — Health check yang menampilkan status API key dan mode yang tersedia.
- **Model Gemini** yang digunakan: `gemini-2.0-flash` (cepat & efisien untuk analisis keamanan).

### Alur Komunikasi (Agentic Workflow):
```
Flutter UI  →  POST /analyze  →  FastAPI  →  [System Prompt + User Query]  →  Gemini AI
                                                                              ↓
Flutter UI  ←  JSON {result}  ←  FastAPI  ←────────────────────────── Respons Gemini
```

---

## 2. Upgrade Frontend Services
**File:** `frontend/lib/services/api_service.dart`

- Metode `analyze()` diperbarui untuk mem-parse field `result` dari respons JSON baru.
- Metode `generateYaml()` ditambahkan — memanggil endpoint `/generate-yaml`.
- Support parameter `context` (RAG knowledge base) di metode `analyze()`.
- Timeout 30 detik untuk query Gemini yang kompleks.

---

## 3. Upgrade Widget Chat Assistant
**File:** `frontend/lib/ui/widgets/chat_assistant.dart`

- Semua **5 mode** kini tersedia sebagai chip yang bisa dipilih (scrollable horizontal).
- **Header** menampilkan mode aktif saat ini + warna indikator mode.
- **Hint text** input berubah sesuai mode yang dipilih (kontekstual).
- **Typing indicator** menggunakan warna sesuai mode aktif.
- Pesan AI kini menggunakan `SelectableText` agar respons panjang bisa di-copy.
- Pesan dikirim ke **Gemini API** secara nyata melalui backend (bukan placeholder).

---

## 4. Upgrade Widget YAML Generator
**File:** `frontend/lib/ui/widgets/yaml_generator.dart`

- Tombol "Generate YAML Rule" kini memanggil **Gemini API secara nyata** via `ApiService.generateYaml()`.
- Output ditampilkan dengan `SelectableText` agar bisa di-copy dengan mudah.
- Tombol **Copy to Clipboard** hanya muncul jika output valid (bukan pesan error).
- Loading state ditampilkan dengan animasi indicator selama Gemini memproses.

---

## 5. Update Dependencies Backend
**File:** `backend/requirements.txt`

Ditambahkan:
- `uvicorn[standard]` — performa lebih baik dengan WebSocket support
- `httpx` — HTTP client async untuk integrasi masa depan

---

## Cara Menjalankan (Lengkap)

### Terminal 1 – Backend:
```bash
cd "ANOA_System/backend"
pip install -r requirements.txt
uvicorn main:app --reload
# Backend aktif di: http://127.0.0.1:8000
```

### Terminal 2 – Frontend:
```bash
cd "ANOA_System/frontend"
flutter run -d windows
# atau: flutter run -d chrome
```

### Verifikasi Backend:
Buka browser → `http://127.0.0.1:8000`
Response yang diharapkan:
```json
{
  "status": "ANOA System Backend is running!",
  "version": "2.0.0",
  "gemini_configured": true,
  "model": "gemini-2.0-flash",
  "available_modes": ["red_team", "blue_team", "phishing", "log_audit", "credential_detector"]
}
```

---

## Status Tahap 4 ✅

- [x] Backend main.py — Full Gemini integration dengan 5 mode
- [x] CORS Middleware — Flutter dapat mengakses backend tanpa error
- [x] Endpoint `/analyze` — Purple Team AI dengan system prompt per mode
- [x] Endpoint `/generate-yaml` — YAML Rules Generator via Gemini
- [x] api_service.dart — generateYaml() + fix response parsing
- [x] chat_assistant.dart — 5 mode agentic dengan UI kontekstual
- [x] yaml_generator.dart — Terhubung ke Gemini API secara nyata
- [x] requirements.txt — Dependencies backend diperbarui

---

> **Selanjutnya (Tahap 5):**
> Testing end-to-end, integrasi Veea Lobster Trap sebagai proxy,
> demo skenario hackathon (Phishing Detection, Log Audit, Real Defense Automation),
> dan polish UI sebelum presentasi final.
