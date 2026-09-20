<div align="center">
  <h1>🏛️ Certus (formerly Sahi Hai?)</h1>
  <p><strong>AI Government Service Assistant — iQOO Hackathon 2026</strong></p>
  <p>An offline-first Flutter application empowering consumers and shopkeepers to instantly verify FMCG products, GST invoices, and complex government forms using on-device AI.</p>
</div>

---

## ✨ Features

- **📦 Product Authentication (Module 1)**: Verifies EAN-13 barcodes, GS1 India prefixes (890), BIS Hallmarking (HUID), and FSSAI structures directly from the packaging.
- **🧾 GST Invoice Verification (Module 2)**: Detects arithmetic fraud, GSTIN checksums, and MRP limits on invoices using OCR and a custom Rule Engine.
- **📝 Govt Form Explainer (Module 3)**: Scans complex forms (like Form 6 or PAN 49A), explains ambiguous fields in Hindi/English, and lists required documents.
- **🎙️ Voice Q&A Assistant**: Tap the microphone to ask questions about your scans (e.g., *"What is wrong with this bill?"*). Uses fast on-device TTS.
- **📄 Evidence Generation**: Generates compliant A4 PDFs of flagged documents, automatically masking PII (Aadhaar, PAN, Phone) to protect privacy.

## 📱 Screenshots & Architecture
*The application utilizes a Hybrid LLM Architecture.*
- **Offline-First**: Uses **Gemma 4 E2B** via LiteRT-LM for completely offline extraction and privacy.
- **Online-Fallback**: Seamlessly falls back to the Gemini 1.5 Flash API if the local model is unavailable but the internet is active.

## 🚀 How to Run

1. **Prerequisites**: Ensure you have [Flutter](https://flutter.dev/) installed.
2. **Clone the Repo**:
   `ash
   git clone https://github.com/Dibyansu33Gouda/Ai-governence---consumer-fiels-ai.git
   cd Ai-governence---consumer-fiels-ai
   `
3. **Install Dependencies**:
   `ash
   flutter pub get
   `
4. **Environment Setup**:
   Add your Gemini API key to the .env file for the online fallback to work:
   `nv
   GEMINI_API_KEY=your_gemini_api_key_here
   `
5. **Run the App**:
   `ash
   flutter run --release
   `

## 🧠 Local Model Setup (Offline Mode)
For the hackathon's strict offline mode, the Gemma model must be placed on the device:
1. Generate/Download the model via 	ools/download_model.ps1.
2. Push the .litertlm file to your Android phone via Office Kit or USB:
   Internal Storage/Android/data/com.example.certus/files/models/

---
<div align="center">
  <i>Built for the iQOO Hackathon Open Innovation Track</i>
</div>
