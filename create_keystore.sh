#!/bin/bash

# Create keystore for app signing
# Run this from your project root directory

echo "Creating keystore for Crave Food app..."

# Create android directory if it doesn't exist
mkdir -p android/app

# Generate keystore
keytool -genkey -v -keystore android/app/crave-food-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias crave-food-key \
  -storetype JKS

echo ""
echo "Keystore created successfully!"
echo "IMPORTANT: Save the keystore password and key password securely!"
echo "You'll need them for future app updates."
echo ""
echo "Next steps:"
echo "1. Create android/key.properties file with your keystore info"
echo "2. Add key.properties to your .gitignore file"
echo "3. Update android/app/build.gradle.kts to use the keystore"