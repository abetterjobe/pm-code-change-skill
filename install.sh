#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/abetterjobe/pm-code-change-skill.git"
skill_dir="${HOME}/.claude/skills/pm-code-change"
commands_dir="${HOME}/.claude/commands"

if [ -d "${skill_dir}/.git" ]; then
  echo "Updating ${skill_dir}"
  git -C "${skill_dir}" pull --ff-only
elif [ -e "${skill_dir}" ]; then
  echo "${skill_dir} exists but isn't a git checkout. Move it aside, then run this again." >&2
  exit 1
else
  echo "Installing to ${skill_dir}"
  mkdir -p "$(dirname "${skill_dir}")"
  git clone --quiet "${repo_url}" "${skill_dir}"
fi

mkdir -p "${commands_dir}"
for command in "${skill_dir}"/commands/*.md; do
  name="$(basename "${command}")"
  target="${commands_dir}/${name}"
  if [ ! -e "${target}" ] && [ ! -L "${target}" ]; then
    ln -s "${command}" "${target}"
    echo "Linked /${name%.md}"
  elif [ "$(readlink "${target}" || true)" != "${command}" ]; then
    echo "Skipped /${name%.md}: ${target} already exists and doesn't point at this skill." >&2
  fi
done

missing=()
command -v gh >/dev/null 2>&1 || missing+=("GitHub CLI (gh): https://cli.github.com, then run: gh auth login")
command -v the-book >/dev/null 2>&1 || missing+=("The Book CLI (the-book): used to look up Betterment's engineering standards")
if command -v claude >/dev/null 2>&1; then
  claude plugin list 2>/dev/null | grep --quiet "bookworm@" || missing+=("bookworm plugin: run  claude plugin install bookworm@betterment-tools")
else
  missing+=("Claude Code CLI (claude): https://claude.com/claude-code")
fi

echo
if [ "${#missing[@]}" -eq 0 ]; then
  echo "Done. Start a new Claude Code session to load the skill."
else
  echo "Installed. The skill also needs:"
  for item in "${missing[@]}"; do
    echo "  - ${item}"
  done
fi
