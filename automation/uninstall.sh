#!/bin/bash
LABEL="com.altamis.upgrade.weekly"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"
echo "Removed: $LABEL"
