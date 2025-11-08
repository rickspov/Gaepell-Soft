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
echo "🌱 Running seeds (idempotent - safe to run multiple times)..."
# Seeds are idempotent, so it's safe to run them every time
# They check if users exist before creating them
if mix run apps/evaa_crm_gaepell/priv/repo/seeds_gaepell.exs; then
  echo "✅ Seeds completed successfully"
else
  echo "⚠️  WARNING: Seeds failed, but continuing..."
  echo "   You may need to create users manually"
fi

echo ""
echo "🎨 Verifying assets are compiled..."
# Assets should be compiled during build, but verify they exist
if [ ! -f "apps/evaa_crm_web_gaepell/priv/static/assets/app.css" ] || [ ! -f "apps/evaa_crm_web_gaepell/priv/static/assets/app.js" ]; then
  echo "⚠️  WARNING: Assets not found, attempting to compile..."
  # Fallback: compile assets if they weren't built during build phase
  if mix tailwind evaa_crm_web_gaepell --minify && mix esbuild evaa_crm_web_gaepell --minify; then
    echo "  ✅ Assets compiled as fallback"
    # Copy additional JS files
    if [ -f "apps/evaa_crm_web_gaepell/assets/js/pwa.js" ]; then
      cp apps/evaa_crm_web_gaepell/assets/js/pwa.js apps/evaa_crm_web_gaepell/priv/static/assets/ 2>/dev/null || true
    fi
    if [ -f "apps/evaa_crm_web_gaepell/assets/js/offline-sync.js" ]; then
      cp apps/evaa_crm_web_gaepell/assets/js/offline-sync.js apps/evaa_crm_web_gaepell/priv/static/assets/ 2>/dev/null || true
    fi
    mix phx.digest 2>/dev/null || true
  else
    echo "  ❌ Asset compilation failed"
  fi
else
  echo "✅ Assets found (compiled during build)"
fi

echo ""
echo "🌐 Starting Phoenix server..."
echo "=========================================="
exec mix phx.server

