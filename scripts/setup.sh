#!/bin/bash

# Setup script for GP CRM
echo "🚀 Setting up GP CRM for deployment..."

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "📁 Initializing git repository..."
    git init
fi

# Add remote if not exists
if ! git remote get-url origin > /dev/null 2>&1; then
    echo "🔗 Adding remote repository..."
    git remote add origin https://github.com/rickspov/gp-crm.git
fi

# Add all files
echo "📦 Adding files to git..."
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "✅ No changes to commit"
else
    echo "💾 Committing changes..."
    git commit -m "Initial commit: GP CRM system with Railway configuration"
fi

# Push to repository
echo "🚀 Pushing to GitHub..."
git branch -M main
git push -u origin main

echo "✅ Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Go to https://railway.app"
echo "2. Login with GitHub"
echo "3. Create new project"
echo "4. Select 'Deploy from GitHub repo'"
echo "5. Choose 'rickspov/gp-crm'"
echo "6. Add PostgreSQL database"
echo "7. Configure environment variables"
echo "8. Deploy!"
