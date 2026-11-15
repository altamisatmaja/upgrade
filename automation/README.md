# Weekly automation (runs on this laptop)

Every **Sunday 10:00** (or at the next wake if the Mac was asleep), `update.sh`:

1. Skips the week if the repo has uncommitted changes, so it never mixes with your own edits.
2. Runs Claude Code headless (`claude -p`) with `prompt.md`: find **25 new** opportunities and **re-verify 20** existing rows (status `C` first, then the oldest `checked_on`).
3. Runs `build.py`. If the data is invalid, everything is restored and nothing is committed.
4. Commits and pushes, which updates the live page. Shows a macOS notification.
5. Writes a summary of what changed to `last-run.md`.

Claude only gets web search/fetch, file read/edit and `python3 build.py`, plus a spending cap per run (`--max-budget-usd`, default $5).

```bash
./install.sh                                              # install the weekly job
launchctl kickstart gui/$(id -u)/com.altamis.upgrade.weekly   # run now
tail -f update.log                                        # watch
./uninstall.sh                                            # remove
UPGRADE_NEW=50 UPGRADE_RECHECK=40 ./update.sh             # bigger one-off run
```
