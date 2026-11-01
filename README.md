> **[RETIRED / 已退役]** This sentinel retired on 2026-11-02 (B-091 single-master migration): Gitee mirrors are frozen as private archives, dual-end consistency checks no longer apply. Canonical development lives on GitHub.
> **[已退役]** 2026-11-02 随 GitHub 单主转换批退役：Gitee 镜像已转私冻结，双端一致性核对不再适用。

# sync-sentinel

Daily **read-only** consistency check between the canonical Git repositories and their public GitHub mirrors: default-branch SHA and `v*` version tags, per repository.

[![dual-end sentinel](https://github.com/evorule/sync-sentinel/actions/workflows/sentinel.yml/badge.svg)](https://github.com/evorule/sync-sentinel/actions/workflows/sentinel.yml)

- Runs daily (scheduled) and on demand; the badge reflects the latest run.
- **Red = divergence detected** between the canonical repository and the mirror. This can be transient while a change is in flight; open the latest run to see the per-repository table.
- Design: anonymous read (`ls-remote`) only — no tokens, no writes, no pushes. Retry included for transient network resets.
