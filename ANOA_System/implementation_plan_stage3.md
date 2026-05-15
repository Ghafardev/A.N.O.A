# Tahap 3: UI Frontend Development (Flutter)

## Tujuan
Membangun keseluruhan antarmuka pengguna (UI) ANOA System dari nol.
Saat ini `lib/` hanya berisi `main.dart` template bawaan Flutter.

## Struktur File yang Akan Dibuat

```
frontend/lib/
├── main.dart                         [OVERWRITE] - Dark theme + routing
├── services/
│   └── api_service.dart              [NEW] - HTTP client ke FastAPI backend
└── ui/
    ├── dashboard.dart                [NEW] - Layout utama (Sidebar + Content)
    └── widgets/
        ├── chart_widgets.dart        [NEW] - Line chart & Pie chart keamanan
        ├── chat_assistant.dart       [NEW] - AI Chat (Side Panel & Floating)
        ├── rag_builder.dart          [NEW] - GUI Knowledge Base / RAG Builder
        └── yaml_generator.dart       [NEW] - Custom YAML Rules Generator
```

## Dependensi Baru (pubspec.yaml)
- `fl_chart: ^0.68.0` — Visualisasi grafik
- `google_fonts: ^6.2.0` — Tipografi Inter
- `http: ^1.2.1` — HTTP call ke backend FastAPI
- `provider: ^6.1.2` — State management

## Desain & Palet Warna
- Background : #0A0E1A (navy sangat gelap)
- Surface    : #101626
- Card       : #1A2035
- Border     : #283050
- Primary    : #6C63FF (ungu)
- Secondary  : #00E5FF (cyan)
- Success    : #34D399 (hijau)
- Danger     : #F87171 (merah)
- Warning    : #FBBF24 (kuning)
- Font       : Inter (Google Fonts)

## Layout Dashboard
```
+--[ SIDEBAR 240px ]--+--[ TOPBAR ]---------------------+
| Logo ANOA           | Judul halaman | Status | [Chat]  |
| [nav] Overview      +-----------------------------------------+
| [nav] RAG Builder   |                                         |
| [nav] YAML Gen      |   KONTEN UTAMA (Overview/RAG/YAML)      |
|                     |                          [CHAT PANEL]   |
+---------------------+-----------------------------------------+
                                                       [FAB 💬]
```

## Status Pengerjaan
- [x] Update pubspec.yaml
- [x] Tulis lib/main.dart
- [x] Tulis lib/services/api_service.dart
- [x] Tulis lib/ui/dashboard.dart
- [x] Tulis lib/ui/widgets/chart_widgets.dart
- [x] Tulis lib/ui/widgets/chat_assistant.dart
- [x] Tulis lib/ui/widgets/rag_builder.dart
- [x] Tulis lib/ui/widgets/yaml_generator.dart
- [x] flutter pub get & verifikasi → BUILD SUKSES ✅
