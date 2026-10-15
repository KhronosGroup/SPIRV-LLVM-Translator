# Instructions for AI coding agents

This file points agents at task-specific procedures in this repository.
The procedures themselves are ordinary documentation, usable by people as well.

## Backporting a PR to `llvm_release_NN0` branches

Follow [`docs/BackportingToReleaseBranches.md`](docs/BackportingToReleaseBranches.md).
Read the whole document before starting — Part 3's release compatibility notes are needed while resolving conflicts in Part 1.

- **Part 1 — Prepare**: cherry-pick, adapt, build, and test locally for each release.
  Never pushes anything.
- **Part 2 — Publish**: push the prepared branches and open one PR per release, gated on CI.
  Run it only when explicitly asked to publish.
