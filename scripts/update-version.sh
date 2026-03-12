#!/bin/bash

# Script to update version across all files
# Usage: ./scripts/update-version.sh 1.2.3

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.2.3"
    exit 1
fi

echo "Updating version to $VERSION..."

# Update podspec
if [ -f "bidscubeSdk.podspec" ]; then
    sed -i.bak "s/spec.version.*=.*/spec.version      = \"$VERSION\"/" bidscubeSdk.podspec
    rm -f bidscubeSdk.podspec.bak
    echo "✅ Updated bidscubeSdk.podspec"
fi

# Update package.json if it exists
if [ -f "package.json" ]; then
    # Use node to update package.json properly
    node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    pkg.version = '$VERSION';
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    "
    echo "✅ Updated package.json"
fi

# Update any version constants in Swift files
if [ -f "bidscubeSdk/Core/Constants.swift" ]; then
    sed -i.bak "s/public static let sdkVersion = \".*\"/public static let sdkVersion = \"$VERSION\"/" bidscubeSdk/Core/Constants.swift
    rm -f bidscubeSdk/Core/Constants.swift.bak
    echo "✅ Updated Constants.swift"
fi

# Update Sources version if it exists
if [ -f "bidscubeSdk/Core/Constants.swift" ]; then
    sed -i.bak "s/public static let sdkVersion = \".*\"/public static let sdkVersion = \"$VERSION\"/" bidscubeSdk/Core/Constants.swift
    rm -f bidscubeSdk/Core/Constants.swift.bak
    echo "✅ Updated Constants.swift"
fi

# Update changelog in README.md
if [ -f "README.md" ]; then
    # Add new version entry to changelog
    sed -i.bak "/## Changelog/a\\
\\
### Version $VERSION\\
- Automated release via GitHub Actions\\
- Bug fixes and improvements\\
" README.md
    rm -f README.md.bak
    echo "✅ Updated README.md changelog"
fi

echo "🎉 Version $VERSION updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit the changes: git add . && git commit -m \"Update to version: v$VERSION\""
echo "3. Create and push tag: git tag v$VERSION && git push origin v$VERSION"