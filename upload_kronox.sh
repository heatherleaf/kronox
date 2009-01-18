#!/bin/sh

# upload_kronox.sh
# KronoX
#
# Created by Peter Ljunglöf on 2009-01-18.
# Copyright 2009 Heatherleaf. All rights reserved.

USERNAME="peter.ljunglof@heatherleaf.se"
CODE_URL="https://kronox.googlecode.com"
VERSION=$(defaults read "build/Release/KronoX.app/Contents/Info" CFBundleVersion)
if [ "$VERSION" == "" ]; then exit 1; fi
VOLNAME="KronoX-$VERSION"
DMGFILE="build/$VOLNAME.dmg"
if [ -f "$DMGFILE" ]; then true; else 
	echo "The file $DMGFILE does not exist"
	exit 1
fi

echo "Uploading new version $VERSION"
echo " 1. First we commit"
echo " 2. Then we upload the file $DMGFILE"
echo " 3. Finally we create a new svn-tag for the release"
echo
read -p "Do you want to proceed? " ANSWER
if [ $ANSWER != yes ]; then exit 1; fi
echo
read -p "Is ChangeLog.txt updated for version $VERSION? " ANSWER
if [ $ANSWER != yes ]; then exit 1; fi
echo
read -p "Have you updated Sparkle_appcast.xml? " ANSWER
if [ $ANSWER != yes ]; then exit 1; fi
echo

echo "1. Commiting final changes"
svn commit -m "Released new version $VERSION"

echo "2. Uploading $DMGFILE"
python googlecode_upload.py --summary "KronoX, version $VERSION" \
							--project kronox \
							--user "$USERNAME" \
							--labels Featured \
							"$DMGFILE"

echo "3. Tagging the new release, $VOLNAME"
svn copy -m "Tagged release $VERSION" "$CODE_URL/svn/trunk" \
			"$CODE_URL/svn/tags/$VOLNAME" \
			--username "$USERNAME"

