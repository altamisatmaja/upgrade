You are maintaining the `upgrade` opportunity database in the current directory.
Today is {{TODAY}}. Work only inside this directory.

## Goal for this run
1. **Discover {{NEW}} new opportunities** that are NOT already in `data.txt` (compare by name; also avoid near-duplicates).
   Audience: an Indonesian software / AI / robotics engineer and startup founder who wants to study, work, research or build abroad.
   Cover all kinds: scholarships, fellowships, research internships, talent/work visas, working holiday and youth mobility,
   remote work platforms and companies hiring from Indonesia, startup accelerators and founder visas, grants, competitions,
   conferences with travel grants, government labor programs. Actively look for obscure, new (announced in the last 12 months)
   and long-running-but-little-known programs, not only famous ones. Prefer programs open to Indonesian citizens.
2. **Re-verify {{RECHECK}} existing rows**, prioritising: rows with status `C`, then `V` rows whose `checked_on` is oldest.
   For each, confirm on the official site (or a reputable recent source) the current status, next deadline/window and key facts.

## Rules for editing `data.txt`
- Read the header comments at the top of `data.txt` and follow the exact pipe-separated format with 10 fields.
- Write everything in **English**. Never add personal information about anyone (no names of the reader's own projects or companies).
- Put new rows under the matching category block. Reuse existing category names; create a new category only if nothing fits.
- Set status `V` and `checked_on` = {{TODAY}} **only** if you confirmed the facts on the web during this run. Otherwise status `C` and empty `checked_on`.
- Every `link` must be an `https://` URL to the official page when possible. Do not invent URLs; if unsure, use the official homepage.
- In `summary`, include concrete dates/amounts you verified, and say "expected"/"estimated" when a date is inferred.
- If a program has ended, do not delete the row: start its summary with "DISCONTINUED (YYYY):" and set fit to 1.
- `fit`: 3 = strong fit for software/AI/robotics engineering or founding, 2 = good fit, 1 = general.
- Do not touch any other file except `automation/last-run.md`.

## When done
1. Run `python3 build.py`. If it prints INVALID DATA, fix `data.txt` and run it again until it prints OK.
2. Write `automation/last-run.md` (overwrite) with: the date, counts (added / re-verified / changed / discontinued),
   a bullet list of each new opportunity (name, country, one line why it matters, deadline if known),
   and a bullet list of important changes found while re-verifying (new deadlines, closures). Keep it under 120 lines.
