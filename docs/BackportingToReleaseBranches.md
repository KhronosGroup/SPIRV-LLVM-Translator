# Backporting to release branches

This document describes how to backport a merged PR from `main` to the `llvm_release_NN0` branches.
It is written so that it can be followed step by step by a person at a terminal or by an AI coding agent; nothing in it depends on a particular agent or tool.

The workflow has two phases, deliberately kept separate:

- **Part 1 — Prepare** cherry-picks, adapts, builds, and tests the change locally for each release.
  It never pushes anything.
- **Part 2 — Publish** pushes the prepared branches to your fork, opens one PR per release, and gates each release on CI before moving to the next.
  Opening PRs against the public repo is visible to others and hard to reverse, so it should be a deliberate second step, not a side effect of local testing.

**Part 3 — Release-specific compatibility notes** lists the known API and syntax differences between releases; both phases refer to it.

## Conventions

- **Input**: a single PR number or commit hash, referred to as `PR` below once resolved (see 1.1).
  One PR is backported at a time; backporting several related PRs together as a single unit isn't covered here.
- **Working directory**: start from inside your SPIRV-LLVM-Translator checkout.
  All commands run from there, except where a command explicitly targets `$LLVM_ROOT` (the surrounding-tree switch and the build commands).
- **"Stop and ask"**: some situations need a human decision.
  If you're an agent, stop and hand control back to the person driving the backport; don't guess.
- **Variables** used throughout:

| Variable | Meaning |
|----------|---------|
| `PR` | PR number being backported (resolved in 1.1) |
| `ID` | `pr-${PR}` — used in backport branch names |
| `N` | Two-digit release major version, e.g. `23` for `llvm_release_230` |
| `LLVM_ROOT` | Root of the surrounding llvm-project checkout (see Setup) |
| `BUILD_DIR` | `$LLVM_ROOT/build-${N}` — per-release build directory |
| `LOGIN` | Your GitHub login (`gh api user --jq .login`) |
| `FORK_REMOTE` | Name of the git remote pointing at your fork (see Setup) |
| `TITLE`, `BODY` | Subject and body of the upstream commit being backported |

## Setup (once per machine)

Resolve these once for your own checkout rather than hardcoding paths:

- **Tools**: `git`, `gh` (authenticated — `gh auth status`), `cmake`, `ninja`, `clang-format`, `clang-format-diff.py` (matching versions, on `$PATH`; `clang-format-diff.py` ships with LLVM's `clang/tools/clang-format/`), plus `grep`, `sed`, `diff`, `curl`, `unzip`, and `python3` (for the `splat` expansion helper in Part 3).
- **Repo root**: `git rev-parse --show-toplevel` from inside the checkout.
- **Fork remote — detect by URL**: don't assume it's named `fork`, your GH username, or anything else — contributors name this differently:
  ```bash
  LOGIN=$(gh api user --jq .login)
  FORK_REMOTE_MATCHES=$(git remote -v | awk -v login="$LOGIN" \
    '$2 ~ ("github.com[:/]" login "/") && tolower($2) ~ /spirv-llvm-translator/ {print $1}' | sort -u)
  ```
  If this returns no remote, the fork hasn't been added yet — stop and ask for it to be added (`git remote add <name> git@github.com:<you>/SPIRV-LLVM-Translator.git`) rather than guessing a name.
  **If it returns more than one, stop and ask which to use — do not default to the first match.**
  Set `FORK_REMOTE` to the confirmed name; Part 2's push commands use it.
- **Surrounding LLVM tree**: this repo lives nested inside an llvm-project monorepo checkout (`llvm/projects/SPIRV-LLVM-Translator`), and any build of `llvm-spirv` compiles against the LLVM sources checked out in that surrounding tree.
  There's only one such tree on disk, so **every release requires switching it to the matching LLVM branch before (re)building** — done per release in 1.3a, not here.
  Just resolve the path once:
  ```bash
  LLVM_ROOT=$(cd "$(git rev-parse --show-toplevel)/../../.." && pwd)   # llvm/projects/SPIRV-LLVM-Translator -> repo root three levels up
  ```
  The switch itself (`git checkout "release/${N}.x"` in `$LLVM_ROOT` — `N` is the two-digit form, e.g. `23`, not `230`) must touch only the surrounding tree, never this repo's own checkout; this repo's branch state is managed entirely by 1.3a.
- **Build-output directory**: use a dedicated dir per release, `$LLVM_ROOT/build-${N}` (`$BUILD_DIR`).
  With the Release, no-assertions config below, building only the tools this workflow needs measures **~1GB** per release — keeping all of them around for every release simultaneously costs only ~10GB total.

### Build directory setup (per release, one-time)

Build directories live under `$LLVM_ROOT` (sibling to `llvm/`, `clang/`, etc.), not inside this translator repo.
Every command below is anchored off `$LLVM_ROOT` explicitly so it works regardless of which directory you're in.
`clang` must be an enabled project — `.cl` test RUN lines shell out to it, and it's not part of the default LLVM build otherwise.

Build with `-DLLVM_TARGETS_TO_BUILD="X86"` on every release.

Always pass `-DLLVM_TOOL_LLVM_SPIRV_BUILD=OFF -DLLVM_TOOL_OPENCL_CLANG_BUILD=OFF` too, on every release — these are no-ops when the legacy `llvm/tools/llvm-spirv` or `llvm/tools/opencl-clang` directories aren't present in your checkout (the option is never even referenced in that case), and prevent a real failure when they are: `add_library cannot create target "LLVMSPIRVLib" because another target with the same name already exists` — some trees have both an old `llvm-spirv` dir and the current `SPIRV-LLVM-Translator` dir under `llvm/projects/`, defining the translator target twice.

```bash
cmake -S "$LLVM_ROOT/llvm" -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DLLVM_TOOL_LLVM_SPIRV_BUILD=OFF -DLLVM_TOOL_OPENCL_CLANG_BUILD=OFF
cmake --build "$BUILD_DIR" --target llvm-spirv llvm-as llvm-dis llc clang FileCheck
```
Building just `llvm-spirv` isn't enough to actually run the test suite — RUN lines also invoke `llvm-as`/`llvm-dis` (assemble/disassemble), `llc` (the `DebugInfo/X86` tests round-trip through real x86 codegen), `clang` (`.cl` tests), and `FileCheck` (pattern matching).
Build all of them together, every time you rebuild after a switch, not just the one target you happen to be editing.

## Part 1 — Prepare (local only)

### 1.1 Resolve what to cherry-pick

The input is a single commit hash or PR number.
Classify by length, not by "hex vs. all-digit" — an all-digit string is valid hex too, so that check alone is ambiguous.
In practice PR numbers here run 1–4 digits and any real commit-hash input is at least 7 characters (git's minimum abbreviation), so:

- **≤ 6 digits, all-numeric**: a PR number.
  - Run `gh pr view <N> --repo KhronosGroup/SPIRV-LLVM-Translator --json mergeCommit` to get the merge commit hash.
  - If the PR isn't merged yet, stop and ask.
- **Otherwise (≥ 7 characters, or contains a letter)**: a commit hash — use it directly.

Every backport is tracked by PR number, not by commit hash — this repo doesn't merge commits to `main` outside a PR.
If you started from a commit hash, resolve its PR number rather than treating the commit as PR-less, since even a commit whose subject doesn't literally contain a `(#NNNN)` suffix (e.g. an auto-generated `Revert "..."` commit) still has an associated PR in GitHub's own metadata:
```bash
gh api repos/KhronosGroup/SPIRV-LLVM-Translator/commits/<commit>/pulls --jq '.[0].number'
```

Fetch origin first:
```bash
git fetch origin
```

Get its title/body (`TITLE`/`BODY`, for the eventual commit message):
```bash
git log -1 --format="%s%n%n%b" <commit>
```

### 1.2 Determine the release range

Discover the current newest release live — don't hardcode a number, it changes every time a release is cut:
```bash
git ls-remote --heads origin 'llvm_release_*0' | grep -oE 'llvm_release_[0-9]+0' | sort -V | tail -1
```

Ask how far back to backport — there's no way to derive this from the repo; it depends on which release lines actually need the fix.
Suggest `14` as the default if there's no preference (the oldest release still commonly backported to at time of writing), but don't assume it.

Backport sequence: the newest discovered release, descending, down to the confirmed floor release — release branches exist for every major version with no gaps.
If `git ls-remote --heads origin llvm_release_${N}0` for a release in that range comes back empty, that's unexpected — stop and ask rather than silently skipping it.

### 1.3 For each release N (descending)

Steps 1.3d–1.3f amend the current commit.
Never amend blindly — before each amend, confirm `git branch --show-current` is still `backport/${ID}-to-llvm_release_${N}0` (not detached, not some other branch).
Something could have changed it since the last step — parallel work in another terminal, or a mistake earlier in this same run.
If it doesn't match, stop and ask rather than amending whatever HEAD happens to point at.

#### 1.3a Set up the release branch

`ID` is `pr-${PR}`, using the PR number resolved in 1.1.

Check first, before touching anything — `git checkout -b` errors outright if the branch already exists, instead of the clean skip this is meant to be:
```bash
git show-ref --verify --quiet refs/heads/backport/${ID}-to-llvm_release_${N}0
```
If that succeeds (branch exists), this release is already prepared — skip the rest of 1.3 for it and move to N-1, unless asked to redo it (in which case `git branch -D` it first, then continue below).
Otherwise:
```bash
git checkout -B llvm_release_${N}0 origin/llvm_release_${N}0
git pull
git checkout -b backport/${ID}-to-llvm_release_${N}0
```
`-B` against the explicit `origin/...` ref avoids ambiguity if another remote (e.g. your fork) also has a branch of the same name.

Then switch the surrounding llvm-project tree to match (see Setup) — required every release:
```bash
(cd "$LLVM_ROOT" && git checkout "release/${N}.x" && git pull)
```

Re-derive `BUILD_DIR` for this release too: `$LLVM_ROOT/build-${N}` — it changes every iteration.

#### 1.3b Cherry-pick

Always cherry-pick the most recently adapted version — when backporting to N-1, cherry-pick HEAD of the branch just built for N, not the original upstream commit.
This carries forward every adaptation already made for the newer release.

```bash
# First (newest) release: cherry-pick the original upstream commit
# Every subsequent (older) release: cherry-pick HEAD of the branch just built for the previous release
git cherry-pick <commit-or-previous-branch-HEAD>
```

**If cherry-pick conflicts:**
- Inspect each conflicted file carefully.
- Resolve conflicts caused by LLVM API differences between releases (renamed methods, changed signatures, updated includes) — expected, fix to match the release branch's API (see Part 3).
- After resolving: `git add <files> && git cherry-pick --continue`
- If the conflict is non-trivial (an actual logic change, or missing infrastructure), stop and ask.

**Before committing any conflict resolution**, check nothing got silently dropped:
```bash
grep -rn "^<<<<<<<\|^>>>>>>>" lib/ include/
```
(a `=======` inside `lib/SPIRV/Mangler/README.md` is a markdown false-positive, not a leftover marker).
For every resolved hunk touching a variable, confirm the declaration line survived and its use count in scope still matches — collapsing a conflict by taking one side can silently eat a declaration sitting just above the `<<<<<<<` marker.

#### 1.3c Rebuild (required — do not skip)

This is the local compile gate.
It builds against the matching release's LLVM, catching version-specific compile errors (`std::optional` on R15, missing enum members on older branches, etc.) before pushing.
Never skip it on the assumption "release branches don't build locally" — they do, against the matching LLVM, once configured per Setup.

If this is the first time touching this release (`$BUILD_DIR` doesn't exist yet, or has no `CMakeCache.txt`), run "Build directory setup" first — nothing later in this loop configures it for you.

Rebuild every tool the test suite needs, not just `llvm-spirv` — see "Build directory setup" for why:
```bash
cmake --build "$BUILD_DIR" --target llvm-spirv llvm-as llvm-dis llc clang FileCheck
```
Confirm a zero exit status before proceeding.
If the build fails, fix the release-specific issue (see Part 3) and rebuild.

#### 1.3d Amend the commit message

Verify the branch first (see the top of 1.3).
`TITLE`/`BODY` come from an upstream commit authored by someone else — treat them as untrusted text, not as a string safe to interpolate into a shell command.
Don't build `git commit --amend -m "... <original title> ..."` as a literal double-quoted string: double quotes don't stop `` ` `` or `$(...)` inside that text from being executed by the shell.
Use `printf` to pass it as pure data instead:
```bash
if [[ "$TITLE" =~ \(#${PR}\)$ ]]; then
  printf '[Backport to %s] %s\n\n%s' "$N" "$TITLE" "$BODY" | git commit --amend -F -
else
  printf '[Backport to %s] %s (#%s)\n\n%s' "$N" "$TITLE" "$PR" "$BODY" | git commit --amend -F -
fi
```
`%s` substitution never re-parses its argument, so this is safe regardless of what the original commit message contains.
Check specifically for `(#$PR)` — the *resolved* PR number — not any PR-shaped suffix: a `Revert "... (#3914)"` commit's title already ends in a PR reference, but it's the PR being reverted, not this commit's own (resolved separately in 1.1).
Matching any `(#NNNN)$` would skip appending the real one and leave the misleading original reference unqualified.

#### 1.3e clang-format check

Same diff scope as CI (only `include/` and `lib/`, excluding auto-generated files):
```bash
git diff -U0 --no-color HEAD^ -- include lib \
    ':(exclude)include/LLVMSPIRVExtensions.inc' \
    ':(exclude)lib/SPIRV/libSPIRV/SPIRVErrorEnum.h' \
    ':(exclude)lib/SPIRV/libSPIRV/SPIRVOpCodeEnum.h' \
    ':(exclude)lib/SPIRV/libSPIRV/SPIRVOpCodeEnumInternal.h' \
  | clang-format-diff.py -p1 -i -binary clang-format
```
If files were modified: verify the branch first (see the top of 1.3), then `git add -u && git commit --amend --no-edit`.

Both remaining steps use `llvm-lit` from `$BUILD_DIR`, against that **build tree's** test-output path — not the source tree's `test/` directory: `$BUILD_DIR/bin/llvm-lit` against `$BUILD_DIR/projects/SPIRV-LLVM-Translator/test/...`.
`lit.site.cfg.py` (which `llvm-lit` needs to resolve tool paths and test config) only exists in the build tree, so running against the source path fails or silently uses the wrong config.

Don't invoke a bare `llvm-lit` relying on `$PATH` — with multiple release build dirs on disk, that resolves to whichever one happens to be first on `$PATH`, not necessarily release N's.

#### 1.3f Run targeted tests first

Identify test files related to the backported feature (grep `test/` for relevant keywords from the commit).
Run just those before the full suite — faster signal, and failures here are easier to attribute:
```bash
"$BUILD_DIR/bin/llvm-lit" <matching test files or subdirectory, under "$BUILD_DIR"'s test path> -v
```
If targeted tests fail:
- If it's a test referencing an LLVM API that changed between releases, update the test to match the release branch.
- Report how the patch differs from the original commit if you had to modify it to fit the older release.
- If the failure indicates a logic problem in the cherry-pick itself, stop and ask.
- Once fixed: verify the branch first (see the top of 1.3), then `git add <files> && git commit --amend --no-edit`.

#### 1.3g Run the full test suite

```bash
"$BUILD_DIR/bin/llvm-lit" "$BUILD_DIR/projects/SPIRV-LLVM-Translator/test/" -q --no-progress-bar
```
If new failures appear that aren't pre-existing on the release branch: determine if the cherry-pick caused them, fix if straightforward, otherwise stop and ask.

### 1.4 Continue to the next release

Repeat 1.3 for N-1, N-2, ... down to the floor release confirmed in 1.2.

## Part 2 — Publish

Run this only after Part 1 has prepared and locally verified every release.

### 2.1 Resolve identifiers

`ID` is `pr-${PR}`, with `PR` resolved the same way as in 1.1.
Detect `FORK_REMOTE` as in Setup — if it matches zero or several remotes, stop and ask.

### 2.2 Determine the release range

Same discovery as 1.2:
```bash
git ls-remote --heads origin 'llvm_release_*0' | grep -oE 'llvm_release_[0-9]+0' | sort -V | tail -1
```
Descend from the newest discovered release.
There's no separate floor to ask for here — this phase only publishes branches Part 1 already prepared, so 2.3a's "branch doesn't exist locally" check is what naturally stops the loop at whatever floor was used during preparation.

### 2.3 For each release N (descending — do not parallelize)

Publish one release at a time, in the same descending order used to prepare them, and gate each on 2.3e before moving to the next.
All releases were already cherry-picked and locally tested in Part 1, so this gate can't stop a bad cherry-pick from having already propagated through the local chain — that already happened during preparation.
What it protects instead is the public PR queue: if release N's backport needs a fixup after push (CI or human review), publishing sequentially means you fix and re-push N once, rather than also having to rebase every already-open older-release PR that would otherwise carry the same issue.

#### 2.3a Confirm the branch exists locally

```bash
git show-ref --verify refs/heads/backport/${ID}-to-llvm_release_${N}0
```
If it doesn't exist, stop and ask — it may be that the commit already exists on that release branch and no backport was needed, or it may mean a release was missed by mistake.
Don't assume either way.

#### 2.3b Diff-audit against the previous (newer) release

Audit before doing anything on GitHub — this is a purely local git comparison and doesn't need anything pushed first.
Catching a problem here means fixing a local branch, not rebasing a public PR.
Compare this release's backport set against the previous (newer) release's, i.e. N against N+1:
```bash
THIS_BP=backport/${ID}-to-llvm_release_${N}0
PREV_BP=backport/${ID}-to-llvm_release_$((N+1))0
THIS_BASE=$(git merge-base "$THIS_BP" "llvm_release_${N}0")
PREV_BASE=$(git merge-base "$PREV_BP" "llvm_release_$((N+1))0")
diff <(git diff "$PREV_BASE" "$PREV_BP" -- lib include | grep -E "^[+-][^+-]") \
     <(git diff "$THIS_BASE" "$THIS_BP" -- lib include | grep -E "^[+-][^+-]")
```
Use `git merge-base`, not `${PREV_BP}^`/`${THIS_BP}^` — the caret form breaks the moment a fixup commit lands (2.3e can add one), since it only means "the release base" when the branch has exactly one commit.

(Compare added/removed lines only — hunk headers and blob hashes always differ between branches.)
Skip this step for the newest release — there's no previous release to compare against.

Expect one of two outcomes for `lib/`+`include/`: byte-identical, or divergent with **every** differing line traceable to a named row in Part 3's "Cumulative adaptation matrix" — state which row.
Then list any file-path or test-content adaptations.
This is the reviewer's audit trail that the backport is mechanically equivalent, not a logic change.

A matching diff does NOT by itself prove no adaptation was needed — an adaptation can land entirely in context lines (e.g. if a type was already correct on the older base branch, only body lines get added, and the added-line set can still match the newer release's exactly).

#### 2.3c Check for an existing PR

Re-running this phase must not create duplicate PRs.
Before pushing, check whether a PR already exists for this branch:
```bash
gh pr list --repo KhronosGroup/SPIRV-LLVM-Translator \
  --head "${LOGIN}:backport/${ID}-to-llvm_release_${N}0" \
  --state all --json number,state
```
Check `state` in the result:
- **OPEN**: skip to 2.3e (CI check) instead of re-pushing/re-creating.
- **MERGED**: this release is already published and integrated — nothing to do, skip this release entirely.
- **CLOSED** (and not merged): stop and ask before proceeding — don't assume it's safe to re-open or recreate.
- **No result**: proceed to 2.3d.

#### 2.3d Push and create the PR

```bash
git push -u "$FORK_REMOTE" backport/${ID}-to-llvm_release_${N}0
```
If this is rejected as non-fast-forward, do **not** force-push.
That means the local commit was amended since an earlier push (e.g. a fixup applied via `--amend` instead of a new commit) — stop and ask rather than rewriting the remote branch automatically.
Overwriting it is a decision for the person driving the backport to make and run explicitly.

Don't reconstruct the title from the original upstream commit again — the prepared branch's own tip commit already has the correct, de-duplicated `[Backport to $N] ...` subject from 1.3d.
Reuse it directly:
```bash
PR_TITLE=$(git log -1 --format=%s "backport/${ID}-to-llvm_release_${N}0")
gh pr create \
  --repo KhronosGroup/SPIRV-LLVM-Translator \
  --base llvm_release_${N}0 \
  --head "${LOGIN}:backport/${ID}-to-llvm_release_${N}0" \
  --title "$PR_TITLE" \
  --body "Backport of #${PR}."
```

**PR description is minimal**: exactly `Backport of #NNNN.` (the target branch is already visible in the PR interface — don't repeat "to `llvm_release_XX0`").
No cross-reference to sibling backport PRs, no list of routine adaptations — mention one only if something genuinely non-mechanical was needed.
Update the body after creation via `gh api -X PATCH repos/KhronosGroup/SPIRV-LLVM-Translator/pulls/<n> -f body='...'` if needed.

Report the PR URL.

#### 2.3e Wait for CI before moving to the next release

Don't move to release N-1 until this release's PR has at least one *substantive* job passing (`Linux (Debug)` or `Linux (Release)`), not just `clang-format`/`license/cla`.

**Phase 1 — Format/tidy checks (~5 min after PR creation):**
```bash
gh pr checks <PR-number> --repo KhronosGroup/SPIRV-LLVM-Translator
```
clang-format and clang-tidy results should be available by now.
Fix immediately if any fail (push a fixup commit to the same branch) — these turn around fast.

**Phase 2 — Full CI (~30 min after PR creation):**
```bash
gh pr checks <PR-number> --repo KhronosGroup/SPIRV-LLVM-Translator
```
Record this release's status (PR number, format/tidy result, full-CI result) for the final summary in 2.4.

If there are CI failures:
- On release branches, CI is expected to be fully green.
  Any failure IS caused by the backport — do not dismiss as pre-existing or infra flake.
- Investigate, fix, push a fixup commit to the same branch.
  Stage explicit paths or `git add -u` (tracked only) — never `git add -A` / `git add .`, which can sweep untracked local helper scripts into the commit.
- **Propagate the fixup into the older releases before continuing.**
  Part 1 already locally prepared N-1 down to the floor by cherry-picking N's *pre-fixup* tip — none of them know about this fix yet, and since publishing is gated one release at a time, none of them are published yet either, so this is still a local-only fix, not a rebase of public PRs.
  For each of those already-prepared branches, in the same descending order: cherry-pick just the fixup commit onto it, then **re-switch `$LLVM_ROOT` and re-derive `BUILD_DIR` for that release first** (repeat the `$LLVM_ROOT` switch and `BUILD_DIR` derivation from 1.3a) before rebuilding and retesting (1.3c, 1.3f, 1.3g).
  By now `$LLVM_ROOT` is sitting wherever Part 1's loop last left it (likely the floor release), not on N-1's branch; skipping the re-switch means rebuilding against the wrong LLVM version silently.
  If the fixup doesn't cleanly apply to some older release, treat it like any other cherry-pick conflict during preparation — adapt it, don't force the same content blindly.
- After pushing a fix, wait for CI to re-run and check again.
- If full CI is still pending at 30 minutes, check once more at 60.
  Still pending/stuck at 60 minutes likely means a job is hanging and needs manual retriggering from the GitHub web UI — report it.

**Diagnosing CI test failures via job logs**: `"possible intended match here"` is FileCheck's own near-miss diagnostic — useful for any CHECK-line mismatch Part 3 covers (hex vs. decimal float literals, typed-pointer syntax, `splat` expansion, etc.), not just one specific kind.
CI's actual output reveals what to align to.
Pull the failing job log:
```bash
curl -s -H "Authorization: token $(gh auth token)" \
  "https://api.github.com/repos/KhronosGroup/SPIRV-LLVM-Translator/actions/runs/<RUN_ID>/logs" -L -o /tmp/ci.zip
unzip -o /tmp/ci.zip -d /tmp/ci && grep -rA2 "possible intended match here" /tmp/ci/
```
Don't assume a specific log filename (job numbering/naming can differ between runs) — grep the whole extracted directory rather than one hardcoded file.

### 2.4 Report final status across all releases

Once every release has been published and passed 2.3e's gate, report the recorded per-release status as a summary table:

| Release | PR | Format/Tidy | Full CI |
|---------|----|-------------|---------|
| R22 | #NNNN | pass/fail | pass/fail/pending |
| ... | ... | ... | ... |

## Part 3 — Release-specific compatibility notes

When cherry-picking to older releases, the following API and syntax differences apply.
Apply these during conflict resolution or as post-cherry-pick fixups.

### Cumulative adaptation matrix

Each row is the **first (newest) release** where the adaptation becomes necessary; it stays necessary for all older releases below it.

The `lib/`+`include/` source of a well-formed backport stays identical across releases **except where the target branch's own API forces a divergence** — e.g. a `case` label pruned because the enumerator doesn't exist yet, or `std::optional` → `llvm::Optional`.
Every divergence must be (a) forced by the branch, (b) traceable to a row in this table, and (c) behavior-preserving.
None of these are logic changes.
If you find yourself changing what the patch *does* on an older branch, stop and ask.

| First needed at | Adaptation | Detail |
|-----------------|-----------|--------|
| **all releases** | Hex float literals | LLVM's IR printer emits a float constant in decimal only if that decimal string round-trips exactly back to the same bit pattern, otherwise falls back to hex — `half`/`bfloat`'s low precision hits the hex fallback far more often than `f32`, so expect `0xH3C00`/`0xR3F80`/`0xH0000`-style literals for those types. This is generic printer logic (`writeAPFloatInternal` in `AsmWriter.cpp`), not release-specific, and it's been unchanged from R14 through current `main` — evidence it's likely to still hold for the next release cut too, though that's not guaranteed for a branch that doesn't exist yet (`AsmWriter.cpp` itself isn't frozen — see the `splat` row in this table). Re-check this function on a new release if literals don't format as expected. Keep `spir_func`. |
| **all releases** | Old spirv-tools | Disable `spirv-val` steps / drop `.spvasm` tests using capabilities the CI runner's `spirv-as` doesn't know (e.g. `Float8EXT`). |
| **all releases** | Build locally before push | The build must compile against the matching LLVM release — catches version-specific compile errors before pushing. Always rebuild after cherry-picking (see 1.3c and Setup). |
| **R21 and below** | `.bc` RUN steps | `llvm-spirv` won't take `.ll` directly: add `; RUN: llvm-as %s -o %t.bc` and feed `%t.bc`. |
| **R21 and below** | Test dir layout | Intel float4/fp_conversions tests live at `test/extensions/SPV_INTEL_*` (no `INTEL/` prefix); int4 keeps `INTEL/`. Git usually auto-relocates. |
| **R22 and below** | Missing enum ops | Enums like `NonSemanticAuxData::Instruction` shrink on older branches; drop `case` labels for enumerators the branch's header lacks (see "Missing enum ops" below). Cherry-picks CLEANLY — only the build catches it. |
| **R19 and below** | `splat`→expanded | `splat (T V)` vector shorthand is LLVM 20+; expand to `<N x T> <T V, T V, …>` (helper below). |
| **R15 and below** | Typed pointers | `ptr addrspace(N)` → typed (`i8 addrspace(N)*`); annotation intrinsic/GEP syntax changes (see Pointer syntax). R16 supports opaque `ptr` — usually no conversion needed there; only R15− forces typed. |
| **R16 and below** | `std::optional` → `llvm::Optional` | API rename. |
| **R15** | Param-decoration location | `spirv.ParameterDecorations` handled in `transFunctionDecorationsToMetadata`, not `transOCLMetadata`. |
| **R14–R15** | `addrspacecast` restriction | No global→addrspace(0) cast; declare `@.str.*` in default AS; `i32 0, i32 0` GEP indices. |

Specifics for each row follow below.

### Pointer syntax (affects `.ll` tests)

| Release | Pointer model | Syntax |
|---------|--------------|--------|
| R17+ | Opaque pointers (default & only) | `ptr addrspace(1)` |
| R15–R16 | Typed pointers (default) | `i8 addrspace(1)*`, `i32 addrspace(4)*` |
| R14 | Typed pointers | Same as R15–R16 |

- **R16 caveat**: LLVM 16 *supports* opaque pointers even though typed is the default — `.ll` tests using `ptr` / `ptr addrspace(N)` (incl. `ptr null` args and `ptr` in declarations) assemble and round-trip fine on R16 with the standard `llvm-as %s -o %t.bc` flow.
  So opaque-pointer test backports generally need NO pointer conversion at R16.
- Convert `ptr addrspace(N)` to typed pointers when backporting `.ll` tests to **R15 or earlier** (and at R16 only if a specific test fails to assemble — check first, don't assume).
- `llvm.ptr.annotation` intrinsic signature differs: R16− uses `@llvm.ptr.annotation.p1i8(i8 addrspace(1)*, i8*, i8*, i32, i8*)` instead of `@llvm.ptr.annotation.p1.p1(ptr addrspace(1), ptr addrspace(1), ...)`.
- CHECK-LLVM lines must match the typed pointer format.
- Global string constants in annotation calls need `getelementptr inbounds` with typed syntax: `i8* getelementptr inbounds ([N x i8], [N x i8]* @str, i64 0, i64 0)`.
- SPT tests (`.spt` using `spirv-as`) are unaffected by pointer model changes.

### Vector-constant `splat` syntax (R19 and earlier)

The `splat (TYPE VAL)` shorthand is **LLVM 20+** only.
R19 and earlier `llvm-dis` emit — and `llvm-as` only parses — the fully-expanded per-element form.
Expand every `<N x TYPE> splat (TYPE VAL)` (CHECK-LLVM lines and IR bodies) to `<N x TYPE> <TYPE VAL, TYPE VAL, … (N times)>`.

`VAL` itself can contain parentheses (e.g. `splat (i64 ptrtoint (ptr @g to i64))`) — a single non-nesting regex like `\(([^()]+?)\)` silently fails to match these and leaves them unexpanded with no error, so scan for the matching close paren by depth instead:

```python
import re
pattern = re.compile(r'<(\d+) x ([^>]+?)> splat \(')
def expand_splats(content):
    out, i = [], 0
    while True:
        m = pattern.search(content, i)
        if not m:
            out.append(content[i:])
            break
        out.append(content[i:m.start()])
        n, vectype = int(m.group(1)), m.group(2)
        depth, j = 1, m.end()
        start_elem = j
        while depth > 0:
            if content[j] == '(':
                depth += 1
            elif content[j] == ')':
                depth -= 1
            j += 1
        elem = content[start_elem:j-1].strip()
        out.append(f'<{n} x {vectype}> <' + ', '.join([elem] * n) + '>')
        i = j
    return ''.join(out)
new = expand_splats(content)
```

Cherry-picking R20+ tests to R19 conflicts on these lines (R19 baseline already used expanded form): take the incoming side (keeps the patch's `spir_func`/hex changes), then run the expansion.

### Missing enum ops in older branches (`NonSemanticAuxData` and friends)

Enums grow upstream over time, so a patch that adds `case` labels to a `switch` fails to compile on older branches with `'X' is not a member of 'Y'`.
This is a **build error, not a cherry-pick conflict** — git applies the hunk cleanly and only the rebuild (1.3c) catches it.
This is the concrete reason 1.3c is non-negotiable.

Example — `NonSemanticAuxData::Instruction` per release (point-in-time example; always re-verify against the actual header before relying on specific enumerator names, since upstream keeps adding to it):

| Release | Enumerators (as last checked) |
|---------|-------------|
| newest releases | `FunctionMetadata`, `FunctionAttribute`, `GlobalVariableMetadata`, `GlobalVariableAttribute`, `Linkage` (+ separate `enum LinkageType`) |
| mid releases | `FunctionMetadata`, `FunctionAttribute`, `GlobalVariableMetadata`, `GlobalVariableAttribute` |
| oldest releases | `FunctionMetadata`, `FunctionAttribute`, `PreserveCount` |

**Fix:** delete only the `case` labels whose enumerator is absent from *that branch's* header.
Verify against the header, never from memory:
```bash
sed -n '/namespace NonSemanticAuxData/,/^} \/\/ namespace/p' \
    lib/SPIRV/libSPIRV/NonSemantic.AuxData.h
```

**`PreserveCount` is a sentinel, not an op** — it exists only to size the enum and has no handler anywhere in `lib/`.
Never add a `case` for it.

**Safety check before deleting a case.**
Deleting a label from a *guard* switch (one whose `default:` returns/breaks early, filtering ops before real work) is safe — the op falls through to `default` and gets skipped, which is the intended behavior.
Deleting a label from a *dispatch* switch (one that does real work per op) silently disables a feature — stop and ask instead.
The rebuild can't catch a wrong classification either way — removing a `case` never breaks compilation, guard or dispatch — so getting this right is entirely on the read, not on any later check:
- Judge by the specific case body being removed, not the switch's overall shape.
  A switch can be mostly guard-like with one dispatch-flavored case mixed in; classifying the whole switch at a glance can miss that one case.
- A genuine guard case's body is early-exit control flow only (`return`/`break`/`continue`, maybe with a trivial log) — nothing that produces output, mutates state, or feeds a later computation.
  If the specific case does anything beyond that, treat it as dispatch, not guard.
- If you're not confident which it is after reading the actual case body, that uncertainty itself means stop and ask — don't default to "probably guard" as the safe assumption.

Confirm which kind you're editing, and that the enumerator is truly absent rather than spelled differently on that branch:
```bash
grep -rn "GlobalVariableAttribute\|Linkage" lib/SPIRV/libSPIRV/NonSemantic.AuxData.h
```

Do NOT resolve this by adding the missing enumerator to the older branch's header — that expands the backport beyond the upstream commit.

This generalizes to any `SPIRVEIS_*`, `Capability*`, `Decoration*`, or `ExtensionID` value added after the target branch forked.
When the rebuild reports `is not a member of`, prune to what the branch has.

Worked example (#3744, "Skip unknown nonsemantic instructions and sets"): the patch added a five-op guard switch in `transAuxDataInst`.
One mid-range release needed `case NonSemanticAuxData::Linkage:` dropped; older releases additionally needed `GlobalVariableAttribute` and `GlobalVariableMetadata` dropped.
Both switches touched were guards, so the prunes were behavior-preserving.

### R14–R15: `addrspacecast` restriction

LLVM 14–15 reject `addrspacecast` from `addrspace(1)` (global) to default address space (0).
Only casts to generic (`addrspace(4)`) are valid.
Annotation string constants (`@.str.*`) must be declared in default address space directly — do NOT use `addrspace(1)` + `addrspacecast`.
Also use `i32 0, i32 0` GEP indices instead of `i64 0, i64 0`.

### `std::optional` vs `llvm::Optional`

| Release | Type |
|---------|------|
| R17+ | `std::optional<T>` |
| R14–R16 | `llvm::Optional<T>` |

Replace `std::optional` → `llvm::Optional` (and `std::nullopt` → `llvm::None`) when backporting to R16 or earlier.

R16 itself supports `std::optional`, so this rename is only strictly required at **R15 and below**.
The rebuild (1.3c) catches an un-converted usage, but it's cheap to also grep the diff first:
```bash
git diff <base> HEAD -- lib include | grep -E '^\+' | grep -E 'std::optional|std::nullopt'
```
Match the surrounding file's existing convention (`llvm::Optional<ExtensionID> getRequiredExtension()`).

### Parameter decoration metadata location

- **R16+**: `spirv.ParameterDecorations` metadata generated in `transOCLMetadata` (SPIRVReader.cpp).
- **R15**: Generated in a separate `transFunctionDecorationsToMetadata` function called from `transMetadata`.
  Any fix to parameter decoration handling must be applied there instead.

### clang-tidy: stale config + version-specific diagnostics (R14/R15)

R15 and R14 ship an old `.clang-tidy` that predates upstream disabling two noisy checks, and run older clang-tidy that emits diagnostics newer clang doesn't.
Three distinct failures can hit these branches on code that's otherwise clean on main / R16+:

1. **`misc-const-correctness`** (added in clang-tidy-15): fires on R15 (clang-tidy-15) but not R14 (clang-tidy-14 lacks the check).
2. **`misc-non-private-member-variables-in-classes`**: exists in clang-tidy-14 and -15, fires on a new public struct member on BOTH R15 and R14.

Both #1 and #2 are disabled on main.

3. **`clang-diagnostic-unused-const-variable`**: clang-tidy-14 and -15 emit `-Wunused-const-variable` for new namespace-scope `constexpr` constants when a TU includes the header but doesn't use them.
   Newer clang (R16+) doesn't.
   Not a `.clang-tidy`-disabled check — the CI job fails on ANY non-empty clang-tidy log.

**Fixes:**
- For #1 and #2: the real fix is a separate prerequisite PR backporting main's `.clang-tidy` to the affected release branch, merged before this backport's own PR.
  That's outside Part 1 (which never pushes) — flag it as a manual prerequisite: `git show origin/main:.clang-tidy > .clang-tidy` is the update that needs to be prepared, pushed, and merged before this release's backport PR can land clean.
  Do NOT sprinkle `const` or refactor structs to satisfy the old checks — keep backport code byte-identical to main.
- For #3: add `[[maybe_unused]]` to the macro defining the new constants, e.g. `#define _SPIRV_OP(x, y) [[maybe_unused]] constexpr x x##y = static_cast<x>(I##x##y);`.
  The standard guarantees this suppresses `-Wunused-const-variable` regardless of TU.

None of this is verifiable locally — the local build never runs clang-tidy, so these three failures only ever surface on CI.

## Rules that apply throughout

- Part 1 never pushes or creates PRs — that's Part 2, run after all releases pass locally.
- Don't skip the clang-format step — CI will fail on formatting issues.
- If a release branch is missing infrastructure needed by the patch (e.g. a class introduced after that release), stop and report — do not attempt to re-implement missing infrastructure.
- **Never `git add -A` / `git add .`** when amending or adding fixup commits — it can sweep untracked local helper scripts into the commit.
  Stage explicit paths or `git add -u` (tracked only).
