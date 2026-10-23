#!/usr/bin/env bash
# Read-only dual-end consistency check: canonical repo vs public mirror.
# Compares default-branch SHA and v* tag sets for each public dual-end repo.
# No tokens, no writes. Exits 1 on any divergence (fail-visible).

set -u
REPOS="evorule:main evorule-server:main evorule-rule:main evo-agent:main evo-agent-desktop:main evorule-console-cloud:main evorule-wasm-demo:main evorule-system-rules:main evorule-hash:main evorule-bundle:main evorule-context-inspector:main evorule-integration-tests:master"

lsr() { # lsr <url> <pattern> — ls-remote with retry (transient resets happen)
  local out="" i
  for i in 1 2 3; do
    out=$(git ls-remote "$1" "$2" 2>/dev/null) && [ -n "$out" ] && { printf '%s\n' "$out"; return 0; }
    sleep 5
  done
  return 1
}

fail=0
echo "| repo | branch | main SHA match | tags gitee/github | verdict |" > /tmp/table.md
echo "|---|---|---|---|---|" >> /tmp/table.md
for entry in $REPOS; do
  r="${entry%%:*}"; b="${entry##*:}"
  g_sha=$(lsr "https://gitee.com/evorule/$r.git" "refs/heads/$b" | awk '{print $1}' | head -1)
  h_sha=$(lsr "https://github.com/evorule/$r.git" "refs/heads/$b" | awk '{print $1}' | head -1)
  g_tags=$(lsr "https://gitee.com/evorule/$r.git" "refs/tags/v*" | awk -F'/' '{print $NF}' | grep -v '\^{}$' | sort -u)
  h_tags=$(lsr "https://github.com/evorule/$r.git" "refs/tags/v*" | awk -F'/' '{print $NF}' | grep -v '\^{}$' | sort -u)
  g_n=$(printf '%s' "$g_tags" | grep -c . || true); h_n=$(printf '%s' "$h_tags" | grep -c . || true)
  only_g=$(comm -23 <(printf '%s\n' "$g_tags") <(printf '%s\n' "$h_tags") | grep -c . || true)
  only_h=$(comm -13 <(printf '%s\n' "$g_tags") <(printf '%s\n' "$h_tags") | grep -c . || true)
  verdict="OK"
  if [ -z "$g_sha" ] || [ -z "$h_sha" ]; then verdict="QUERY-FAIL"; fail=1
  elif [ "$g_sha" != "$h_sha" ]; then verdict="MAIN-DIVERGED"; fail=1
  fi
  if [ "${only_g:-0}" != "0" ] || [ "${only_h:-0}" != "0" ]; then verdict="$verdict+TAG-DIFF"; fail=1; fi
  echo "| $r | $b | $([ "$g_sha" = "$h_sha" ] && echo yes || echo no) | ${g_n:-?}/${h_n:-?} | $verdict |" >> /tmp/table.md
done
cat /tmp/table.md
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then cp /tmp/table.md "$GITHUB_STEP_SUMMARY"; fi
[ $fail -eq 0 ] && echo "ALL-SYNCED" || echo "DIVERGENCE-DETECTED"
exit $fail
