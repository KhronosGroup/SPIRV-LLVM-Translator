---
name: spirv-translator-backport-prs
description: Push previously-prepared SPIRV-LLVM-Translator backport branches and open PRs against KhronosGroup/SPIRV-LLVM-Translator, then monitor CI. Run after spirv-translator-backport has locally built and tested each release. Pass the same commit hash/PR number used to prepare the backports.
allowed-tools: Bash(git *) Bash(gh *) Bash(curl *) Bash(unzip *) Bash(diff *) Bash(grep *) Bash(cmake *) Bash(ninja *) Bash(llvm-lit *)
---

Read `docs/BackportingToReleaseBranches.md` (from the repository root) in full, then follow **Part 2 — Publish** for `$ARGUMENTS`, which is the PR number or commit hash described in its Conventions section.
Part 2's CI-fixup propagation step re-runs Part 1's rebuild and test steps on older releases, and its diff audit refers to Part 3.
