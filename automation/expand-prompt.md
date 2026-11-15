You are growing the `upgrade` opportunity database in the current directory. Today is {{TODAY}}.

## Focus of this batch
{{SLICE}}

## Task
Find **{{COUNT}} new opportunities** in this focus area that are NOT already in `data.txt`.
Before adding, check `data.txt` (Grep) so you do not add duplicates or near-duplicates.
Audience: an Indonesian software / AI / robotics engineer and startup founder who wants to study, work, research,
compete or build abroad. Prefer opportunities open to Indonesian citizens. Include obscure, new and little-known ones,
not only famous programs. Each row must be one specific, real program (not a vague category). Use web search a lot.

## Rules for editing `data.txt`
- Follow the header comments and the exact pipe-separated format with 10 fields. Never use `|` inside a field.
- Write in **English**, in your own words. Never paste sentences from websites. Never add personal information.
- Add rows at the end of the matching category block. Reuse existing category names when they fit
  (e.g. "Hackathons" for hackathons); create a new category only if nothing fits.
- Status `V` with `checked_on` = {{TODAY}} only if you confirmed it exists and the key facts on the web in this run; otherwise `C` and empty `checked_on`.
- `link` must be a real `https://` URL, the official page when possible. Never invent URLs.
- `summary`: one or two sentences with concrete facts (amounts, eligibility, deadlines). Mark inferred dates as "expected".
- `fit`: 3 = strong fit for software/AI/robotics engineering or founding, 2 = good, 1 = general.
- Only edit `data.txt`. Do not touch other files.

## When done
Run `python3 build.py`. If it prints INVALID DATA, fix `data.txt` and re-run until it prints OK.
Finish with one line: `ADDED <number>`.
