#!/bin/bash

if [[ $# != 2 ]]; then
   echo -e "Usage: $0 <file> <version number>\n\ne.g.\n    $0 ../stable 0.5.0"
   exit 1
fi

TARGET_FILE=$1
NEW_VERSION=$2
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

read -p "Are you sure you want to push this new version ($NEW_VERSION)? (y/N) " -n 1 -r

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
   exit 1
fi

# Split version number
IFS='.' read -ra VERSION_PARTS <<< "$NEW_VERSION"

git checkout gh-pages > /dev/null
git ls-files $TARGET_FILE --error-unmatch >& /dev/null

if [[ $? -ne 0 ]]; then
   echo "ERROR: The file '$TARGET_FILE' is not tracked by git! Did you mistype?"
   git checkout master
   exit 1
fi

printf '{ "version": { "full": "%s", "major": %s, "minor": %s, "bugfix": %s }, "timestamp": "%s" }' "$NEW_VERSION" "${VERSION_PARTS[0]}" "${VERSION_PARTS[1]}" "${VERSION_PARTS[2]}" "$TIMESTAMP" > $TARGET_FILE

echo "New version written to $TARGET_FILE!"
echo "------------------------------------"
cat $TARGET_FILE
echo
echo "------------------------------------"
echo

git commit $TARGET_FILE -m "Update to $NEW_VERSION"
git push origin gh-pages
git checkout master > /dev/null
