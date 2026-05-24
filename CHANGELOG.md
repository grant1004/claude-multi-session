# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-25

### Added

- Initial plugin scaffolding: manifest, MIT license, README, `/multi-session:init` command
- Role definitions (Reviewer, Worker, Project Manager), message templates (dispatch, completion-report, review-pass), log templates (atomic, daily, reviewer-master, pitfall), and workflow state machine
- QUICKSTART.md — zero-baseline Windows setup guide (steps 1-8)
- `claude-peers.ps1` PowerShell launcher script with `-id` flag and env var passthrough
- `.claude-plugin/marketplace.json` for `/plugin marketplace add` resolution
- `/multi-session:audit` and `/multi-session:roll-call` slash commands
- `/multi-session:bootstrap` command with onboarding pre-check on audit/roll-call
- `docs/.obsidian/` directory so `docs/` opens as an Obsidian vault out of the box
- Mandatory git pre-check on `/multi-session:init` with offer to run `git init` when missing
- `.gitignore` covering OS files, Obsidian workspace state, `node_modules/`, and editor configs
- `claude-peers` bash/zsh launcher script for macOS/Linux (mirrors PowerShell launcher behavior)

### Changed

- Restructured plugin from repo root into `plugins/claude-multi-session/` subdirectory
- Baked onboarding flow into audit and dispatch commands (per user feedback — removed separate bootstrap requirement)
- Replaced WPF-specific examples in all templates with framework-agnostic ones (env-var-shadow, Redis cache, REST API patterns)
- Scaffolded multi-session workflow documentation and PROGRESS.md audit structure

### Fixed

- Dropped redundant `[Alias('id')]` in PowerShell launcher that conflicted with case-insensitive parameter matching
- Switched marketplace manifest source from string path to `git-subdir` object form (required by plugin resolver)
- Made git context commands in audit tolerate empty or non-git repositories without erroring
