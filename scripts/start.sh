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
echo "🌐 Starting Phoenix server..."
echo "=========================================="
exec mix phx.server

