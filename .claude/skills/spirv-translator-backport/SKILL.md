---
name: spirv-translator-backport
description: Backport a single SPIRV-LLVM-Translator commit or PR across a release range you confirm (in-tree checkout only, not standalone — see Setup). Cherry-picks, adapts, builds, and tests locally for each release — does not push or open PRs (see spirv-translator-backport-prs for that). Pass a commit hash or PR number as argument.
allowed-tools: Bash(git *) Bash(cmake *) Bash(ninja *) Bash(gh *) Bash(llvm-lit *) Bash(clang-format *) Bash(clang-format-diff.py *) Bash(sed *) Bash(grep *)
---

# SPIRV-LLVM-Translator backport skill

Backport the given commit/PR (`$ARGUMENTS`) to SPIRV-LLVM-Translator release branches, from the current newest release down to a floor release confirmed with the contributor (see Step 1). This skill prepares and locally verifies each release's backport branch — it does not push anything or open PRs. Run the `spirv-translator-backport-prs` skill afterward to publish.

Start from inside your SPIRV-LLVM-Translator checkout — all commands below run from there, except where a command explicitly targets `$LLVM_ROOT` instead (the surrounding-tree switch and the build commands).

## Setup (once per machine)

This skill doesn't assume a particular directory layout — resolve these once for your own checkout rather than hardcoding paths:

- **Repo root**: `git rev-parse --show-toplevel` from inside the checkout.
- **Fork remote - detect by URL**: don't assume it's named `fork`, your GH username, or anything else — contributors name this differently (this repo has both patterns in the wild):
  ```bash
  LOGIN=$(gh api user --jq .login)
  git remote -v | awk -v login="$LOGIN" \
    '$2 ~ ("github.com[:/]" login "/") && tolower($2) ~ /spirv-llvm-translator/ {print $1}' | sort -u
  ```
  If this returns no remote, the contributor hasn't added their fork yet — stop and ask them to (`git remote add <name> git@github.com:<you>/SPIRV-LLVM-Translator.git`) rather than guessing a name. If it returns more than one, ask which to use. Use the resulting remote name (call it `<FORK_REMOTE>` below) in `spirv-translator-backport-prs`'s push commands — never hardcode one.
- **`gh` CLI**: authenticated (`gh auth status`).
- **`clang-format` / `clang-format-diff.py`**: matching versions, on `$PATH`. `clang-format-diff.py` ships with LLVM's `clang/tools/clang-format/`.
- **Switching the surrounding LLVM tree**: this repo lives nested inside an llvm-project monorepo checkout (`llvm/projects/SPIRV-LLVM-Translator`), and any build of `llvm-spirv` compiles against the LLVM sources checked out in that surrounding tree. There's only one such tree on disk, so **every release requires switching it to the matching LLVM branch before (re)building** — done per-release in Step 2a, not here. Just resolve the path once:
  ```bash
  LLVM_ROOT=$(cd "$(git rev-parse --show-toplevel)/../../.." && pwd)   # llvm/projects/SPIRV-LLVM-Translator -> repo root three levels up
  ```
  The actual switch (`git checkout "release/${N}.x"` in `$LLVM_ROOT`, one release major version — `N` is already the two-digit form used everywhere else in this file, e.g. `23`, not `230`) must touch only the surrounding tree, never this repo's own checkout — this repo's branch state is managed entirely by Step 2a below.
- **Build-output directory**: use a dedicated dir per release, `$LLVM_ROOT/build-${N}` (call it `$BUILD_DIR` below). With the Release, no-assertions config below, building only the tools this skill needs measures **~1GB** per release (verified) — keeping all of them around for every release simultaneously costs only ~10GB total.

### Build dir setup (per release, one-time)

Build directories live under `$LLVM_ROOT` (sibling to `llvm/`, `clang/`, etc.), not inside this translator repo. Every command below is anchored off `$LLVM_ROOT` explicitly so it works regardless of which directory you're actually in when you run it. `clang` must be an enabled project — `.cl` test RUN lines shell out to it, and it's not part of the default LLVM build otherwise.

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
Building just `llvm-spirv` isn't enough to actually run the test suite — RUN lines also invoke `llvm-as`/`llvm-dis` (assemble/disassemble), `llc` (the `DebugInfo/X86` tests round-trip through real x86 codegen), `clang` (`.cl` tests), and `FileCheck` (pattern matching). Build all of them together, every time you rebuild after a switch, not just the one target you happen to be editing.

## Step 0 — Resolve what to cherry-pick

`$ARGUMENTS` is a single commit hash or PR number. Classify by length, not by "hex vs. all-digit" — an all-digit string is valid hex too, so that check alone is ambiguous. In practice PR numbers here run 1–4 digits (currently in the ~3900s) and any real commit-hash input is at least 7 characters (git's minimum abbreviation), so:

- **≤ 6 digits, all-numeric**: a PR number.
  - Run: `gh pr view <N> --repo KhronosGroup/SPIRV-LLVM-Translator --json mergeCommit` to get the merge commit hash.
  - If the PR isn't merged yet, stop and tell the user.
- **Otherwise (≥ 7 characters, or contains a letter)**: a commit hash — use it directly.

Every backport is tracked by PR number, not by commit hash — this repo doesn't merge commits to `main` outside a PR. If you started from a commit hash, resolve its PR number rather than treating the commit as PR-less, since even a commit whose subject doesn't literally contain a `(#NNNN)` suffix (e.g. an auto-generated `Revert "..."` commit) still has an associated PR in GitHub's own metadata:
```bash
gh api repos/KhronosGroup/SPIRV-LLVM-Translator/commits/<commit>/pulls --jq '.[0].number'
```

Fetch origin first:
```bash
git fetch origin
```

Get its title/body (for the eventual commit message):
```bash
git log -1 --format="%s%n%n%b" <commit>
```

## Step 1 — Determine release range

Discover the current newest release live — don't hardcode a number, it changes every time Khronos cuts a release:
```bash
git ls-remote --heads origin 'llvm_release_*0' | grep -oE 'llvm_release_[0-9]+0' | sort -V | tail -1
```

Ask the contributor how far back to backport — there's no way to derive this from the repo; it depends on which release lines actually need the fix. Suggest `14` as the default if they have no preference (the oldest release still commonly backported to at time of writing), but don't assume it.

Backport sequence: the newest discovered release, descending, down to the confirmed floor release — release branches exist for every major version with no gaps (verified: `llvm_release_70` through the current newest, contiguous). If `git ls-remote --heads origin llvm_release_${N}0` for a release in that range comes back empty, that's unexpected — stop and ask the user rather than silently skipping it; don't assume it's fine to just continue to N-1.

## Step 2 — For each release N (descending)

Steps 2d–2f amend the current commit. Per this repo's own CLAUDE.md git-safety rule, never amend blindly — before each amend below, confirm `git branch --show-current` is still `backport/${ID}-to-llvm_release_${N}0` (not detached, not some other branch). Something could have changed it since the last step — parallel work in another tab, or a mistake earlier in this same run. If it doesn't match, stop and alert the user rather than amending whatever HEAD happens to point at.

### 2a — Set up the release branch

The identifier `<ID>` for this backport is `pr-<PR>`, using the PR number resolved in Step 0.

Check first, before touching anything — `git checkout -b` errors outright if the branch already exists, instead of the clean skip this is meant to be:
```bash
git show-ref --verify --quiet refs/heads/backport/${ID}-to-llvm_release_${N}0
```
If that succeeds (branch exists), this release is already prepared — skip the rest of Step 2 for it and move to N-1, unless the contributor asks to redo it (in which case `git branch -D` it first, then continue below). Otherwise:
```bash
git checkout -B llvm_release_${N}0 origin/llvm_release_${N}0
git pull
git checkout -b backport/${ID}-to-llvm_release_${N}0
```
`-B` against the explicit `origin/...` ref avoids ambiguity if another remote (e.g. your fork) also has a branch of the same name.

Then switch the surrounding llvm-project tree to match, per Setup — this is required every release regardless of build-directory layout:
```bash
(cd "$LLVM_ROOT" && git checkout "release/${N}.x" && git pull)
```

Re-derive `$BUILD_DIR` for this release too: `$LLVM_ROOT/build-${N}` — it changes every iteration.

### 2b — Cherry-pick

Always cherry-pick the most recently adapted version — when backporting to N-1, cherry-pick HEAD of the branch just built for N, not the original upstream commit. This carries forward every adaptation already made for the newer release.

```bash
# First (newest) release: cherry-pick the original upstream commit
# Every subsequent (older) release: cherry-pick HEAD of the branch just built for the previous release
git cherry-pick <commit-or-previous-branch-HEAD>
```

**If cherry-pick conflicts:**
- Inspect each conflicted file carefully.
- Resolve conflicts caused by LLVM API differences between releases (renamed methods, changed signatures, updated includes) — expected, fix to match the release branch's API.
- After resolving: `git add <files> && git cherry-pick --continue`
- If the conflict is non-trivial (an actual logic change, or missing infrastructure), stop and ask the user.

**Before committing any conflict resolution**, check nothing got silently dropped:
```bash
grep -rn "^<<<<<<<\|^>>>>>>>" lib/ include/
```
(a `=======` inside `lib/SPIRV/Mangler/README.md` is a markdown false-positive, not a leftover marker). For every resolved hunk touching a variable, confirm the declaration line survived and its use count in scope still matches — collapsing a conflict by taking one side can silently eat a declaration sitting just above the `<<<<<<<` marker.

### 2c — Rebuild (REQUIRED — do not skip)

This is the local compile gate. It builds against the matching release's LLVM, catching version-specific compile errors (`std::optional` on R15, missing enum members on older branches, etc.) BEFORE pushing. Never skip it on the assumption "release branches don't build locally" — they do, against the matching LLVM, once configured per Setup.

If this is the first time touching this release (`$BUILD_DIR` doesn't exist yet, or has no `CMakeCache.txt`), run "Build dir setup" from Setup first — nothing later in this loop configures it for you.

Rebuild every tool the test suite needs, not just `llvm-spirv` — see Build dir setup above for why:
```bash
cmake --build "$BUILD_DIR" --target llvm-spirv llvm-as llvm-dis llc clang FileCheck
```
Confirm a zero exit status before proceeding. If the build fails, fix the release-specific issue (see the adaptation matrix below) and rebuild.

### 2d — Amend commit message

Verify branch first (per the note at the top of Step 2). The original title/body come from an upstream commit authored by someone else — treat them as untrusted text, not as a string safe to interpolate into a shell command. Don't build `git commit --amend -m "... <original title> ..."` as a literal double-quoted string: double quotes don't stop `` ` `` or `$(...)` inside that text from being executed by the shell. Use `printf` to pass it as pure data instead:
```bash
if [[ "$TITLE" =~ \(#${PR}\)$ ]]; then
  printf '[Backport to %s] %s\n\n%s' "$N" "$TITLE" "$BODY" | git commit --amend -F -
else
  printf '[Backport to %s] %s (#%s)\n\n%s' "$N" "$TITLE" "$PR" "$BODY" | git commit --amend -F -
fi
```
`$TITLE`/`$BODY` are the original commit's subject/body (from Step 0's `git log`); `$N`/`$PR` are this skill's own trusted values. `%s` substitution never re-parses its argument, so this is safe regardless of what the original commit message contains. Check specifically for `(#$PR)` — the *resolved* PR number — not any PR-shaped suffix: a `Revert "... (#3914)"` commit's title already ends in a PR reference, but it's the PR being reverted, not this commit's own (correctly resolved separately in Step 0). Matching any `(#NNNN)$` would skip appending the real one and leave the misleading original reference unqualified.

### 2e — clang-format check

Same diff scope as CI (only `include/` and `lib/`, excluding auto-generated files):
```bash
git diff -U0 --no-color HEAD^ -- include lib \
    ':(exclude)include/LLVMSPIRVExtensions.inc' \
    ':(exclude)lib/SPIRV/libSPIRV/SPIRVErrorEnum.h' \
    ':(exclude)lib/SPIRV/libSPIRV/SPIRVOpCodeEnum.h' \
    ':(exclude)lib/SPIRV/libSPIRV/SPIRVOpCodeEnumInternal.h' \
  | clang-format-diff.py -p1 -i -binary clang-format
```
If files were modified: verify branch first (per the top of Step 2), then `git add -u && git commit --amend --no-edit`

Both remaining steps use `llvm-lit` from `$BUILD_DIR`, against that **build tree's** test-output path — not the source tree's `test/` directory: `$BUILD_DIR/bin/llvm-lit` against `$BUILD_DIR/projects/SPIRV-LLVM-Translator/test/...`. `lit.site.cfg.py` (which `llvm-lit` needs to resolve tool paths and test config) only exists in the build tree, so running against the source path fails or silently uses the wrong config.

Don't invoke a bare `llvm-lit` relying on `$PATH` — with multiple release build dirs on disk, that resolves to whichever one happens to be first on `$PATH`, not necessarily release N's.

### 2f — Run targeted tests first

Identify test files related to the backported feature (grep `test/` for relevant keywords from the commit). Run just those before the full suite — faster signal, and failures here are easier to attribute:
```bash
"$BUILD_DIR/bin/llvm-lit" <matching test files or subdirectory, under "$BUILD_DIR"'s test path> -v
```
If targeted tests fail:
- If it's a test referencing an LLVM API that changed between releases, update the test to match the release branch.
- Report how the patch differs from the original commit if you had to modify it to fit the older release.
- If the failure indicates a logic problem in the cherry-pick itself, stop and ask the user.
- Once fixed: verify branch first (per the top of Step 2), then `git add <files> && git commit --amend --no-edit`

### 2g — Run the full test suite

```bash
"$BUILD_DIR/bin/llvm-lit" "$BUILD_DIR/projects/SPIRV-LLVM-Translator/test/" -q --no-progress-bar
```
If new failures appear that aren't pre-existing on the release branch: determine if the cherry-pick caused them, fix if straightforward, otherwise stop and ask.

## Step 3 — Continue to next release

Repeat Step 2 for N-1, N-2, ... down to the floor release confirmed in Step 1.

## Release-specific compatibility notes

When cherry-picking to older releases, the following API and syntax differences apply. Apply these during conflict resolution or as post-cherry-pick fixups.

### Cumulative adaptation matrix

Each row is the **first (newest) release** where the adaptation becomes necessary; it stays necessary for all older releases below it.

The `lib/`+`include/` source of a well-formed backport stays identical across releases **except where the target branch's own API forces a divergence** — e.g. a `case` label pruned because the enumerator doesn't exist yet, or `std::optional` → `llvm::Optional`. Every divergence must be (a) forced by the branch, (b) traceable to a row in this table, and (c) behavior-preserving. None of these are logic changes. If you find yourself changing what the patch *does* on an older branch, stop and ask.

| First needed at | Adaptation | Detail |
|-----------------|-----------|--------|
| **all releases** | Hex float literals | LLVM's IR printer emits a float constant in decimal only if that decimal string round-trips exactly back to the same bit pattern, otherwise falls back to hex — `half`/`bfloat`'s low precision hits the hex fallback far more often than `f32`, so expect `0xH3C00`/`0xR3F80`/`0xH0000`-style literals for those types. This is generic printer logic (`writeAPFloatInternal` in `AsmWriter.cpp`), not release-specific, and it's been unchanged from R14 through current `main` — evidence it's likely to still hold for the next release cut too, though that's not guaranteed for a branch that doesn't exist yet (`AsmWriter.cpp` itself isn't frozen — see the `splat`/`ConstantByte` rows elsewhere in this table). Re-check this function on a new release if literals don't format as expected. Keep `spir_func`. |
| **all releases** | Old spirv-tools | Disable `spirv-val` steps / drop `.spvasm` tests using capabilities the CI runner's `spirv-as` doesn't know (e.g. `Float8EXT`). |
| **all releases** | Build locally before push | The build must compile against the matching LLVM release — catches version-specific compile errors before pushing. Always rebuild after cherry-picking (see 2c and Setup). |
| **R21 and below** | `.bc` RUN steps | `llvm-spirv` won't take `.ll` directly: add `; RUN: llvm-as %s -o %t.bc` and feed `%t.bc`. |
| **R21 and below** | Test dir layout | Intel float4/fp_conversions tests live at `test/extensions/SPV_INTEL_*` (no `INTEL/` prefix); int4 keeps `INTEL/`. Git usually auto-relocates. |
| **R22 and below** | Missing enum ops | Enums like `NonSemanticAuxData::Instruction` shrink on older branches; drop `case` labels for enumerators the branch's header lacks (see "Missing enum ops" below). Cherry-picks CLEANLY — only the build catches it. |
| **R19 and below** | `splat`→expanded | `splat (T V)` vector shorthand is LLVM 20+; expand to `<N x T> <T V, T V, …>` (regex below). |
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

- **R16 caveat**: LLVM 16 *supports* opaque pointers even though typed is the default — `.ll` tests using `ptr` / `ptr addrspace(N)` (incl. `ptr null` args and `ptr` in declarations) assemble and round-trip fine on R16 with the standard `llvm-as %s -o %t.bc` flow. Verified against R16 baseline tests. So opaque-pointer test backports generally need NO pointer conversion at R16.
- Convert `ptr addrspace(N)` to typed pointers when backporting `.ll` tests to **R15 or earlier** (and at R16 only if a specific test fails to assemble — check first, don't assume).
- `llvm.ptr.annotation` intrinsic signature differs: R16− uses `@llvm.ptr.annotation.p1i8(i8 addrspace(1)*, i8*, i8*, i32, i8*)` instead of `@llvm.ptr.annotation.p1.p1(ptr addrspace(1), ptr addrspace(1), ...)`.
- CHECK-LLVM lines must match the typed pointer format.
- Global string constants in annotation calls need `getelementptr inbounds` with typed syntax: `i8* getelementptr inbounds ([N x i8], [N x i8]* @str, i64 0, i64 0)`.
- SPT tests (`.spt` using `spirv-as`) are unaffected by pointer model changes.

### Vector-constant `splat` syntax (R19 and earlier)

The `splat (TYPE VAL)` shorthand is **LLVM 20+** only. R19 and earlier `llvm-dis` emit — and `llvm-as` only parses — the fully-expanded per-element form. Expand every `<N x TYPE> splat (TYPE VAL)` (CHECK-LLVM lines and IR bodies) to `<N x TYPE> <TYPE VAL, TYPE VAL, … (N times)>`.

`VAL` itself can contain parentheses (e.g. `splat (i64 ptrtoint (ptr @g to i64))`) — a single non-nesting regex like `\(([^()]+?)\)` silently fails to match these and leaves them unexpanded with no error, so scan for the matching close paren by depth instead of using a flat character-class regex (verified against exactly this case):

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

Enums grow upstream over time, so a patch that adds `case` labels to a `switch` fails to compile on older branches with `'X' is not a member of 'Y'`. This is a **build error, not a cherry-pick conflict** — git applies the hunk cleanly and only the rebuild step (2c) catches it. This is the concrete reason 2c is non-negotiable.

Example — `NonSemanticAuxData::Instruction` per release (point-in-time example; always re-verify against the actual header before relying on specific enumerator names, since upstream keeps adding to it):

| Release | Enumerators (as last checked) |
|---------|-------------|
| newest releases | `FunctionMetadata`, `FunctionAttribute`, `GlobalVariableMetadata`, `GlobalVariableAttribute`, `Linkage` (+ separate `enum LinkageType`) |
| mid releases | `FunctionMetadata`, `FunctionAttribute`, `GlobalVariableMetadata`, `GlobalVariableAttribute` |
| oldest releases | `FunctionMetadata`, `FunctionAttribute`, `PreserveCount` |

**Fix:** delete only the `case` labels whose enumerator is absent from *that branch's* header. Verify against the header, never from memory:
```bash
sed -n '/namespace NonSemanticAuxData/,/^} \/\/ namespace/p' \
    lib/SPIRV/libSPIRV/NonSemantic.AuxData.h
```

**`PreserveCount` is a sentinel, not an op** — it exists only to size the enum and has no handler anywhere in `lib/`. Never add a `case` for it.

**Safety check before deleting a case.** Deleting a label from a *guard* switch (one whose `default:` returns/breaks early, filtering ops before real work) is safe — the op falls through to `default` and gets skipped, which is the intended behavior. Deleting a label from a *dispatch* switch (one that does real work per op) silently disables a feature — stop and ask instead. The rebuild can't catch a wrong classification either way — removing a `case` never breaks compilation, guard or dispatch — so getting this right is entirely on the read, not on any later check:
- Judge by the specific case body being removed, not the switch's overall shape. A switch can be mostly guard-like with one dispatch-flavored case mixed in; classifying the whole switch at a glance can miss that one case.
- A genuine guard case's body is early-exit control flow only (`return`/`break`/`continue`, maybe with a trivial log) — nothing that produces output, mutates state, or feeds a later computation. If the specific case does anything beyond that, treat it as dispatch, not guard.
- If you're not confident which it is after reading the actual case body, that uncertainty itself means stop and ask — don't default to "probably guard" as the safe assumption.

Confirm which kind you're editing, and that the enumerator is truly absent rather than spelled differently on that branch:
```bash
grep -rn "GlobalVariableAttribute\|Linkage" lib/SPIRV/libSPIRV/NonSemantic.AuxData.h
```

Do NOT resolve this by adding the missing enumerator to the older branch's header — that expands the backport beyond the upstream commit.

This generalizes to any `SPIRVEIS_*`, `Capability*`, `Decoration*`, or `ExtensionID` value added after the target branch forked. When the rebuild reports `is not a member of`, prune to what the branch has.

Worked example (#3744, "Skip unknown nonsemantic instructions and sets"): the patch added a five-op guard switch in `transAuxDataInst`. One mid-range release needed `case NonSemanticAuxData::Linkage:` dropped; older releases additionally needed `GlobalVariableAttribute` and `GlobalVariableMetadata` dropped. Both switches touched were guards, so the prunes were behavior-preserving.

### R14–R15: `addrspacecast` restriction

LLVM 14–15 reject `addrspacecast` from `addrspace(1)` (global) to default address space (0). Only casts to generic (`addrspace(4)`) are valid. Annotation string constants (`@.str.*`) must be declared in default address space directly — do NOT use `addrspace(1)` + `addrspacecast`. Also use `i32 0, i32 0` GEP indices instead of `i64 0, i64 0`.

### `std::optional` vs `llvm::Optional`

| Release | Type |
|---------|------|
| R17+ | `std::optional<T>` |
| R14–R16 | `llvm::Optional<T>` |

Replace `std::optional` → `llvm::Optional` (and `std::nullopt` → `llvm::None`) when backporting to R16 or earlier.

R16 itself supports `std::optional`, so this rename is only strictly required at **R15 and below**. The rebuild (2c) catches an un-converted usage, but it's cheap to also grep the diff first:
```bash
git diff <base> HEAD -- lib include | grep -E '^\+' | grep -E 'std::optional|std::nullopt'
```
Match the surrounding file's existing convention (`llvm::Optional<ExtensionID> getRequiredExtension()`).

### Parameter decoration metadata location

- **R16+**: `spirv.ParameterDecorations` metadata generated in `transOCLMetadata` (SPIRVReader.cpp).
- **R15**: Generated in a separate `transFunctionDecorationsToMetadata` function called from `transMetadata`. Any fix to parameter decoration handling must be applied there instead.

### clang-tidy: stale config + version-specific diagnostics (R14/R15)

R15 and R14 ship an old `.clang-tidy` that predates upstream disabling two noisy checks, and run older clang-tidy that emits diagnostics newer clang doesn't. Three distinct failures can hit these branches on code that's otherwise clean on main / R16+:

1. **`misc-const-correctness`** (added in clang-tidy-15): fires on R15 (clang-tidy-15) but not R14 (clang-tidy-14 lacks the check).
2. **`misc-non-private-member-variables-in-classes`**: exists in clang-tidy-14 and -15, fires on a new public struct member on BOTH R15 and R14.

Both #1 and #2 are disabled on main.

3. **`clang-diagnostic-unused-const-variable`**: clang-tidy-14 and -15 emit `-Wunused-const-variable` for new namespace-scope `constexpr` constants when a TU includes the header but doesn't use them. Newer clang (R16+) doesn't. Not a `.clang-tidy`-disabled check — the CI job fails on ANY non-empty clang-tidy log.

**Fixes:**
- For #1 and #2: the real fix is a separate prerequisite PR backporting main's `.clang-tidy` to the affected release branch, merged before this backport's own PR — but pushing/merging PRs is out of scope for this skill (see Notes: never push or create PRs here). Flag this to the contributor as a manual prerequisite rather than doing it yourself: `git show origin/main:.clang-tidy > .clang-tidy` is the update they need to prepare, push, and merge themselves (or via `spirv-translator-backport-prs`) before this release's backport PR can land clean. Do NOT sprinkle `const` or refactor structs to satisfy the old checks — keep backport code byte-identical to main.
- For #3: add `[[maybe_unused]]` to the macro defining the new constants, e.g. `#define _SPIRV_OP(x, y) [[maybe_unused]] constexpr x x##y = static_cast<x>(I##x##y);`. The standard guarantees this suppresses `-Wunused-const-variable` regardless of TU.

None of this is verifiable locally — this skill's build never runs clang-tidy, so these three failures only ever surface on CI.

## Notes

- Do NOT push or create PRs from this skill — that's `spirv-translator-backport-prs`, run after all releases pass locally.
- Do NOT skip the clang-format step — CI will fail on formatting issues.
- If a release branch is missing infrastructure needed by the patch (e.g. a class introduced after that release), stop and report — do not attempt to re-implement missing infrastructure.
- This skill backports one commit/PR at a time. Backporting several related commits together as a single unit isn't covered here.
- **Never `git add -A` / `git add .`** when amending commits — it can sweep untracked local helper scripts into the commit. Stage explicit paths or `git add -u` (tracked only).
