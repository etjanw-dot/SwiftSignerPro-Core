#!/bin/bash

#
# Ksign Build Script
# Build iOS IPA for Ksign with various options
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Ksign"
PROJECT_FILE="Ksign.xcodeproj"
SCHEME="Ksign"
BUILD_DIR=".build/${PROJECT_NAME}"
PACKAGES_DIR="packages"
CONFIGURATION="Release"
SDK="iphoneos"
ARCH="arm64"

# Print banner
print_banner() {
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                    Ksign Build Script                     ║"
    echo "║                  Custom Wallpaper Edition                 ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print step
print_step() {
    echo -e "\n${CYAN}▶ $1${NC}"
}

# Print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Show help
show_help() {
    echo -e "${BLUE}Usage:${NC} ./build.sh [options]"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo "  -h, --help         Show this help message"
    echo "  -c, --clean        Clean build directory before building"
    echo "  -d, --deps         Download dependencies only"
    echo "  -b, --build        Build the IPA (default action)"
    echo "  -a, --all          Clean, download deps, and build"
    echo "  -s, --simulator    Build for iOS Simulator instead"
    echo "  -v, --verbose      Show verbose xcodebuild output"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./build.sh              # Build IPA"
    echo "  ./build.sh -c -b        # Clean and build"
    echo "  ./build.sh -a           # Full clean build with deps"
    echo "  ./build.sh -s           # Build for simulator"
}

# Clean build directory
clean_build() {
    print_step "Cleaning build directory..."
    rm -rf "${BUILD_DIR}"
    rm -rf "${PACKAGES_DIR}"
    rm -rf "Payload"
    print_success "Build directory cleaned"
}

# Initialize submodules
init_submodules() {
    print_step "Initializing git submodules..."
    if git submodule update --init --recursive; then
        print_success "Submodules initialized"
    else
        print_warning "Submodules may not be configured"
    fi
}

# Download dependencies
download_deps() {
    print_step "Downloading dependencies..."
    
    rm -rf deps 2>/dev/null || true
    mkdir -p deps
    
    # Download SSL certificates
    echo "  Downloading SSL certificates..."
    curl -sL -o deps/server.crt https://backloop.dev/backloop.dev-cert.crt || true
    curl -sL -o deps/server.key1 https://backloop.dev/backloop.dev-key.part1.pem || true
    curl -sL -o deps/server.key2 https://backloop.dev/backloop.dev-key.part2.pem || true
    
    # Combine key parts
    if [[ -f deps/server.key1 && -f deps/server.key2 ]]; then
        cat deps/server.key1 deps/server.key2 > deps/server.pem 2>/dev/null || true
        rm -f deps/server.key1 deps/server.key2
    fi
    
    # Create common name file
    echo "*.backloop.dev" > deps/commonName.txt
    
    if [[ -f deps/server.crt && -f deps/server.pem ]]; then
        print_success "Dependencies downloaded"
    else
        print_warning "Some dependencies may be missing"
    fi
}

# Build for iOS device
build_ios() {
    local verbose=$1
    
    print_step "Building ${PROJECT_NAME} for iOS..."
    echo "  Configuration: ${CONFIGURATION}"
    echo "  SDK: ${SDK}"
    echo "  Architecture: ${ARCH}"
    
    mkdir -p "${BUILD_DIR}"
    
    local XCODE_ARGS=(
        -project "${PROJECT_FILE}"
        -scheme "${SCHEME}"
        -configuration "${CONFIGURATION}"
        -arch "${ARCH}"
        -sdk "${SDK}"
        -derivedDataPath "${BUILD_DIR}"
        -skipPackagePluginValidation
        -skipMacroValidation
        CODE_SIGNING_ALLOWED=NO
        CODE_SIGNING_REQUIRED=NO
        CODE_SIGN_IDENTITY=""
        DEVELOPMENT_TEAM=""
        ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
        GCC_TREAT_WARNINGS_AS_ERRORS=NO
        SWIFT_TREAT_WARNINGS_AS_ERRORS=NO
    )
    
    if [[ "$verbose" == "true" ]]; then
        xcodebuild "${XCODE_ARGS[@]}"
    else
        xcodebuild "${XCODE_ARGS[@]}" 2>&1 | grep -E "(Build|error:|warning:|✓|✗)" || true
    fi
    
    local BUILD_STATUS=${PIPESTATUS[0]}
    
    if [[ $BUILD_STATUS -eq 0 ]]; then
        print_success "Build completed"
        return 0
    else
        print_error "Build failed with status $BUILD_STATUS"
        return 1
    fi
}

# Build for simulator
build_simulator() {
    local verbose=$1
    
    print_step "Building ${PROJECT_NAME} for iOS Simulator..."
    
    mkdir -p "${BUILD_DIR}"
    
    local XCODE_ARGS=(
        -project "${PROJECT_FILE}"
        -scheme "${SCHEME}"
        -configuration "${CONFIGURATION}"
        -sdk "iphonesimulator"
        -derivedDataPath "${BUILD_DIR}"
        -skipPackagePluginValidation
        -skipMacroValidation
        CODE_SIGNING_ALLOWED=NO
    )
    
    if [[ "$verbose" == "true" ]]; then
        xcodebuild "${XCODE_ARGS[@]}"
    else
        xcodebuild "${XCODE_ARGS[@]}" 2>&1 | grep -E "(Build|error:|warning:)" || true
    fi
    
    local BUILD_STATUS=${PIPESTATUS[0]}
    
    if [[ $BUILD_STATUS -eq 0 ]]; then
        print_success "Simulator build completed"
        return 0
    else
        print_error "Simulator build failed"
        return 1
    fi
}

# Create IPA package
create_ipa() {
    print_step "Creating IPA package..."
    
    local SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    local APP_PATH="${SCRIPT_DIR}/${BUILD_DIR}/Build/Products/Release-${SDK}/${PROJECT_NAME}.app"
    
    if [[ ! -d "$APP_PATH" ]]; then
        print_error "App bundle not found at: $APP_PATH"
        return 1
    fi
    
    # Create staging directory
    rm -rf "${SCRIPT_DIR}/Payload"
    mkdir -p "${SCRIPT_DIR}/Payload"
    
    # Copy app bundle
    cp -r "$APP_PATH" "${SCRIPT_DIR}/Payload/${PROJECT_NAME}.app"
    
    # Set permissions
    chmod -R 0755 "${SCRIPT_DIR}/Payload/${PROJECT_NAME}.app"
    
    # Copy dependencies if they exist
    if [[ -d "${SCRIPT_DIR}/deps" ]]; then
        cp "${SCRIPT_DIR}/deps/"* "${SCRIPT_DIR}/Payload/${PROJECT_NAME}.app/" 2>/dev/null || true
    fi
    
    # Remove code signature (for unsigned IPA)
    rm -rf "${SCRIPT_DIR}/Payload/${PROJECT_NAME}.app/_CodeSignature"
    
    # Create packages directory
    mkdir -p "${SCRIPT_DIR}/${PACKAGES_DIR}"
    
    # Create IPA from script directory
    cd "${SCRIPT_DIR}"
    zip -r9 "${PACKAGES_DIR}/${PROJECT_NAME}.ipa" Payload
    
    local IPA_SIZE=$(du -h "${PACKAGES_DIR}/${PROJECT_NAME}.ipa" | cut -f1)
    
    print_success "IPA created: ${PACKAGES_DIR}/${PROJECT_NAME}.ipa (${IPA_SIZE})"
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Build Successful!                       ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC} IPA Location: ${CYAN}${PACKAGES_DIR}/${PROJECT_NAME}.ipa${NC}"
    echo -e "${GREEN}║${NC} Size: ${CYAN}${IPA_SIZE}${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
}

# Main execution
main() {
    local do_clean=false
    local do_deps=false
    local do_build=false
    local do_simulator=false
    local verbose=false
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        do_build=true
    fi
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                do_clean=true
                shift
                ;;
            -d|--deps)
                do_deps=true
                shift
                ;;
            -b|--build)
                do_build=true
                shift
                ;;
            -a|--all)
                do_clean=true
                do_deps=true
                do_build=true
                shift
                ;;
            -s|--simulator)
                do_simulator=true
                do_build=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_banner
    
    # Execute requested operations
    if [[ "$do_clean" == "true" ]]; then
        clean_build
    fi
    
    if [[ "$do_deps" == "true" ]]; then
        init_submodules
        download_deps
    fi
    
    if [[ "$do_build" == "true" ]]; then
        if [[ "$do_simulator" == "true" ]]; then
            build_simulator "$verbose"
        else
            # Ensure deps exist
            if [[ ! -d deps ]]; then
                download_deps
            fi
            
            if build_ios "$verbose"; then
                create_ipa
            else
                exit 1
            fi
        fi
    fi
}

# Run main with all arguments
main "$@"
