#!/bin/bash

# Update version across both CocoaPods delivery packages.
# Usage: ./scripts/update-version.sh 1.1.4

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.1.4"
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

# Primary delivery packages (modern + legacy)
update_podspec "BidscubeSDKAppLovin.podspec"
update_podspec "BidscubeSDKAppLovinLegacy.podspec"

# Deprecated standalone pod (compatibility only)
update_podspec "bidscubeSdk.podspec"

if [ -f "bidscubeSdk/Core/Constants.swift" ]; then
    sed -i.bak "s/public static let sdkVersion = \".*\"/public static let sdkVersion = \"$VERSION\"/" bidscubeSdk/Core/Constants.swift
    rm -f bidscubeSdk/Core/Constants.swift.bak
    echo "✅ Updated bidscubeSdk/Core/Constants.swift"
fi

if [ -f "README.md" ]; then
    sed -i.bak "s/pod 'BidscubeSDKAppLovin', '[^']*'/pod 'BidscubeSDKAppLovin', '$VERSION'/" README.md
    sed -i.bak "s/pod 'BidscubeSDKAppLovinLegacy', '[^']*'/pod 'BidscubeSDKAppLovinLegacy', '$VERSION'/" README.md
    sed -i.bak "s/\`BidscubeSDKAppLovin\` \*\*[0-9.][0-9.]*\*\*/\`BidscubeSDKAppLovin\` **$VERSION**/" README.md
    sed -i.bak "s/\`BidscubeSDKAppLovinLegacy\` \*\*[0-9.][0-9.]*\*\*/\`BidscubeSDKAppLovinLegacy\` **$VERSION**/" README.md
    sed -i.bak "s/Current release: \*\*[0-9.][0-9.]*\*\*/Current release: **$VERSION**/" README.md
    rm -f README.md.bak
    echo "✅ Updated README.md version references"
fi

for podfile in Podfile.example Podfile.legacy.example Podfile; do
    if [ -f "$podfile" ]; then
        sed -i.bak "s/pod 'BidscubeSDKAppLovin', '[^']*'/pod 'BidscubeSDKAppLovin', '$VERSION'/" "$podfile"
        sed -i.bak "s/pod 'BidscubeSDKAppLovinLegacy', '[^']*'/pod 'BidscubeSDKAppLovinLegacy', '$VERSION'/" "$podfile"
        rm -f "${podfile}.bak"
        echo "✅ Updated $podfile"
    fi
done

for doc in applovin-adapter/README.md RELEASE.md; do
    if [ -f "$doc" ]; then
        sed -i.bak "s/pod 'BidscubeSDKAppLovin', '[^']*'/pod 'BidscubeSDKAppLovin', '$VERSION'/" "$doc"
        sed -i.bak "s/pod 'BidscubeSDKAppLovinLegacy', '[^']*'/pod 'BidscubeSDKAppLovinLegacy', '$VERSION'/" "$doc"
        sed -i.bak "s/\*\*Release $VERSION\*\*/\*\*Release $VERSION\*\*/" "$doc" 2>/dev/null || true
        sed -i.bak "s/\*\*SDK \/ adapter [0-9.][0-9.]*\*\*/\*\*Release $VERSION\*\*/" "$doc" 2>/dev/null || true
        sed -i.bak "s/# Release [0-9.][0-9.]*/# Release $VERSION/" "$doc" 2>/dev/null || true
        sed -i.bak "s/\*\*1\.[0-9.][0-9.]*\*\*/\*\*$VERSION\*\*/g" "$doc" 2>/dev/null || true
        rm -f "${doc}.bak"
        echo "✅ Updated $doc"
    fi
done

if [ -f "testApp/README.md" ]; then
    sed -i.bak "s/BidscubeSDKAppLovin [0-9.][0-9.]*/BidscubeSDKAppLovin $VERSION/" testApp/README.md
    rm -f testApp/README.md.bak
    echo "✅ Updated testApp/README.md"
fi

"$(dirname "$0")/sync-cocoapods-spec.sh"

echo "🎉 Version $VERSION updated successfully!"
echo ""
echo "Next steps:"
echo "1. Review the changes: git diff"
echo "2. Commit: git add . && git commit -m \"Update to version $VERSION\""
echo "3. Tag and push: git tag v$VERSION && git push origin main --tags"
