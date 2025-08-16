#!/bin/bash

echo "🚀 Building TaskFlow for Production Deployment"
echo "=============================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Analyze code for critical issues only
echo "🔍 Analyzing code for critical issues..."
flutter analyze --no-fatal-infos --no-fatal-warnings

# Build for web production
echo "🏗️  Building for web (production)..."
flutter build web --release --dart-define=ENV=production --web-renderer html

# Check build output
echo "📊 Build complete! Checking output..."
ls -la build/web/

echo ""
echo "✅ Production build ready!"
echo "📁 Build output: build/web/"
echo "🌐 Ready for Vercel deployment"
echo ""
echo "Next steps:"
echo "1. Upload to Vercel or run: vercel --prod"
echo "2. Ensure backend server is accessible"
echo "3. Test the deployed app"