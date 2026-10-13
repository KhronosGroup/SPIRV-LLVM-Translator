---
name: spirv-translator-backport
description: Backport a single SPIRV-LLVM-Translator commit or PR across a release range you confirm (in-tree checkout only, not standalone). Cherry-picks, adapts, builds, and tests locally for each release — does not push or open PRs (see spirv-translator-backport-prs for that). Pass a commit hash or PR number as argument.
allowed-tools: Bash(git *) Bash(cmake *) Bash(ninja *) Bash(gh *) Bash(llvm-lit *) Bash(clang-format *) Bash(clang-format-diff.py *) Bash(sed *) Bash(grep *) Bash(python3 *)
---

Read `docs/BackportingToReleaseBranches.md` (from the repository root) in full, then follow its Setup and **Part 1 — Prepare** for `$ARGUMENTS`, which is the PR number or commit hash described in its Conventions section.
Use Part 3 during conflict resolution.
Do not run Part 2 from this skill.
