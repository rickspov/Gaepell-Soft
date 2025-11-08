#!/bin/bash
set -e

echo "=========================================="
echo "🌱 Running database seeds"
echo "=========================================="

echo ""
echo "📦 Running seeds_gaepell.exs..."
mix run apps/evaa_crm_gaepell/priv/repo/seeds_gaepell.exs

echo ""
echo "✅ Seeds completed successfully!"
echo "=========================================="

