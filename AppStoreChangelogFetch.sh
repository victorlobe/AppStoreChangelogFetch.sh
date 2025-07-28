#!/bin/bash

#AppStoreChangelogFetch.sh

# === CONFIGURATION ===
# Replace the following placeholders with your actual App Store Connect API details:

KEY_ID="YOUR_KEY_ID"                              # e.g. "ABC123XYZ9"
ISSUER_ID="YOUR_ISSUER_ID"                        # e.g. "11223344-5566-7788-99AA-BBCCDDEEFF00"
PRIVATE_KEY_PATH="/path/to/AuthKey.p8"            # path to your AuthKey file
APP_ID="YOUR_APP_ID"                              # internal App Store Connect App ID

LOCALE="en-US"                                    # App Store Region, e.g. "en-US" or "de-DE"
DATE_FORMAT="%Y-%m-%d %H:%M"                      # desired date format (e.g. "%Y-%m-%d %H:%M" for English style)

# === GENERATE JWT TOKEN ===
JWT=$(ruby <<EOF
require 'jwt'
key = OpenSSL::PKey::EC.new(File.read('$PRIVATE_KEY_PATH'))
header = { alg: 'ES256', kid: '$KEY_ID', typ: 'JWT' }
claims = {
  iss: '$ISSUER_ID',
  exp: Time.now.to_i + 1200,
  aud: 'appstoreconnect-v1'
}
puts JWT.encode(claims, key, 'ES256', header)
EOF
)

# === FETCH ALL APP STORE VERSIONS (WITH PAGINATION) ===
echo "📦 Fetching App Store versions..."

VERSION_IDS=()
NEXT_URL="https://api.appstoreconnect.apple.com/v1/apps/$APP_ID/appStoreVersions"

while [[ -n "$NEXT_URL" ]]; do
  RESPONSE=$(curl -s -H "Authorization: Bearer $JWT" "$NEXT_URL")
  IDS=$(echo "$RESPONSE" | jq -r '.data[].id')
  VERSION_IDS+=($IDS)
  NEXT_URL=$(echo "$RESPONSE" | jq -r '.links.next // empty')
done

# === FETCH DETAILS FOR EACH VERSION ===
for VERSION_ID in "${VERSION_IDS[@]}"; do
  VERSION_INFO=$(curl -s -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$VERSION_ID")

  VERSION_STRING=$(echo "$VERSION_INFO" | jq -r '.data.attributes.versionString')

  # Determine best available date (release → earliestRelease → created)
  RELEASE_DATE_RAW=""
  RELEASE_LABEL=""

  RELEASE_DATE_RAW=$(echo "$VERSION_INFO" | jq -r '.data.attributes.releaseDate // empty')
  if [[ -n "$RELEASE_DATE_RAW" ]]; then
    RELEASE_LABEL="Released"
  else
    RELEASE_DATE_RAW=$(echo "$VERSION_INFO" | jq -r '.data.attributes.earliestReleaseDate // empty')
    if [[ -n "$RELEASE_DATE_RAW" ]]; then
      RELEASE_LABEL="Planned"
    else
      RELEASE_DATE_RAW=$(echo "$VERSION_INFO" | jq -r '.data.attributes.createdDate // empty')
      RELEASE_LABEL="Created"
    fi
  fi

  # Sanitize timezone offset for macOS date
  RELEASE_DATE_SANITIZED=$(echo "$RELEASE_DATE_RAW" | sed -E 's/([-+][0-9]{2}):([0-9]{2})$/\1\2/')

  # Format date using configured DATE_FORMAT
  if [[ -n "$RELEASE_DATE_SANITIZED" ]]; then
    RELEASE_DATE_FORMATTED=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$RELEASE_DATE_SANITIZED" +"$DATE_FORMAT" 2>/dev/null)
    RELEASE_DATE_FORMATTED=${RELEASE_DATE_FORMATTED:-$RELEASE_DATE_RAW}
  else
    RELEASE_DATE_FORMATTED="– No release date available"
  fi

  # Fetch localized "What's New"
  LOCALIZATIONS=$(curl -s -H "Authorization: Bearer $JWT" \
    "https://api.appstoreconnect.apple.com/v1/appStoreVersions/$VERSION_ID/appStoreVersionLocalizations")

  WHATS_NEW=$(echo "$LOCALIZATIONS" | jq -r "
    (.data[] | select(.attributes.locale == \"$LOCALE\") | .attributes.whatsNew),
    (.data[0].attributes.whatsNew)
    // \"– No changelog found.\"
  " | head -n 1)

  echo -e "\n📦 Version: $VERSION_STRING"
  echo -e "📅 $RELEASE_LABEL: $RELEASE_DATE_FORMATTED"
  echo -e "📝 Changelog:\n$WHATS_NEW"
done