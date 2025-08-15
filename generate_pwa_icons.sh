#!/bin/bash

# 🎨 Script para generar iconos PWA básicos
# Uso: ./generate_pwa_icons.sh

echo "🎨 Generando iconos PWA..."

# Crear un icono SVG básico para EVA CRM
cat > apps/evaa_crm_web_gaepell/priv/static/images/icon.svg << 'EOF'
<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#3b82f6;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#1d4ed8;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="80" fill="url(#grad)"/>
  <text x="256" y="200" font-family="Arial, sans-serif" font-size="120" font-weight="bold" text-anchor="middle" fill="white">EVA</text>
  <text x="256" y="320" font-family="Arial, sans-serif" font-size="80" font-weight="bold" text-anchor="middle" fill="white">CRM</text>
  <circle cx="256" cy="400" r="20" fill="white" opacity="0.8"/>
</svg>
EOF

echo "✅ Icono SVG creado"

# Instalar librería para convertir SVG a PNG si no está instalada
if ! command -v rsvg-convert &> /dev/null; then
    echo "📦 Instalando librería para conversión de iconos..."
    if command -v brew &> /dev/null; then
        brew install librsvg
    else
        echo "⚠️  Por favor instala librsvg para convertir SVG a PNG:"
        echo "   - macOS: brew install librsvg"
        echo "   - Ubuntu: sudo apt-get install librsvg2-bin"
        echo "   - Windows: Descarga desde https://github.com/2vg/librsvg/releases"
    fi
fi

# Convertir SVG a PNG si rsvg-convert está disponible
if command -v rsvg-convert &> /dev/null; then
    echo "🔄 Convirtiendo SVG a PNG..."
    
    # Icono 192x192
    rsvg-convert -w 192 -h 192 apps/evaa_crm_web_gaepell/priv/static/images/icon.svg > apps/evaa_crm_web_gaepell/priv/static/images/icon-192x192.png
    
    # Icono 512x512
    rsvg-convert -w 512 -h 512 apps/evaa_crm_web_gaepell/priv/static/images/icon.svg > apps/evaa_crm_web_gaepell/priv/static/images/icon-512x512.png
    
    echo "✅ Iconos PNG generados"
else
    echo "⚠️  No se pudo convertir a PNG. Usando solo SVG."
    echo "📝 Para generar PNG, instala librsvg y ejecuta este script nuevamente."
fi

echo ""
echo "🎯 Iconos PWA generados en:"
echo "   📁 apps/evaa_crm_web_gaepell/priv/static/images/"
echo "   📄 icon.svg"
if [ -f "apps/evaa_crm_web_gaepell/priv/static/images/icon-192x192.png" ]; then
    echo "   📄 icon-192x192.png"
    echo "   📄 icon-512x512.png"
fi
echo ""
echo "✅ ¡Iconos PWA listos!" 