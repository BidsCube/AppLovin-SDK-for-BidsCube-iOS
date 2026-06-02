#!/bin/bash

# Update version across the primary BidscubeSDKAppLovin delivery package.
# Usage: ./scripts/update-version.sh 1.0.4

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.4"
    exit 1
fi

echo "Updating version to $VERSION..."

update_podspec() {
    local file=$1
    if [ -f "$file" ]; then
        sed -i.bak "s/spec.version.*=.*/spec.version      = \"$VERSION\"/" "$file"
        rm -f "${file}.bak"
        echo "✅ Updated $file"
    fi
}

# Primary delivery package
update_podspec "BidscubeSDKAppLovin.podspec"

# Deprecated standalone pod (compatibility only; git tracks bidscubeSdk.podspec)
update_podspec "bidscubeSdk.podspec"

if [ -f "bidscubeSdk/Core/Constants.swift" ]; then
    sed -i.bak "s/public static let sdkVersion = \".*\"/public static let sdkVersion = \"$VERSION\"/" bidscubeSdk/Core/Constants.swift
    rm -f bidscubeSdk/Core/Constants.swift.bak
    echo "✅ Updated bidscubeSdk/Core/Constants.swift"
fi

if [ -f "README.md" ]; then
    sed -i.bak "s/pod 'BidscubeSDKAppLovin', '[^']*'/pod 'BidscubeSDKAppLovin', '$VERSION'/" README.md
    sed -i.bak "s/BidscubeSDKAppLovin \*\*[^*]*\*\*/BidscubeSDKAppLovin **$VERSION**/" README.md
    rm -f README.md.bak
    echo "✅ Updated README.md version references"
fi

echo "🎉 Version $VERSION updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit: git add . && git commit -m \"Update to version $VERSION\""
echo "3. Tag and push: git tag v$VERSION && git push origin main --tags"
