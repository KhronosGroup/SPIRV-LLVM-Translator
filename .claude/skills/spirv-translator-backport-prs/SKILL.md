---
name: spirv-translator-backport-prs
description: Push previously-prepared SPIRV-LLVM-Translator backport branches and open PRs against KhronosGroup/SPIRV-LLVM-Translator, then monitor CI. Run after spirv-translator-backport has locally built and tested each release. Pass the same commit hash/PR number used to prepare the backports.
allowed-tools: Bash(git *) Bash(gh *) Bash(curl *) Bash(unzip *) Bash(diff *) Bash(grep *)
---

# SPIRV-LLVM-Translator backport-prs skill

Publishes backport branches already prepared by `spirv-translator-backport` for the given commit/PR (`$ARGUMENTS`): pushes each release's branch to your fork, opens a PR against the matching `llvm_release_${N}0`, and monitors CI. This is a separate, deliberate step from preparation — opening PRs against the public Khronos repo is visible to others and hard to reverse, so it shouldn't happen automatically as a side effect of local testing.

Start from inside your SPIRV-LLVM-Translator checkout — every command below runs from there.

## Step 0 — Resolve identifiers

Re-derive the same `<ID>` used by `spirv-translator-backport`: `pr-<PR>`, using the same PR-number resolution as that skill's Step 0 (see that skill's Step 2a).

Re-detect the fork remote the same way (don't hardcode a name — see that skill's Setup section):
```bash
LOGIN=$(gh api user --jq .login)
FORK_REMOTE_MATCHES=$(git remote -v | awk -v login="$LOGIN" \
  '$2 ~ ("github.com[:/]" login "/") && tolower($2) ~ /spirv-llvm-translator/ {print $1}' | sort -u)
```
If this returns no remote, stop and ask the contributor to add one. **If it returns more than one, stop and ask which to use — do not default to the first match.** Set `FORK_REMOTE` to the confirmed name before continuing; every push command below uses `$FORK_REMOTE`.

## Step 1 — Determine release range

Same discovery as `spirv-translator-backport`:
```bash
git ls-remote --heads origin 'llvm_release_*0' | grep -oE 'llvm_release_[0-9]+0' | sort -V | tail -1
```
Descending from the newest discovered release. There's no separate floor to ask for here — this skill only publishes branches `spirv-translator-backport` already prepared, so 2a's own "branch doesn't exist locally" check is what naturally stops the loop at whatever floor was used during preparation.

## Step 2 — For each release N (descending, newest to oldest — do not parallelize)

Publish one release at a time, in the same descending order used to prepare them, and gate each on 2e before moving to the next. All releases were already cherry-picked and locally tested by `spirv-translator-backport` before this skill runs, so this gate can't stop a bad cherry-pick from having already propagated through the local chain — that already happened during preparation. What it protects instead is the public PR queue: if release N's backport needs a fixup after push (CI or human review), publishing sequentially means you fix and re-push N once, rather than also having to rebase every already-open older-release PR that would otherwise carry the same issue.

### 2a — Confirm the branch exists locally

```bash
git show-ref --verify refs/heads/backport/${ID}-to-llvm_release_${N}0
```
If it doesn't exist, stop and ask the user — it may be that the commit already exists on that release branch and no backport was needed, or it may mean a release was skipped by mistake. Don't assume either way.

### 2b — Diff-audit against the previous (newer) release

Audit before doing anything on GitHub — this is a purely local git comparison and doesn't need anything pushed first. Catching a problem here means fixing a local branch, not rebasing a public PR. Compare this release's backport set against the previous (newer) release's, i.e. N against N+1:
```bash
THIS_BP=backport/${ID}-to-llvm_release_${N}0
PREV_BP=backport/${ID}-to-llvm_release_$((N+1))0
THIS_BASE=$(git merge-base "$THIS_BP" "llvm_release_${N}0")
PREV_BASE=$(git merge-base "$PREV_BP" "llvm_release_$((N+1))0")
diff <(git diff "$PREV_BASE" "$PREV_BP" -- lib include | grep -E "^[+-][^+-]") \
     <(git diff "$THIS_BASE" "$THIS_BP" -- lib include | grep -E "^[+-][^+-]")
```
Use `git merge-base`, not `${PREV_BP}^`/`${THIS_BP}^` — the caret form breaks the moment a fixup commit lands (2e can add one), since it only means "the release base" when the branch has exactly one commit.

(Compare added/removed lines only — hunk headers and blob hashes always differ between branches.) Skip this step for the newest release — there's no previous release to compare against.

Expect one of two outcomes for `lib/`+`include/`: byte-identical, or divergent with **every** differing line traceable to a named row in the adaptation matrix (`spirv-translator-backport`'s "Cumulative adaptation matrix") — state which row. Then list any file-path or test-content adaptations. This is the reviewer's audit trail that the backport is mechanically equivalent, not a logic change.

Note a matching diff does NOT by itself prove no adaptation was needed — an adaptation can land entirely in context lines (e.g. if a type was already correct on the older base branch, only body lines get added, and the added-line set can still match the newer release's exactly).

### 2c — Check for an existing PR before doing anything

Re-running this skill must not create duplicate PRs. Before pushing, check whether a PR already exists for this branch:
```bash
gh pr list --repo KhronosGroup/SPIRV-LLVM-Translator \
  --head "${LOGIN}:backport/${ID}-to-llvm_release_${N}0" \
  --state all --json number,state
```
Check `state` in the result:
- **OPEN**: skip to 2e (CI check) instead of re-pushing/re-creating.
- **MERGED**: this release is already published and integrated — nothing to do, skip this release entirely.
- **CLOSED** (and not merged): stop and ask the user before proceeding — don't assume it's safe to re-open or recreate.
- **No result**: proceed to 2d.

### 2d — Push and create PR

```bash
git push -u "$FORK_REMOTE" backport/${ID}-to-llvm_release_${N}0
```
If this is rejected as non-fast-forward, do **not** force-push. That means the local commit was amended since an earlier push (e.g. a fixup applied via `--amend` instead of a new commit) — stop and ask the user how they want to proceed, rather than rewriting the remote branch automatically. If they do want to overwrite it, that's their call to make and run explicitly, not this skill's.

Don't reconstruct the title from the original upstream commit again — the prepared branch's own tip commit already has the correct, de-duplicated `[Backport to $N] ...` subject from `spirv-translator-backport`'s 2d. Reuse it directly:
```bash
PR_TITLE=$(git log -1 --format=%s "backport/${ID}-to-llvm_release_${N}0")
gh pr create \
  --repo KhronosGroup/SPIRV-LLVM-Translator \
  --base llvm_release_${N}0 \
  --head "${LOGIN}:backport/${ID}-to-llvm_release_${N}0" \
  --title "$PR_TITLE" \
  --body "Backport of #<PR>."
```

**PR description is minimal**: exactly `Backport of #NNNN.` (the target branch is already visible in the PR interface — don't repeat "to `llvm_release_XX0`"). No cross-reference to sibling backport PRs, no list of routine adaptations — mention one only if something genuinely non-mechanical was needed. Update the body after creation via `gh api -X PATCH repos/KhronosGroup/SPIRV-LLVM-Translator/pulls/<n> -f body='...'` if you need to.

Report the PR URL to the user.

### 2e — Wait for CI before moving to the next release

Don't move to release N-1 until this release's PR has at least one *substantive* job passing (`Linux (Debug)` or `Linux (Release)`), not just `clang-format`/`license/cla`.

**Phase 1 — Format/tidy checks (~5 min after PR creation):**
```bash
gh pr checks <PR-number> --repo KhronosGroup/SPIRV-LLVM-Translator
```
clang-format and clang-tidy results should be available by now. Fix immediately if any fail (push a fixup commit to the same branch) — these turn around fast.

**Phase 2 — Full CI (~30 min after PR creation):**
```bash
gh pr checks <PR-number> --repo KhronosGroup/SPIRV-LLVM-Translator
```
Record this release's status (PR number, format/tidy result, full-CI result) for the final summary in Step 3.

If there are CI failures:
- On release branches, CI is expected to be fully green. Any failure IS caused by the backport — do not dismiss as pre-existing or infra flake.
- Investigate, fix, push a fixup commit to the same branch. Stage explicit paths or `git add -u` (tracked only) — never `git add -A` / `git add .`, which can sweep untracked local helper scripts into the commit.
- **Propagate the fixup into the older releases before continuing.** `spirv-translator-backport` already locally prepared N-1 down to the floor by cherry-picking N's *pre-fixup* tip — none of them know about this fix yet, and if you don't gate on 2e (i.e. you followed Step 2's sequencing correctly), none of them are published yet either, so this is still a local-only fix, not a rebase of public PRs. For each of those already-prepared branches, in the same descending order: cherry-pick just the fixup commit onto it, rebuild and retest (2c/2f/2g), then continue. If the fixup doesn't cleanly apply to some older release, treat it like any other cherry-pick conflict during preparation — adapt it, don't force the same content blindly.
- After pushing a fix, wait for CI to re-run and check again.
- If full CI is still pending at 30 minutes, check once more at 60. Still pending/stuck at 60 minutes likely means a job is hanging and needs manual retriggering from the GitHub web UI — report to the user.

**Diagnosing CI test failures via job logs**: `"possible intended match here"` is FileCheck's own near-miss diagnostic — useful for any CHECK-line mismatch this skill's adaptation matrix covers (hex vs. decimal float literals, typed-pointer syntax, `splat` expansion, etc.), not just one specific kind. CI's actual output reveals what to align to. Pull the failing job log:
```bash
curl -s -H "Authorization: token $(gh auth token)" \
  "https://api.github.com/repos/KhronosGroup/SPIRV-LLVM-Translator/actions/runs/<RUN_ID>/logs" -L -o /tmp/ci.zip
unzip -o /tmp/ci.zip -d /tmp/ci && grep -rA2 "possible intended match here" /tmp/ci/
```
Don't assume a specific log filename (job numbering/naming can differ between runs) — grep the whole extracted directory rather than one hardcoded file.

## Step 3 — Report final status across all releases

Once every release has been published and passed 2e's gate, report the recorded per-release status as a summary table:

| Release | PR | Format/Tidy | Full CI |
|---------|----|-------------|---------|
| R22 | #NNNN | pass/fail | pass/fail/pending |
| ... | ... | ... | ... |
