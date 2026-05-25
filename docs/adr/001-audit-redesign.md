---
title: "ADR-001: Audit 重設計 — grill 環節 + codebase-memory + catchup mode"
date: 2026-05-26
status: accepted
---

# ADR-001: Audit 重設計

## 背景

2026-05-25 首次 multi-session 實跑，audit 產出的 milestones 大多是 polish/refactor（非必要）。根因：audit 沒有先問 user 意圖就直接掃 code 找改善點。

## 決策

### 1. Audit 觸發路徑（雙模式）
- User 帶明確目標 → 圍繞目標拆 milestones
- User 不確定 → audit 掃 code 提建議，但 **必須 user confirm 方向後才產 milestones**

### 2. Grill 環節（bake 進 audit.md）
- 寫在 audit.md 的獨立 section，方便未來抽離成獨立命令
- 固定 5 題，允許 N/A，可擴充：
  1. 「這次 session 要達成什麼？」
  2. 「哪些東西不要動？」
  3. 「有什麼已經卡住或壞掉的？」
  4. 「品質標準是什麼？」
  5. 「有 deadline 或外部限制嗎？」

### 3. codebase-memory 整合
- Default 必須執行 `get_architecture`
- 環境不允許 → 詢問 user 要不要安裝
- 堅持不裝 → fallback glob/grep
- 三層邏輯：try → ask → fallback

### 4. Catchup = audit 的自動 mode（不是獨立命令）
- `git log` 非空 → 自動進 catchup mode
- Catchup mode 額外步驟：git log --stat -30、get_architecture、讀既有 docs、讀 pitfalls
- 空 repo → 新專案 mode

### 5. PROGRESS.md audit summary 擴充
現有欄位不變，新增：
- **Hotspots**: 最近 30 commits 最常動的 3-5 個檔案/模組
- **現狀**: 什麼做完、做到一半、壞掉
- **已知限制**: user 說不要動的 + code 觀察到的 constraints

### 6. Test spec 寫進 acceptance criteria
- 每個 milestone 的 acceptance criteria 直接包含 test spec（不另開 section）
- 不區分「人看的」vs「機器跑的」— worker 自行判斷
- 不加 [diff] / [test] / [run] 標記

### 7. dispatch.md 小改
- 規則提醒加一條：acceptance criteria 含 executable test → test pass 才能 commit

## 影響範圍
- `plugins/claude-multi-session/commands/multi-session/audit.md` — 重寫
- `plugins/claude-multi-session/templates/.claude-multi-session/messages/dispatch.md` — 小改
- 不需要新命令、不需要新文件
