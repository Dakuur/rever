#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  REVER – Build Flutter Web & Deploy to Firebase Hosting
#  Usage: ./deploy.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# -- Load .env ----------------------------------------------------------------
if [ -f .env ]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

# -- Validate required keys ---------------------------------------------------
: "${GROQ_API_KEY:?Missing GROQ_API_KEY in .env}"
: "${SHOPIFY_STORE_DOMAIN:?Missing SHOPIFY_STORE_DOMAIN in .env (e.g. yourstore.myshopify.com)}"
: "${SHOPIFY_STOREFRONT_PUBLIC_TOKEN:?Missing SHOPIFY_STOREFRONT_PUBLIC_TOKEN in .env}"

echo "[OK] Keys validated"

# -- Run tests ----------------------------------------------------------------
echo "[TEST] Running Flutter unit tests (models, services, config)..."
cd flutter_app
flutter test test/models/ test/services/ test/config/ test/widget_test.dart --reporter=compact
if [ $? -ne 0 ]; then
  echo "[FAIL] Flutter tests failed — deploy aborted."
  exit 1
fi
cd ..
echo "[OK] Flutter tests passed"

echo "[TEST] Running Node.js tests..."
cd rever-chatbot
npm test
if [ $? -ne 0 ]; then
  echo "[FAIL] Node.js tests failed — deploy aborted."
  exit 1
fi
cd ..
echo "[OK] Node.js tests passed"

# -- Build --------------------------------------------------------------------
echo "[BUILD] Building Flutter Web..."
cd flutter_app
flutter build web --release \
  --dart-define=GROQ_API_KEY="${GROQ_API_KEY}" \
  --dart-define=SHOPIFY_STORE_DOMAIN="${SHOPIFY_STORE_DOMAIN}" \
  --dart-define=SHOPIFY_STOREFRONT_TOKEN="${SHOPIFY_STOREFRONT_PUBLIC_TOKEN}"

cd ..
echo "[OK] Build complete -> flutter_app/build/web"

# -- Deploy to Firebase Hosting -----------------------------------------------
echo "[DEPLOY] Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "[DONE] Live at: https://rever-c494a.web.app"
echo ""
