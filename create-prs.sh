#!/usr/bin/env bash
set -euo pipefail
git switch main && git pull

# open_pr <branch> <PR title> <file> <file content> [changie kind] [changie body]
open_pr() {
  local branch=$1 title=$2 file=$3 content=$4 kind=${5:-} body=${6:-}
  git switch -c "$branch" main
  mkdir -p "$(dirname "$file")"
  echo "$content" > "$file"
  if [[ -n $kind ]]; then
    cat > "changie-demo/.changes/unreleased/${kind}-${branch##*/}.yaml" <<EOF
kind: $kind
body: $body
time: $(date +%Y-%m-%dT%H:%M:%S%z | sed 's/\(..\)$/:\1/')
EOF
  fi
  git add -A && git commit -qm "$title"
  git push -qu origin "$branch"
  gh pr create --base main --head "$branch" --title "$title" \
    --body "Demo PR for the release talk. Don't merge until the demo."
  git switch -q main
}

# release-please flavour: the PR title decides the bump
open_pr demo/rp-fix      "fix: battery no longer reads 110%" \
  release-please-demo/battery.txt   "max: 100%"
open_pr demo/rp-feat     "feat: add return-to-home button" \
  release-please-demo/rth.txt       "return-to-home: enabled"
open_pr demo/rp-breaking "feat!: remove v1 flight API" \
  release-please-demo/flight-api.txt "v1: removed"

# changie flavour: the change file's kind decides the bump
open_pr demo/changie-fix      "Fix battery percentage overflow" \
  changie-demo/battery.txt   "max: 100%"            Fixed    "Battery no longer reads 110%"
open_pr demo/changie-feat     "Add return-to-home button" \
  changie-demo/rth.txt       "return-to-home: enabled" Added  "Add return-to-home button"
open_pr demo/changie-breaking "Remove v1 flight API" \
  changie-demo/flight-api.txt "v1: removed"          Breaking "Remove v1 flight API"

gh pr list