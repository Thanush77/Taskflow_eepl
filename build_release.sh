#!/bin/bash

echo "🔨 Building TaskFlow Release APK..."

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release --dart-define=ENV=production

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📦 APK location: build/app/outputs/flutter-apk/app-release.apk"
    
    # Show APK size
    APK_SIZE=$(ls -lh build/app/outputs/flutter-apk/app-release.apk | awk '{print $5}')
    echo "📏 APK Size: $APK_SIZE"
else
    echo "❌ Build failed!"
    exit 1
fi