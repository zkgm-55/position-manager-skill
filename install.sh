#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME=position-manager-skill
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SOURCE_DIR=${SCRIPT_DIR}/skill

TARGET_ROOT=${1:-.}
TARGET_DIR=${TARGET_ROOT}/.claude/skills/${SKILL_NAME}

if [ ! -d "${SOURCE_DIR}" ]; then
  echo Error: source skill directory not found at ${SOURCE_DIR}
  exit 1
fi

mkdir -p "${TARGET_DIR}"
cp -r "${SOURCE_DIR}/." "${TARGET_DIR}/"

echo Installed ${SKILL_NAME} to ${TARGET_DIR}
echo
echo Files installed:
find "${TARGET_DIR}" -type f -name "*.md" | sed 's/^/  - /'
echo
echo Done. The skill will trigger automatically when your agent context matches the description in SKILL.md.
echo
echo Optional: copy agents and commands into your project .claude directory too:
echo "  cp -r ${SCRIPT_DIR}/agents/* ${TARGET_ROOT}/.claude/agents/"
echo "  cp -r ${SCRIPT_DIR}/commands/* ${TARGET_ROOT}/.claude/commands/"
