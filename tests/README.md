# Tests

## validate-templates.sh

Validates structural correctness of all plugin template and command files.

### Run

```sh
bash tests/validate-templates.sh
```

Exit code 0 = all checks pass. Non-zero = at least one failure (details printed to stdout).

### Checks

| # | What | Files checked |
|---|------|---------------|
| 1 | Command files have `allowed-tools` and `description` in YAML frontmatter | `plugins/claude-multi-session/commands/**/*.md` |
| 2 | All files listed in `init.md`'s copy manifest exist in templates | `plugins/claude-multi-session/templates/.claude-multi-session/` |
| 3 | No WPF/XAML/DataTrigger terms in templates (regression guard) | All template `.md` files |
| 4 | Role files have a `# Role:` H1 heading | `templates/.claude-multi-session/roles/*.md` |
| 5 | Message templates contain a fenced code block | `templates/.claude-multi-session/messages/*.md` |
| 6 | Log templates demonstrate YAML frontmatter | `templates/.claude-multi-session/log-templates/*.md` |
