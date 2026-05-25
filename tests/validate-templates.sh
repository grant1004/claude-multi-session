#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMANDS_DIR="$REPO_ROOT/plugins/claude-multi-session/commands"
TEMPLATES_DIR="$REPO_ROOT/plugins/claude-multi-session/templates/.claude-multi-session"

failures=0
passes=0

pass() { passes=$((passes + 1)); printf "  ✓ %s\n" "$1"; }
fail() { failures=$((failures + 1)); printf "  ✗ %s\n" "$1"; }

# ---------- Check 1: command files have allowed-tools + description ----------
echo "── Check 1: Command files have allowed-tools and description in frontmatter"

while IFS= read -r -d '' f; do
  rel="${f#"$REPO_ROOT/"}"
  head_block=$(head -20 "$f")

  if ! echo "$head_block" | head -1 | grep -q '^---'; then
    fail "$rel — missing YAML frontmatter"
    continue
  fi

  fm=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$f")

  has_at=0; has_desc=0
  echo "$fm" | grep -q '^allowed-tools:' && has_at=1
  echo "$fm" | grep -q '^description:' && has_desc=1

  if [ "$has_at" -eq 1 ] && [ "$has_desc" -eq 1 ]; then
    pass "$rel"
  else
    [ "$has_at" -eq 0 ] && fail "$rel — missing allowed-tools"
    [ "$has_desc" -eq 0 ] && fail "$rel — missing description"
  fi
done < <(find "$COMMANDS_DIR" -name '*.md' -print0)

# ---------- Check 2: init.md copy-list files exist in templates ----------
echo "── Check 2: All files referenced in init.md copy list exist in templates/"

init_copy_files=(
  "workflow.md"
  "roles/reviewer.md"
  "roles/worker.md"
  "roles/project-manager.md"
  "messages/dispatch.md"
  "messages/review-pass.md"
  "messages/completion-report.md"
  "log-templates/atomic.md"
  "log-templates/daily.md"
  "log-templates/reviewer-master.md"
  "log-templates/pitfall.md"
)

for relpath in "${init_copy_files[@]}"; do
  if [ -f "$TEMPLATES_DIR/$relpath" ]; then
    pass "$relpath"
  else
    fail "$relpath — not found in templates/"
  fi
done

# ---------- Check 3: No WPF/XAML terms in template files (regression guard) ----------
echo "── Check 3: No WPF/XAML/DataTrigger terms in template files (regression guard)"

wpf_pattern='WPF|XAML|DataTrigger|DependencyProperty|MultiBinding|App\.xaml|\.csproj'
wpf_hits=0

while IFS= read -r -d '' f; do
  rel="${f#"$REPO_ROOT/"}"
  if grep -Pn "$wpf_pattern" "$f" > /dev/null 2>&1; then
    wpf_hits=1
    while IFS= read -r line; do
      fail "$rel:$line"
    done < <(grep -Pn "$wpf_pattern" "$f")
  fi
done < <(find "$TEMPLATES_DIR" -name '*.md' -print0)

# Also check the extra template file outside the .claude-multi-session tree
extra_template="$REPO_ROOT/plugins/claude-multi-session/templates/claude-md-snippet.md"
if [ -f "$extra_template" ]; then
  rel="${extra_template#"$REPO_ROOT/"}"
  if grep -Pn "$wpf_pattern" "$extra_template" > /dev/null 2>&1; then
    wpf_hits=1
    while IFS= read -r line; do
      fail "$rel:$line"
    done < <(grep -Pn "$wpf_pattern" "$extra_template")
  fi
fi

if [ "$wpf_hits" -eq 0 ]; then
  pass "No WPF/XAML terms found in any template file"
fi

# ---------- Check 4: Role files have # Role: heading ----------
echo "── Check 4: Role files have a '# Role:' H1 heading"

while IFS= read -r -d '' f; do
  rel="${f#"$REPO_ROOT/"}"
  if grep -q '^# Role:' "$f"; then
    pass "$rel"
  else
    fail "$rel — missing '# Role:' H1 heading"
  fi
done < <(find "$TEMPLATES_DIR/roles" -name '*.md' -print0)

# ---------- Check 5: Message templates have a fenced code block ----------
echo "── Check 5: Message templates have a fenced code block"

while IFS= read -r -d '' f; do
  rel="${f#"$REPO_ROOT/"}"
  if grep -q '^ *```' "$f"; then
    pass "$rel"
  else
    fail "$rel — no fenced code block found"
  fi
done < <(find "$TEMPLATES_DIR/messages" -name '*.md' -print0)

# ---------- Check 6: Log template files have YAML frontmatter ----------
echo "── Check 6: Log template files have YAML frontmatter"

while IFS= read -r -d '' f; do
  rel="${f#"$REPO_ROOT/"}"
  # Log templates are documentation files — they contain a YAML frontmatter
  # example inside a fenced code block, not at the file's top level.
  # Check that the file demonstrates frontmatter (at least two '---' lines).
  delim_count=$(grep -c '^---$' "$f" || true)
  if [ "$delim_count" -ge 2 ]; then
    pass "$rel"
  else
    fail "$rel — no YAML frontmatter block found (need at least opening + closing '---')"
  fi
done < <(find "$TEMPLATES_DIR/log-templates" -name '*.md' -print0)

# ---------- Summary ----------
echo ""
total=$((passes + failures))
echo "── Summary: $passes passed, $failures failed ($total checks)"

if [ "$failures" -gt 0 ]; then
  exit 1
fi
exit 0
