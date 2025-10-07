#!/bin/bash

# Deploy script for Railway
echo "🚀 Starting deployment..."

# Install dependencies
echo "📦 Installing dependencies..."
mix deps.get --only prod

# Compile dependencies
echo "🔨 Compiling dependencies..."
mix deps.compile

# Build assets
echo "🎨 Building assets..."
mix assets.deploy

# Run database migrations
echo "🗄️ Running database migrations..."
mix ecto.migrate

# Generate secret key base if not set
if [ -z "$SECRET_KEY_BASE" ]; then
  echo "🔑 Generating secret key base..."
  export SECRET_KEY_BASE=$(mix phx.gen.secret)
fi

echo "✅ Deployment completed successfully!"
