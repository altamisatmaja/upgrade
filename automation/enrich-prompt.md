You are adding detail pages to the `upgrade` opportunity database in the current directory. Today is {{TODAY}}.

## Entries to enrich (exact names from `data.txt`)
{{NAMES}}

## Task
For each entry: find its row in `data.txt`, open its official website (WebFetch the link, follow to the right page, use
WebSearch if the link is only a homepage), then add an entry to `details.json` keyed by the exact name:

```json
"<exact name>": {
  "who": "eligibility: nationality, degree, age limit, work experience, language tests",
  "covers": "what is funded/provided: tuition, monthly stipend with amount, flights, insurance, salary",
  "dates": "current or next cycle: opens, closes, results, start. Say 'expected' when inferred from past cycles",
  "apply": "how to apply in 1-3 short steps, and the key documents",
  "bond": "return/service obligation after finishing, or 'None stated'",
  "checked_on": "{{TODAY}}"
}
```

## Rules
- **Write in your own words in English. Do not copy sentences from the website.** Facts, numbers, dates and names are fine;
  prose is not. Keep each field under about 60 words.
- Only state what you found on the official site or a reputable recent source. If something is unknown, write "Not stated on the official site".
- If what you found contradicts the row in `data.txt` (wrong summary, window, link, or the program has ended), fix that row too
  and set its status to `V` with `checked_on` = {{TODAY}}. If the program has ended, start the summary with "DISCONTINUED (YYYY):" and set fit to 1.
- `details.json` must stay valid JSON (one object, keys = exact names). Edit only `details.json` and `data.txt`.

## When done
Run `python3 build.py`. If it prints INVALID DATA, fix the files and re-run until it prints OK.
Finish with one line: `ENRICHED <number>`.
