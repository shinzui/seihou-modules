---
type: Friction Entry
title: "Seihou update silently cancels and exits 0 without a terminal"
description: "Plain seihou update in a non-interactive shell treats end of input as a declined confirmation, prints a cancellation with no visible prompt, changes nothing and still exits 0, so automation has to retry with --json and cannot detect the skip from the exit status."
generated:
  by: "claude-code/claude-opus-5-5"
  at: "2026-11-04T17:41:44Z"
frictionId: FRIC-11
status: "promoted"
impact: nuisance
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou"
affectedVersion: "0.15.0.0"
tags:
  - "seihou"
  - "update"
  - "automation"
promotedTo: "mori://shinzui/seihou/okf/improvement-requests/concepts/IR-16"
amended:
  - by: "claude-code/claude-opus-5-5"
    at: "2026-11-04T18:07:22Z"
    change: "Promoted to an improvement request for a non-zero exit and a hint when an update has no terminal to confirm on."
---
# Seihou update silently cancels and exits 0 without a terminal

## Attempted

Run seihou update nix-bun-flake from a non-interactive shell to take the nix-bun-flake 0.6.0 release, reported by a session working in mori://shinzui/kansoku-ui. Reproduced here with seihou update child --no-commands </dev/null on a minimal local module with a pending 1.0.0 to 1.1.0 update.

## Encountered

The command printed the update plan and a cancellation message, showed no prompt, left the file at the old version and exited 0. Repeating it with --json applied the update. The update help does say that --json disables prompts, but the cancellation message does not point to it. The reproduction showed the exit status; the kansoku-ui report covered the missing prompt and the retry with --json.

```text
Update cancelled; no managed state was changed.
child  1.0.0 -> 1.1.0
exit 0
name=demo v1.0.0
```
