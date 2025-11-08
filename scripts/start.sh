#!/bin/bash
set -e

echo "=========================================="
echo "🚀 Starting Evaa CRM Application"
echo "=========================================="

# Check environment variables
echo ""
echo "📋 Checking environment variables..."
if [ -z "$SECRET_KEY_BASE" ]; then
  echo "❌ ERROR: SECRET_KEY_BASE is not set!"
  exit 1
else
  echo "✅ SECRET_KEY_BASE is set"
fi

if [ -z "$DATABASE_URL" ] && [ -z "$DATABASE_PUBLIC_URL" ]; then
  echo "❌ ERROR: DATABASE_URL is not set!"
  echo "   Please configure DATABASE_URL in Railway variables"
  echo "   Or connect PostgreSQL service to your application"
  exit 1
else
  echo "✅ DATABASE_URL is set"
fi

if [ -z "$PHX_SERVER" ]; then
  echo "⚠️  WARNING: PHX_SERVER is not set (should be 'true')"
else
  echo "✅ PHX_SERVER is set to: $PHX_SERVER"
fi

echo ""
echo "📦 Running database migrations..."
if mix ecto.migrate; then
  echo "✅ Migrations completed successfully"
else
  echo "❌ ERROR: Migrations failed!"
  echo "   Check DATABASE_URL and PostgreSQL connection"
  exit 1
fi

echo ""
echo "🎨 Building and digesting assets..."
# In umbrella projects, we need to compile assets for the specific app
# First, ensure we're in the root directory
cd "$(dirname "$0")/.." || exit 1

# Compile Tailwind CSS (minified for production)
echo "  Compiling Tailwind CSS..."
if mix tailwind evaa_crm_web_gaepell --minify; then
  echo "  ✅ Tailwind compiled"
else
  echo "  ⚠️  Tailwind compilation failed"
fi

# Compile JavaScript with esbuild (minified for production)
echo "  Compiling JavaScript..."
if mix esbuild evaa_crm_web_gaepell --minify; then
  echo "  ✅ JavaScript compiled"
else
  echo "  ⚠️  JavaScript compilation failed"
fi

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
if mix phx.digest; then
  echo "✅ Assets compiled and digested successfully"
else
  echo "⚠️  WARNING: Asset digest failed, but continuing..."
  echo "   The app may work but cache busting might not work"
fi

echo ""
echo "🌐 Starting Phoenix server..."
echo "=========================================="
exec mix phx.server

