#!/bin/bash

if [[ $# != 2 ]]; then
   echo -e "Usage: $0 <channel> <version number>\n\ne.g.\n    $0 stable 0.5.0"
   exit 1
fi

TARGET_FILE=$1
NEW_VERSION=$2
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

#Remove leading 'v' if provided
NEW_VERSION=${NEW_VERSION#v}

# Split version number
IFS='.' read -ra VERSION_PARTS <<< "$NEW_VERSION"

if [[ $TARGET_FILE != "stable" ]]; then
   echo "Currently, only the channel 'stable' is supported."
   exit -1
fi

TEMP_FILE=$(mktemp)
echo -e "# Write a short summary of the changes/fixes in this update\n" > $TEMP_FILE

FINISHED=0
while [ $FINISHED -eq 0 ]; do
   $EDITOR $TEMP_FILE

   echo "Your summary:"
   echo "----------------------------------------"
   tail -n +2 $TEMP_FILE
   echo "----------------------------------------"


   if [[ $(tail -n +2 $TEMP_FILE) == "" ]]; then
      echo "Empty summary, aborting ..."
      exit 0
   fi

   read -rep 'Are you finished editing the summary? (y/N) ' -n 1
   echo

   if [[ $REPLY =~ ^[Yy]$ ]]
   then
      FINISHED=1
   fi
done

SUMMARY=$(tail -n +2 $TEMP_FILE | sed ':a;N;$!ba;s/\n/\\n/g')
OUTPUT=$(printf '{ "version": { "full": "%s", "major": %s, "minor": %s, "bugfix": %s }, "timestamp": "%s", "summary": "%s"}' "$NEW_VERSION" "${VERSION_PARTS[0]}" "${VERSION_PARTS[1]}" "${VERSION_PARTS[2]}" "$TIMESTAMP" "$SUMMARY")

echo "------------------------------------"
echo "$OUTPUT"
echo "------------------------------------"
echo

read -rep "Are you sure you want to push this new version ($NEW_VERSION)? (y/N) " -n 1
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
   exit 1
fi

git checkout gh-pages > /dev/null

if [[ $? != "0" ]]; then
   echo "Error switching branches. Did you make any local changes?"
   exit 1
fi

echo $OUTPUT > $TARGET_FILE
git commit $TARGET_FILE -m "Update to $NEW_VERSION" > /dev/null
git push origin gh-pages > /dev/null
git checkout master > /dev/null
