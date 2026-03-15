# REVER – Shopify AI Chatbot

An AI-powered chatbot embedded in a Shopify storefront as a floating widget. It handles two flows:

- **Pre-purchase**: shopping assistant that answers product questions, checks availability, and suggests alternatives using GROQ (Llama 3.3 70B) + Shopify Storefront API.
- **Post-purchase / Returns**: guides customers through return alternatives (exchange → gift card with bonus → refund) before offering a refund, minimising returns.

**Stack:** Flutter Web · Firebase (Auth + Firestore + Hosting) · GROQ / Llama 3.3 70B · Shopify Theme App Extension

---

## Project structure

```
rever/
├── flutter_app/          # Flutter Web chat UI (deployed to Firebase Hosting)
├── rever-chatbot/        # Shopify app (Node.js + Theme App Extension)
│   └── extensions/
│       └── rever-chabot/ # App Embed Block – floating iframe widget
├── firebase.json         # Firebase Hosting config
├── firestore.rules       # Firestore security rules
├── deploy.ps1            # Windows build + deploy script
├── deploy.sh             # macOS / Linux build + deploy script
└── .env.example          # Environment variable template
```

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter | ≥ 3.41 | https://docs.flutter.dev/get-started/install |
| Node.js | ≥ 20.19 | https://nodejs.org |
| Firebase CLI | ≥ 15 | `npm install -g firebase-tools` |
| Shopify CLI | ≥ 3.92 | `npm install -g @shopify/cli` |

---

## Setup

### 1. Clone and configure environment

```bash
git clone <repo-url>
cd rever
cp .env.example .env
```

Edit `.env` and fill in all values (see comments in the file for where to find each key).

```bash
cp rever-chatbot/.env.example rever-chatbot/.env
```

Edit `rever-chatbot/.env` with the Shopify app credentials.

### 2. Firebase

Log in and select the project:

```bash
firebase login
firebase use rever-c494a
```

Deploy Firestore rules:

```bash
firebase deploy --only firestore:rules
```

### 3. Flutter dependencies

```bash
cd flutter_app
flutter pub get
cd ..
```

### 4. Build and deploy Flutter Web

**Windows:**
```powershell
.\deploy.ps1
```

**macOS / Linux:**
```bash
chmod +x deploy.sh
./deploy.sh
```

This reads keys from `.env`, builds Flutter Web, and deploys to Firebase Hosting at `https://rever-c494a.web.app`.

### 5. Shopify extension

```bash
cd rever-chatbot
npm install
shopify app deploy
```

This deploys the Theme App Extension to Shopify Partners.

### 6. Install the app on the dev store

Go to [Shopify Partners](https://partners.shopify.com) → Apps → **Rever Chatbot** → **Test your app** → select the dev store → install.

### 7. Activate the widget in the theme

1. Go to Shopify Admin → Online Store → Themes → **Customize**
2. In the left panel, click **App embeds**
3. Toggle **REVER Chat** on → **Save**

The floating chat bubble will now appear on all storefront pages.

---

## Development

To run the Flutter app locally:

```bash
cd flutter_app
flutter run -d chrome \
  --dart-define=GROQ_API_KEY=your_groq_key \
  --dart-define=SHOPIFY_STORE_DOMAIN=yourstore.myshopify.com \
  --dart-define=SHOPIFY_STOREFRONT_TOKEN=your_token
```

To run the Shopify app locally (requires the app to be installed first):

```bash
cd rever-chatbot
shopify app dev
```

---

## How it works

```
Shopify storefront
  └── App Embed Block (rever-chat.liquid)
        └── iframe → https://rever-c494a.web.app
              └── Flutter Web app
                    ├── GeminiService  → GROQ / Llama 3.3 70B (AI responses)
                    ├── ShopifyService → Storefront GraphQL API (product data)
                    └── FirebaseService → Firestore (session + return request logs)
```

All API keys are injected at Flutter build time via `--dart-define` and are never stored in source code.
