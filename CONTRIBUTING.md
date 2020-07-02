# Contribution guidelines

## If you found a bug or would like to see a new feature

Please reach us by creating a [new issue].

Bug report should include proper description and steps to reproduce:
- attach LLVM BC or SPV file you are trying to translate and command you launch
- any backtrace in case of crashes would be helpful
- please describe what goes wrong or in unexpected way during translation

For feature requests, please describe the feature you would like to see
implemented in the translator.

[new issue]: https://github.com/KhronosGroup/SPIRV-LLVM-Translator/issues/new

## If you would like to contribute your change

Please open a [pull request]. If you are not sure whether your changes are
correct, you can either mark it as [draft] or create an issue to discuss the
problem and possible ways to fix it prior publishing a PR.

It is okay to have several commits in the PR, but each of them should be
build-able and tests should pass: repo maintainers can squash several commits
into a single one for you during merge, but if you would like to see several
commits in the git history, please let us know in PR description/comments so
maintainers will rebase your PR instead of squashing it.

Each functional change (new feature or bug fix) must be supplied with
corresponding tests. See [#testing-guidelines] for more information about
testing. NFC (non-functional change) PRs can be accepted without new tests.

Code changes should follow coding standards, which are inherited from [LLVM
Coding Standards] - compliance of your code is checked automatically using
Travis CI. See [clang-format] and [clang-tidy] configs for more details about
coding standards.

In order to get your PR merged, the following conditions must be met:
- If you are first-time contributor, you have to sign
  [Contributor License Agreement]. Corresponding link and instructions will be
  automatically posted into your PR.
- [Travis CI testing] jobs must pass on your PR: this includes functional
  testing and checking for complying with coding standards.
- You need to get approval from at least one contributor with merge rights

As a contributor, you should expect that even approved PR might still be left
unmerged for a few days: this is needed, because the translator is being
developed by different vendors and individuals and we need to ensure that each
interested party were able to react to new changes and provide feedback.

Information below is a guideline for repo maintainers and can be used by
contributors to get some expectations about how long PR has to be opened before
it can be merged:
- For any significant change/redesign, the PR must be opened for at least 5
  working days, so everyone interested can step in to provide feedback, discuss
  direction and help to find bugs
  - Ideally, there should be more several approvals from different
    vendors/individuals to get it merged
- For regular changes/bug fixes, the PR must be opened for at least 2-3 working
  days, so everyone interested can step in for review and providing feedback
  - If change is vendor-specific (bug fix in vendor extension implementation or
    new vendor-specific extension support), then it is okay to merge PR sooner
  - If change affects or might affect several interesting parties, the PR must
    be left opened for 2-3 working days and it would be good to see feedback
    from different vendors/inviduals before merging
- Tiny NFC changes or trivial build fixes (due to LLVM API changes) can be
  submitted as soon as testing is finished and PR approved - no need to wait for
  too long
- In general, just use common sense to wait long enough to get feedback from
  everyone who might be interested in the PR and don't hesitate to explicitly
  mention ones who might be interested in reviewing the PR

[pull request]: https://github.com/KhronosGroup/SPIRV-LLVM-Translator/pulls
[draft]: https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests#draft-pull-requests
[LLVM Coding Standards]: https://llvm.org/docs/CodingStandards.html
[clang-format]: [.clang-format]
[clang-tidy]: [.clang-tidy]
[Contributor License Agreement]: https://cla-assistant.io/KhronosGroup/SPIRV-LLVM-Translator
[Travis CI testing]: https://travis-ci.org/KhronosGroup/SPIRV-LLVM-Translator
