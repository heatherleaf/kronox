#!/bin/bash

# release_new_version.sh 
# KronoX
# Created by Peter Ljunglöf on 2009-01-18.

set -o errexit

USERNAME="peter.ljunglof@heatherleaf.se"
CODE_URL="https://kronox.googlecode.com"
RELEASENOTES_URL="$CODE_URL/svn/trunk/ChangeLog.txt"

VERSION=$(defaults read "$PWD/build/Release/KronoX.app/Contents/Info" CFBundleVersion)
if [ "$VERSION" == "" ]; then exit 1; fi

BUILT_PRODUCTS_DIR="build/Release"
VOLNAME="KronoX-$VERSION"
ARCHIVE_FILENAME="build/$VOLNAME.dmg"
DOWNLOAD_URL="$CODE_URL/files/$VOLNAME.dmg"
KEYCHAIN_PRIVKEY_NAME="KronoX Sparkle Private Key"

echo
echo "Releasing the new version $VERSION"
echo " 1. First we create the file $ARCHIVE_FILENAME"
echo " 2. Then you update the Sparkle Appcast"
echo " 3. Then we commit the final changes (Sparkle Appcast)"
echo " 4. Then we upload the file $ARCHIVE_FILENAME"
echo " 5. Finally we create a new svn-tag for the release"
echo
read -p "Do you want to proceed? " ANSWER
if [ $ANSWER != yes ]; then exit 1; fi
echo
read -p "Is $VERSION the correct version? " ANSWER
if [ $ANSWER != yes ]; then exit 1; fi
echo
read -p "Is ChangeLog.txt updated for version $VERSION? " ANSWER
if [ $ANSWER != yes ]; then exit 1; fi
echo

# Check that everything is commited
if [ "$(svn status -q)" ]; then
    echo "==> There are uncommited changes:"
    echo
    svn status
    echo
    exit 1
fi

echo "1. Creating the file $ARCHIVE_FILENAME"
cp COPYING.txt "$BUILT_PRODUCTS_DIR"
rm -rf "$BUILT_PRODUCTS_DIR/KronoX.app.dSYM"
hdiutil create "$ARCHIVE_FILENAME" -srcfolder "$BUILT_PRODUCTS_DIR" -volname "$VOLNAME"
echo

echo "2. Creating the PGP key for the Sparkle Appcast"
echo

SIZE=$(stat -f %z "$ARCHIVE_FILENAME")
PUBDATE=$(date +"%a, %d %b %G %T %z")
SIGNATURE=$(
    openssl dgst -sha1 -binary < "$ARCHIVE_FILENAME" \
	| openssl dgst -dss1 -sign <(security find-generic-password -g -s "$KEYCHAIN_PRIVKEY_NAME" 2>&1 1>/dev/null | perl -pe '($_) = /"(.+)"/; s/\\012/\n/g') \
	| openssl enc -base64
)

if [ "$SIGNATURE" ]; then true; else
    echo "==> Unable to load signing private key with name '$KEYCHAIN_PRIVKEY_NAME' from keychain"
    exit 1
}

cat <<EOF
--------------------------------------------------------------
Insert the following into Sparkle_appcast.xml:

	<item>
		<title>Version $VERSION</title>
		<sparkle:releaseNotesLink>
			$RELEASENOTES_URL
		</sparkle:releaseNotesLink>
		<pubDate>$PUBDATE</pubDate>
		<enclosure 
			url="$DOWNLOAD_URL"
			sparkle:version="$VERSION"
			type="application/octet-stream"
			length="$SIZE"
			sparkle:dsaSignature="$SIGNATURE"
		/>
	</item>
--------------------------------------------------------------
EOF

echo
read -p "Have you updated Sparkle_appcast.xml? " ANSWER
if [ $ANSWER != yes ]; then exit 1; fi
echo


echo "3. Commiting final changes"
svn commit -m "Released new version $VERSION"
echo

echo "4. Uploading $DMGFILE"
python googlecode_upload.py \
    --summary "KronoX, version $VERSION" \
    --project kronox \
    --user "$USERNAME" \
    --labels Featured \
    "$DMGFILE"
echo

echo "5. Tagging the new release, $VOLNAME"
svn copy -m "Tagged release $VERSION" \
    "$CODE_URL/svn/trunk" \
    "$CODE_URL/svn/tags/$VOLNAME" \
    --username "$USERNAME"
echo

echo "Don't forget to remove the 'Featured' label from the old download"
echo
