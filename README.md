# release-the-things

Two ways to automate firmware releases, side by side in one repo. No Node, no package.json.

| Folder | How a change is described | When it releases | Tool |
| --- | --- | --- | --- |
| `release-please-demo/` | Conventional Commit message (`feat:`, `fix:`, `feat!:`) | Merge the release PR | release-please (GitHub Action) |
| `changie-demo/` | A small change file per PR (`changie new`) | Merge the release PR | changie (single Go binary) + 2 workflows |

Each flavour only looks at its own folder, opens its own release PR, writes its own `CHANGELOG.md`, and tags with its own prefix:

- `release-please-demo-vX.Y.Z`
- `changie-demo-vX.Y.Z`

## Try it

**release-please flavour:** change something in `release-please-demo/` commit it as `feat: add parachute`, and merge the PR. A release PR appears; merge it to tag and release. The version in `release-please-demo/include/version.h` updates on the line marked `x-release-please-version`.

**changie flavour:** in `changie-demo/`, run `changie new` (pick *Added*, type "Add parachute") and merge the PR. A `release(changie-demo): vX.Y.Z` PR appears; merge it to tag and release. The bump is picked from the change kinds in `changie-demo/.changie.yaml`.

## Files

- `release-please-config.json`, `.release-please-manifest.json`: release-please setup, scoped to `release-please-demo/`
- `.github/workflows/release-please.yml`: flavour 1
- `.github/workflows/changie-release-pr.yml`: flavour 2, keeps the release PR current
- `.github/workflows/changie-release-tag.yml`: flavour 2, tags and publishes on merge
- `changie-demo/.changie.yaml`: change kinds (Breaking → major, Added/Changed → minor, Fixed/Safety → patch)

## One-time setup

- Create a small GitHub App ("release-bot") with Contents and Pull requests write access, install it on the repo, and add:
  - repo variable `RELEASE_BOT_APP_ID`
  - repo secret `RELEASE_BOT_PRIVATE_KEY`

  Why: PRs and tags created with the default `GITHUB_TOKEN` don't trigger other workflows, so CI wouldn't run on the release PRs.
- If branch or tag protection is on, allow the app to push release branches and create tags.
- Use squash merges.

## Caveats

- A single PR that touches both folders feeds both flavours. Fine for a demo.
- release-please is ready-made. The changie flavour is ~2 workflows we own: treat them like product code, reviewed and owned by the team, not one person. Otherwise we've automated our way to a new Bob.
- Starting point, not battle-tested: check action versions (`@v1`, `@v4`, `@v5`, `@v6`) against current docs, and try it on this repo before copying it to a real one.

## Lint demo

Two checks run on every PR (`.github/workflows/lint.yml`). Each only looks at its own folder:

| Folder | Rule | Tool |
| --- | --- | --- |
| `release-please-demo/` | Every commit touching it must be a Conventional Commit (`feat:`, `fix:`, `feat!:`). We keep merge commits, so every commit lands on `main`. | cocogitto (`cog verify`), a single Rust binary |
| `changie-demo/` | PR must add a file in `.changes/unreleased/` (or carry the `skip-changelog` label) | plain shell check |

Optional local hook, so a bad message never reaches a PR:

```bash
brew install cocogitto        # or: cargo binstall cocogitto
cog install-hook commit-msg   # installs the hook defined in cog.toml
```

The hook only checks commits that touch `release-please-demo/`.
