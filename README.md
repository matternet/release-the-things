# release-the-things

Two ways to automate firmware releases, side by side in one repo. No Node, no package.json.

| Folder | How a change is described | When it releases | Tool |
| --- | --- | --- | --- |
| `release-please-demo/` | Conventional Commit messages (`feat:`, `fix:`, `feat!:`) | Merge the release PR | release-please (GitHub Action) |
| `knope-demo/` | A Markdown change file per change (`.changeset/*.md`) | Merge the release PR | knope (single Rust binary) |

Each flavour only looks at its own folder, opens its own release PR, writes its own `CHANGELOG.md`, and tags with its own prefix:

- `release-please-demo-vX.Y.Z`
- `knope-demo/vX.Y.Z`

## Try it

**release-please flavour:** change something in `release-please-demo/`, commit it as `feat: add parachute`, and merge the PR. A release PR appears; merge it to tag and release. The version in `release-please-demo/include/version.h` updates on the line marked `x-release-please-version`.

**knope flavour:** change something in `knope-demo/` and add a change file, e.g. `knope-demo/.changeset/add_parachute.md`:

```markdown
---
knope-demo: minor
---

# Add parachute

Deploys automatically below 20 m with motors off. Tested in the sim and on the bench.
```

Merge the PR. A `release(knope-demo): X.Y.Z` PR appears (created by knope's `CreatePullRequest` step); merge it to tag and release. The bump comes from the change files (`major` / `minor` / `patch`), and the version in `knope-demo/include/version.h` is updated by a regex in `knope-demo/knope.toml`. Locally, `knope document-change` (inside `knope-demo/`) writes the change file for you.

## Files

- `release-please-config.json`, `.release-please-manifest.json`: release-please setup, scoped to `release-please-demo/`
- `.github/workflows/release-please.yml`: flavour 1
- `knope-demo/knope.toml`: knope package, versioned file, and the `prepare-release` / `release` workflows
- `.github/workflows/knope-release-pr.yml`: runs `knope prepare-release` (opens/updates the release PR)
- `.github/workflows/knope-release.yml`: runs `knope release` when the release PR is merged

## Lint demo

Two checks run on every PR (`.github/workflows/lint.yml`). Each only looks at its own folder:

| Folder | Rule | Tool |
| --- | --- | --- |
| `release-please-demo/` | Every commit touching it must be a Conventional Commit. We keep merge commits, so every commit lands on `main`. | cocogitto (`cog verify`), a single Rust binary |
| `knope-demo/` | PR must add a Markdown change file in `.changeset/` (or carry the `skip-changelog` label) | plain shell check |

Optional local hook, so a bad message never reaches a PR:

```bash
brew install cocogitto        # or: cargo binstall cocogitto
cog install-hook commit-msg   # installs the hook defined in cog.toml
```

The hook only checks commits that touch `release-please-demo/`.

## One-time setup

- A GitHub App ("release-bot") with Contents and Pull requests write access, installed on the repo, with:
  - repo variable `RELEASE_BOT_APP_ID`
  - repo secret `RELEASE_BOT_PRIVATE_KEY`

  Why: PRs and tags created with the default `GITHUB_TOKEN` don't trigger other workflows, so CI wouldn't run on the release PRs.
- If branch or tag protection is on, allow the app to push release branches and create tags.

## Caveats

- A single PR that touches both folders feeds both flavours. Fine for a demo.
- Both flavours are ready-made tools; we only own small trigger workflows. Still: treat them like product code, owned by the team, not one person. Otherwise we've automated our way to a new Bob.
- Starting point, not battle-tested: check action and tool versions against current docs, and try it on this repo before copying it to a real one.
