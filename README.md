# release-the-things

Two ways to automate firmware releases, side by side in one repo. No Node, no package.json.

| Folder | How a change is described | When it releases | Tool |
| --- | --- | --- | --- |
| `release-please-demo/` | Conventional Commits scoped to the folder: `feat(release-please-demo): …` | Merge the release PR | release-please (GitHub Action) |
| `knope-demo/` | A Markdown change file (`.changeset/*.md`) **and/or** a scoped commit: `fix(knope-demo): …` | Merge the release PR | knope (single Rust binary) |

Each flavour only looks at its own folder, opens its own release PR, writes its own `CHANGELOG.md`, and tags with its own prefix:

- `release-please-demo-vX.Y.Z`
- `knope-demo/vX.Y.Z`

**The one rule:** a Conventional Commit names its folder as scope. knope counts unscoped commits for every package, so scopes keep the demos apart. The lint enforces it.

## Try it

**release-please flavour:** change something in `release-please-demo/`, commit it as `feat(release-please-demo): add parachute`, and merge the PR. A release PR appears; merge it to tag and release. The version in `release-please-demo/include/version.h` updates on the line marked `x-release-please-version`.

**knope flavour:** change something in `knope-demo/` and add a change file, e.g. `knope-demo/.changeset/add_parachute.md`:

```markdown
---
knope-demo: minor
---

# Add parachute

Deploys automatically below 20 m with motors off. Tested in the sim and on the bench.
```

Or skip the file and commit as `fix(knope-demo): battery no longer reads 110%`: knope picks up feat/fix commits scoped to `knope-demo` too, and merges both into one changelog.

Merge the PR. A `chore(knope-demo): release X.Y.Z` PR appears (created by knope's `CreatePullRequest` step); merge it to tag and release. The bump is the biggest of the change files (`major` / `minor` / `patch`) and scoped commits (`fix` / `feat` / `!`), and the version in `knope-demo/include/version.h` is updated by a regex in `knope-demo/knope.toml`. Locally, `knope document-change` (inside `knope-demo/`) writes the change file for you.

## Files

- `release-please-config.json`, `.release-please-manifest.json`: release-please setup, scoped to `release-please-demo/`
- `.github/workflows/release-please.yml`: flavour 1
- `knope-demo/CHANGESETS.md`: how to write a change file (kept outside `.changeset/`, where every `.md` must be a change file)
- `knope-demo/knope.toml`: knope package, versioned file, and the `prepare-release` / `release` workflows
- `.github/workflows/knope-release-pr.yml`: runs `knope prepare-release` (opens/updates the release PR)
- `.github/workflows/knope-release.yml`: runs `knope release` when the release PR is merged

## Lint demo

Two checks run on every PR (`.github/workflows/lint.yml`). Each only looks at its own folder:

| Folder | Rule | Tool |
| --- | --- | --- |
| everywhere | A Conventional Commit must have a scope, and it must match the folder it touches | cocogitto (`cog verify`) + shell |
| `release-please-demo/` | Every commit touching it must be a Conventional Commit. We keep merge commits, so every commit lands on `main`. | cocogitto (`cog verify`), a single Rust binary |
| `knope-demo/` | PR needs a release note: a `.changeset/*.md` file **or** a `feat`/`fix` commit scoped to `knope-demo` (escape hatch: `skip-changelog` label) | plain shell check |

Optional local hook, so a bad message never reaches a PR:

```bash
brew install cocogitto        # or: cargo binstall cocogitto
cog install-hook commit-msg   # installs the hook defined in cog.toml
```

The hook checks commits that touch `release-please-demo/` (format and scope). CI checks the rest.

## Baseline tag for knope

knope reads commits since the last `knope-demo/v*` tag. Before the first knope release, tag the current `main` so older commits aren't counted:

```bash
git tag knope-demo/v0.0.0 origin/main && git push origin knope-demo/v0.0.0
```

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
