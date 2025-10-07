# Setup script for GP CRM - PowerShell version
Write-Host "🚀 Setting up GP CRM for deployment..." -ForegroundColor Green

# Check if git is initialized
if (-not (Test-Path ".git")) {
    Write-Host "📁 Initializing git repository..." -ForegroundColor Yellow
    git init
}

# Add remote if not exists
$remoteUrl = git remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "🔗 Adding remote repository..." -ForegroundColor Yellow
    git remote add origin https://github.com/rickspov/gp-crm.git
}

# Add all files
Write-Host "📦 Adding files to git..." -ForegroundColor Yellow
git add .

# Check if there are changes to commit
$status = git status --porcelain
if ($status) {
    Write-Host "💾 Committing changes..." -ForegroundColor Yellow
    git commit -m "Initial commit: GP CRM system with Railway configuration"
} else {
    Write-Host "✅ No changes to commit" -ForegroundColor Green
}

# Push to repository
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Yellow
git branch -M main
git push -u origin main

Write-Host "✅ Setup completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. Go to https://railway.app" -ForegroundColor White
Write-Host "2. Login with GitHub" -ForegroundColor White
Write-Host "3. Create new project" -ForegroundColor White
Write-Host "4. Select 'Deploy from GitHub repo'" -ForegroundColor White
Write-Host "5. Choose 'rickspov/gp-crm'" -ForegroundColor White
Write-Host "6. Add PostgreSQL database" -ForegroundColor White
Write-Host "7. Configure environment variables" -ForegroundColor White
Write-Host "8. Deploy!" -ForegroundColor White
