#!/bin/bash
set -e

echo "🔐 Generating Sparkle EdDSA Keys..."

# Check if Sparkle is installed
if ! command -v generate_keys &> /dev/null; then
    echo "❌ Sparkle's generate_keys tool not found"
    echo ""
    echo "First, add Sparkle to your project via Xcode:"
    echo "1. File > Add Package Dependencies"
    echo "2. https://github.com/sparkle-project/Sparkle"
    echo "3. Add version 2.7.0+"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Generate keys in project root
cd "$(dirname "$0")/.."

if [ -f "sparkle_eddsa_private.pem" ]; then
    echo "⚠️  Keys already exist!"
    read -p "Overwrite existing keys? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled"
        exit 0
    fi
fi

# Generate the keys
generate_keys

echo ""
echo "✅ Keys generated successfully!"
echo ""
echo "📁 Private key: sparkle_eddsa_private.pem (KEEP SECRET!)"
echo "📁 Public key:  sparkle_eddsa_public.pem"
echo ""
echo "⚠️  IMPORTANT:"
echo "  1. Back up sparkle_eddsa_private.pem securely"
echo "  2. Never commit the private key to git"
echo "  3. Add the public key to Info.plist as SUPublicEDKey"
echo ""
echo "Public key content:"
cat sparkle_eddsa_public.pem
