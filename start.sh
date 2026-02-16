#!/usr/bin/env sh
set -eu

APP_DIR="/app"
SEGMENTS_DIR="$APP_DIR/segments4"
PROFILES_DIR="$APP_DIR/profiles"
CUSTOM_PROFILES_DIR="$APP_DIR/customprofiles"
SEGMENT_BASE_URL="https://brouter.de/brouter/segments4"

# Ireland-only tiles to keep storage usage low.
IRELAND_SEGMENTS="W15_N50.rd5 W10_N50.rd5 W10_N55.rd5"

mkdir -p "$SEGMENTS_DIR" "$PROFILES_DIR" "$CUSTOM_PROFILES_DIR"
cd "$APP_DIR"

# Render injects PORT at runtime; fallback to the BRouter default.
PORT="${PORT:-17777}"
MAX_THREADS="${MAX_THREADS:-1}"
JAVA_OPTS="${JAVA_OPTS:--Xmx256M -Xms128M -Xmn8M -DmaxRunningTime=300 -DuseRFCMimeType=false}"

# Find a BRouter server jar from the extracted archive.
B_ROUTER_JAR=""
for candidate in \
  "$APP_DIR"/brouter.jar \
  "$APP_DIR"/*/*all.jar \
  "$APP_DIR"/*/*server*.jar \
  "$APP_DIR"/*/*.jar \
  "$APP_DIR"/*.jar
 do
  if [ -f "$candidate" ]; then
    B_ROUTER_JAR="$candidate"
    break
  fi
done

if [ -z "$B_ROUTER_JAR" ]; then
  echo "No BRouter JAR found under $APP_DIR"
  exit 1
fi

# Ensure required Ireland map segments exist.
for tile in $IRELAND_SEGMENTS; do
  target="$SEGMENTS_DIR/$tile"
  if [ ! -f "$target" ]; then
    echo "Downloading $tile ..."
    curl -fsSL -o "$target" "$SEGMENT_BASE_URL/$tile"
  fi
done

# Ensure lookups.dat exists in the profiles folder.
if [ ! -f "$PROFILES_DIR/lookups.dat" ]; then
  found_lookup="$(find "$APP_DIR" -type f -name lookups.dat | head -n 1 || true)"
  if [ -n "$found_lookup" ]; then
    cp "$found_lookup" "$PROFILES_DIR/lookups.dat"
  else
    echo "lookups.dat not found in $PROFILES_DIR or extracted BRouter files"
    exit 1
  fi
fi

echo "Starting BRouter on 0.0.0.0:$PORT using $B_ROUTER_JAR"
exec java $JAVA_OPTS -cp "$B_ROUTER_JAR" btools.server.RouteServer \
  "$SEGMENTS_DIR" "$PROFILES_DIR" "$CUSTOM_PROFILES_DIR" "$PORT" "$MAX_THREADS" 0.0.0.0
