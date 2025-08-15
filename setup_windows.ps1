# 🚀 Script de Instalación EvaaCRM para Windows
# Uso: .\setup_windows.ps1
# Ejecutar como Administrador

param(
    [switch]$SkipPrerequisites
)

Write-Host "🚀 Iniciando instalación de EvaaCRM en Windows..." -ForegroundColor Green

# Función para escribir mensajes con colores
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Verificar si estamos en el directorio correcto
if (-not (Test-Path "mix.exs")) {
    Write-Error "No se encontró mix.exs. Asegúrate de estar en el directorio raíz del proyecto."
    exit 1
}

# Verificar si se ejecuta como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Este script debe ejecutarse como Administrador. Por favor, ejecuta PowerShell como Administrador."
    exit 1
}

if (-not $SkipPrerequisites) {
    # Verificar Chocolatey
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Warning "Chocolatey no está instalado. Instalando..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Success "Chocolatey instalado"
    } else {
        Write-Success "Chocolatey ya está instalado"
    }

    # Verificar Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning "Git no está instalado. Instalando..."
        choco install git -y
        Write-Success "Git instalado"
    } else {
        Write-Success "Git ya está instalado: $(git --version)"
    }

    # Verificar Elixir
    if (-not (Get-Command elixir -ErrorAction SilentlyContinue)) {
        Write-Warning "Elixir no está instalado. Instalando..."
        choco install elixir -y
        Write-Success "Elixir instalado"
    } else {
        Write-Success "Elixir ya está instalado: $(elixir --version | Select-Object -First 1)"
    }

    # Verificar Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Warning "Node.js no está instalado. Instalando..."
        choco install nodejs -y
        Write-Success "Node.js instalado"
    } else {
        Write-Success "Node.js ya está instalado: $(node --version)"
    }

    # Verificar PostgreSQL
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        Write-Warning "PostgreSQL no está instalado. Instalando..."
        choco install postgresql -y
        Write-Success "PostgreSQL instalado"
    } else {
        Write-Success "PostgreSQL ya está instalado"
    }

    # Verificar Visual Studio Build Tools
    Write-Warning "Verificando Visual Studio Build Tools..."
    choco install visualstudio2019buildtools -y
    Write-Success "Visual Studio Build Tools instalado"

    Write-Host ""
    Write-Host "⚠️  IMPORTANTE: Reinicia tu terminal después de instalar las dependencias." -ForegroundColor Yellow
    Write-Host "Luego ejecuta este script nuevamente con: .\setup_windows.ps1 -SkipPrerequisites" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

# Refrescar variables de entorno
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Instalar dependencias de Elixir
Write-Status "Instalando dependencias de Elixir..."
mix deps.get
if ($LASTEXITCODE -eq 0) {
    Write-Success "Dependencias de Elixir instaladas"
} else {
    Write-Error "Error instalando dependencias de Elixir"
    exit 1
}

# Instalar dependencias de Node.js
Write-Status "Instalando dependencias de Node.js..."
Set-Location "apps\evaa_crm_web_gaepell\assets"
npm install
if ($LASTEXITCODE -eq 0) {
    Write-Success "Dependencias de Node.js instaladas"
} else {
    Write-Error "Error instalando dependencias de Node.js"
    exit 1
}
Set-Location "..\..\.."

# Iniciar PostgreSQL si no está corriendo
Write-Status "Verificando PostgreSQL..."
try {
    $pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
    if ($pgService -and $pgService.Status -ne "Running") {
        Write-Warning "Iniciando PostgreSQL..."
        Start-Service $pgService.Name
    }
    Write-Success "PostgreSQL está corriendo"
} catch {
    Write-Warning "No se pudo verificar PostgreSQL. Asegúrate de que esté corriendo manualmente."
}

# Crear base de datos
Write-Status "Creando base de datos..."
mix ecto.create
if ($LASTEXITCODE -eq 0) {
    Write-Success "Base de datos creada"
} else {
    Write-Error "Error creando base de datos"
    exit 1
}

# Ejecutar migraciones
Write-Status "Ejecutando migraciones..."
mix ecto.migrate
if ($LASTEXITCODE -eq 0) {
    Write-Success "Migraciones ejecutadas"
} else {
    Write-Error "Error ejecutando migraciones"
    exit 1
}

# Compilar assets
Write-Status "Compilando assets..."
Set-Location "apps\evaa_crm_web_gaepell\assets"
npx tailwindcss -i css\app.css -o ..\priv\static\assets\app.css --minify
npx esbuild js\app.js --bundle --target=es2017 --outdir=..\priv\static\assets --external:/fonts/* --external:/images/*
if ($LASTEXITCODE -eq 0) {
    Write-Success "Assets compilados"
} else {
    Write-Error "Error compilando assets"
    exit 1
}
Set-Location "..\..\.."

# Verificar instalación
Write-Status "Verificando instalación..."
if (Get-Command mix -ErrorAction SilentlyContinue) {
    Write-Success "✅ Instalación completada exitosamente!"
} else {
    Write-Error "❌ Error en la instalación"
    exit 1
}

Write-Host ""
Write-Host "🎉 ¡EvaaCRM está listo para usar!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Comandos útiles:" -ForegroundColor Cyan
Write-Host "   • Iniciar servidor: mix phx.server" -ForegroundColor White
Write-Host "   • Con ngrok: ngrok http 4000" -ForegroundColor White
Write-Host "   • Acceso local: http://localhost:4000" -ForegroundColor White
Write-Host ""
Write-Host "📖 Para más información, consulta INSTALL_WINDOWS.md" -ForegroundColor Cyan
Write-Host "" 