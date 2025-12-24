#!/bin/bash

#
# Ksign Build Script with Logging
#

set -e

# Configuration
LOG_FILE="build_log_$(date +%Y%m%d_%H%M%S).txt"
PROJECT_DIR="/Users/ethfr/Downloads/SwiftSignerPro-Core"

cd "$PROJECT_DIR"

echo "🔨 Building Ksign..." | tee "$LOG_FILE"
echo "📝 Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "⏰ Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Build command
xcodebuild \
    -project Ksign.xcodeproj \
    -scheme Ksign \
    -configuration Release \
    -arch arm64 \
    -sdk iphoneos \
    -derivedDataPath .build/Ksign \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    DEVELOPMENT_TEAM="" \
    2>&1 | tee -a "$LOG_FILE"

BUILD_STATUS=${PIPESTATUS[0]}

echo "" | tee -a "$LOG_FILE"

if [ $BUILD_STATUS -eq 0 ]; then
    echo "✅ Build SUCCEEDED" | tee -a "$LOG_FILE"
    
    # Create IPA
    echo "📦 Creating IPA..." | tee -a "$LOG_FILE"
    rm -rf Payload packages 2>/dev/null || true
    mkdir -p Payload packages
    cp -r .build/Ksign/Build/Products/Release-iphoneos/Ksign.app Payload/
    chmod -R 0755 Payload/Ksign.app
    rm -rf Payload/Ksign.app/_CodeSignature
    cp deps/* Payload/Ksign.app/ 2>/dev/null || true
    zip -r9 packages/Ksign.ipa Payload 2>&1 | tee -a "$LOG_FILE"
    
    echo "" | tee -a "$LOG_FILE"
    echo "🎉 IPA created: packages/Ksign.ipa" | tee -a "$LOG_FILE"
    ls -lh packages/Ksign.ipa | tee -a "$LOG_FILE"
else
    echo "❌ Build FAILED with status $BUILD_STATUS" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "📋 Errors:" | tee -a "$LOG_FILE"
    grep -E "error:" "$LOG_FILE" | tail -20
fi

echo "" | tee -a "$LOG_FILE"
echo "⏰ Finished: $(date)" | tee -a "$LOG_FILE"
