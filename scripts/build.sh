#!/bin/bash
set -e

echo "=========================================="
echo "🔨 Building Evaa CRM Application"
echo "=========================================="

echo ""
echo "📦 Installing dependencies..."
mix deps.get --only prod

echo ""
echo "🔨 Compiling application..."
mix compile

echo ""
echo "🎨 Building assets..."
# Compile Tailwind CSS (minified for production)
echo "  Compiling Tailwind CSS..."
mix tailwind evaa_crm_web_gaepell --minify

# Compile JavaScript with esbuild (minified for production)
echo "  Compiling JavaScript..."
mix esbuild evaa_crm_web_gaepell --minify

# Copy additional JS files that aren't bundled
echo "  Copying additional JS files..."
if [ -f "apps/evaa_crm_web_gaepell/assets/js/pwa.js" ]; then
  cp apps/evaa_crm_web_gaepell/assets/js/pwa.js apps/evaa_crm_web_gaepell/priv/static/assets/ 2>/dev/null || true
fi
if [ -f "apps/evaa_crm_web_gaepell/assets/js/offline-sync.js" ]; then
  cp apps/evaa_crm_web_gaepell/assets/js/offline-sync.js apps/evaa_crm_web_gaepell/priv/static/assets/ 2>/dev/null || true
fi

# Generate digest manifest for cache busting
echo "  Generating asset digest..."
mix phx.digest

echo ""
echo "✅ Build completed successfully!"
echo "=========================================="

