#!/usr/bin/env bash
#
# rename_app.sh
#
# Renames a cloned rails_starter project to a new app name.
# Run this from inside the cloned project's root directory.
#
# Usage:
#   ./rename_app.sh new_app_name
#
# Example:
#   ./rename_app.sh shopify_clone
#
set -euo pipefail

OLD_NAME="rails_starter"

# --- 1. Validate input ---
if [ $# -ne 1 ]; then
  echo "Usage: $0 <new_app_name>"
  echo "Example: $0 my_new_app"
  exit 1
fi

RAW_INPUT="$1"

# Normalize to snake_case (lowercase, spaces/dashes -> underscores)
NEW_NAME_SNAKE=$(echo "$RAW_INPUT" | tr '[:upper:]' '[:lower:]' | tr ' -' '_' | tr -cd 'a-z0-9_')

if [ -z "$NEW_NAME_SNAKE" ]; then
  echo "Error: could not derive a valid app name from '$RAW_INPUT'"
  exit 1
fi

# Derive CamelCase version (rails_starter -> RailsStarter, my_new_app -> MyNewApp)
NEW_NAME_CAMEL=$(echo "$NEW_NAME_SNAKE" | awk -F'_' '{for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1)) substr($i,2)}')

OLD_NAME_CAMEL=$(echo "$OLD_NAME" | awk -F'_' '{for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1)) substr($i,2)}')

echo "=========================================="
echo " Renaming project"
echo "   snake_case: $OLD_NAME  ->  $NEW_NAME_SNAKE"
echo "   CamelCase:  $OLD_NAME_CAMEL  ->  $NEW_NAME_CAMEL"
echo "=========================================="
echo

# --- 2. Sanity check: are we in the right place? ---
if [ ! -f "config/application.rb" ]; then
  echo "Error: config/application.rb not found."
  echo "Run this script from the root of the Rails app."
  exit 1
fi

# --- 3. Confirm before making changes ---
read -r -p "Proceed with renaming in $(pwd)? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# --- 4. Find candidate files (text files only, skip binary/vendored dirs) ---
EXCLUDE_DIRS=(.git node_modules tmp log storage public/assets vendor/javascript coverage)

EXCLUDE_ARGS=()
for dir in "${EXCLUDE_DIRS[@]}"; do
  EXCLUDE_ARGS+=(--exclude-dir="$dir")
done

echo "Scanning for references to '$OLD_NAME' / '$OLD_NAME_CAMEL'..."
MATCHING_FILES=$(grep -rlI "${EXCLUDE_ARGS[@]}" -e "$OLD_NAME" -e "$OLD_NAME_CAMEL" . 2>/dev/null || true)

if [ -z "$MATCHING_FILES" ]; then
  echo "No matches found. Nothing to rename in file contents."
else
  echo "Files to update:"
  echo "$MATCHING_FILES" | sed 's/^/  - /'
  echo
fi

# --- 5. Perform replacements (snake_case first, then CamelCase) ---
if [ -n "$MATCHING_FILES" ]; then
  # Detect sed flavor (BSD/macOS vs GNU/Linux) for the -i flag
  if sed --version >/dev/null 2>&1; then
    SED_INPLACE=(-i)
  else
    SED_INPLACE=(-i '')
  fi

  echo "$MATCHING_FILES" | while IFS= read -r file; do
    sed "${SED_INPLACE[@]}" \
      -e "s/${OLD_NAME_CAMEL}/${NEW_NAME_CAMEL}/g" \
      -e "s/${OLD_NAME}/${NEW_NAME_SNAKE}/g" \
      "$file"
  done
  echo "File contents updated."
fi

# --- 6. Rename database.yml database names, if present ---
if [ -f "config/database.yml" ]; then
  if sed --version >/dev/null 2>&1; then
    sed -i "s/${OLD_NAME}/${NEW_NAME_SNAKE}/g" config/database.yml
  else
    sed -i '' "s/${OLD_NAME}/${NEW_NAME_SNAKE}/g" config/database.yml
  fi
fi

# --- 7. Reset git history so this becomes a fresh, independent repo ---
if [ -d ".git" ]; then
  read -r -p "Reset git history so this becomes an independent repo? [y/N] " RESET_GIT
  if [[ "$RESET_GIT" =~ ^[Yy]$ ]]; then
    rm -rf .git
    git init -q
    git add -A
    git commit -q -m "Initial commit: renamed from ${OLD_NAME} to ${NEW_NAME_SNAKE}"
    echo "Git history reset. Fresh repo created with one initial commit."

    read -r -p "Enter the git remote URL for '${NEW_NAME_SNAKE}' (leave blank to skip): " REMOTE_URL
    if [ -n "$REMOTE_URL" ]; then
      git remote add "$NEW_NAME_SNAKE" "$REMOTE_URL"
      CURRENT_BRANCH=$(git branch --show-current)
      git push -u "$NEW_NAME_SNAKE" "$CURRENT_BRANCH"
      echo "Remote '${NEW_NAME_SNAKE}' added and pushed to ${REMOTE_URL}"
    else
      echo "Skipped remote setup. You can add one later with:"
      echo "  git remote add ${NEW_NAME_SNAKE} <your-repo-url>"
      echo "  git push -u ${NEW_NAME_SNAKE} $(git branch --show-current)"
    fi
  else
    echo "Skipped git history reset. Remember to update your remote:"
    echo "  git remote set-url origin <your-new-repo-url>"
  fi
fi

# --- 8. Reminders for things this script can't safely automate ---
cat <<EOF

==========================================
 Rename complete: $NEW_NAME_SNAKE
==========================================

Next steps (do these manually):
  1. bundle install
  2. bin/rails db:drop db:create db:migrate   # old-named dev/test DBs won't auto-drop
  3. Review config/deploy.yml (Kamal) for registry/image names if you use a container registry
  4. Review config/credentials.yml.enc / master.key — these were NOT touched
  5. Search for any remaining stray references just in case:
       grep -rli "${OLD_NAME}" --exclude-dir=.git .

EOF