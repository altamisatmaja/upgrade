#!/bin/bash
# Install the weekly launchd job (Sunday 10:00). If the laptop is asleep/off at that
# time, launchd runs it once at the next wake. Logs: automation/update.log
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
LABEL="com.altamis.upgrade.weekly"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
mkdir -p "$HOME/Library/LaunchAgents"
chmod +x "$DIR/update.sh"
cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>/usr/bin/caffeinate</string><string>-i</string><string>/bin/bash</string><string>$DIR/update.sh</string></array>
  <key>WorkingDirectory</key><string>$DIR/..</string>
  <key>StartCalendarInterval</key>
  <dict><key>Weekday</key><integer>0</integer><key>Hour</key><integer>10</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$DIR/launchd.log</string>
  <key>StandardErrorPath</key><string>$DIR/launchd.log</string>
</dict>
</plist>
PL
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Installed: $LABEL (every Sunday 10:00)"
echo "Run now:   launchctl kickstart gui/$(id -u)/$LABEL"
