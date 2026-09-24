#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(dirname "$0")/../test/fixtures/files/osm_client_details"
DEST_DIR="$(dirname "$0")/../test/fixtures/files/new_osm_client_details"

mkdir -p "$DEST_DIR"

for file in "$SOURCE_DIR"/*.json; do
  filename="$(basename "$file")"
  if [[ "$filename" == "list.json" ]]; then
    echo "SKIP $filename: intentionally"
    continue
  fi

  osm_type="$(jq -r '.osm_type' "$file")"
  osm_id="$(jq -r '.osm_id' "$file")"

  if [[ "$osm_type" == "null" || "$osm_id" == "null" ]]; then
    echo "SKIP $filename: missing osm_type or osm_id"
    continue
  fi

  url="https://nominatim.openstreetmap.org/details?osmtype=${osm_type}&osmid=${osm_id}&addressdetails=1"
  echo "Fetching $filename ($url)"
  curl -sSf \
    -H "Accept: application/json" \
    -H "User-Agent: ops-portal-fixture-updater/1.0" \
    "$url" \
  | jq '.' > "$DEST_DIR/$filename"

  # Nominatim usage policy: max 1 request/second
  sleep 1
done

echo "Done. Files saved to $DEST_DIR"
