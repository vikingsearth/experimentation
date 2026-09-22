#!/bin/zsh
# Run one local arm of hypothesis 2.1: five briefs, one worker at a time.
#
#   ./run-local-arm.sh qwen3-8b-40k arm-c-qwen3-8b-40k
#   ./run-local-arm.sh gemma4-12b-256k arm-d-gemma4-12b-256k
#
# Sequential by design. The ollama daemon serves one slot on stock defaults, so
# concurrency buys nothing and costs memory (measured in hypothesis 1).

set -u
MODEL="${1:?model tag required}"
ARM="${2:?arm directory name required}"
REPO="/Users/wikus.bergh/dev/experimentation"
BRIEFS="$REPO/optimization-exp/hyp2/briefs"
OUT="$REPO/optimization-exp/hyp2-1/reports/$ARM"
# Per-worker watchdog. Default 90 min: gemma4:12b needed more than the original
# 45 on brief 2 and was killed mid-work. Override with DEADLINE=<seconds>.
DEADLINE=${DEADLINE:-5400}
mkdir -p "$OUT"
cd "$REPO" || exit 1

LOG="$OUT/_progress.log"
[ -f "$LOG" ] && print -r -- "--- resumed $(date +%H:%M:%S) ---" >> "$LOG" || : > "$LOG"
[ -f "$OUT/_metrics.tsv" ] || printf 'brief\tmodel\tattempt\tinput_tokens\toutput_tokens\tturns\tapi_ms\twall_s\tstatus\n' > "$OUT/_metrics.tsv"
[ -f "$OUT/_start.txt" ] || date +"%Y-%m-%dT%H:%M:%S" > "$OUT/_start.txt"

say(){ print -r -- "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

# Brief 5 runs last: it is the heaviest, so four results are banked first.
# Optional 3rd argument resumes a partial arm, e.g. "02,03,04,05".
ALL=(01-data-model 02-policy-thresholds 03-risk-and-budget 04-state-and-audit 05-presentation-and-docs)
if [ $# -ge 3 ]; then
  ORDER=()
  for want in ${(s:,:)3}; do
    for b in $ALL; do [[ $b == ${want}-* ]] && ORDER+=$b; done
  done
else
  ORDER=($ALL)
fi

say "arm $ARM on $MODEL, ${#ORDER[@]} briefs, sequential"

for B in $ORDER; do
  for ATTEMPT in 1 2; do
    say "brief $B attempt $ATTEMPT starting"
    S=$(date +%s)
    RAW="$OUT/$B.attempt$ATTEMPT.json"

    ANTHROPIC_BASE_URL=${BASE_URL:-http://localhost:11434} \
    ANTHROPIC_AUTH_TOKEN=ollama \
    ANTHROPIC_API_KEY="" \
      claude -p --bare --strict-mcp-config --tools Bash Read \
             --model "$MODEL" --output-format json \
             < "$BRIEFS/$B.md" > "$RAW" 2>"$OUT/$B.attempt$ATTEMPT.err" &
    PID=$!

    # No timeout(1) on this machine, so watchdog by hand.
    while kill -0 $PID 2>/dev/null; do
      [ $(( $(date +%s) - S )) -gt $DEADLINE ] && { say "brief $B attempt $ATTEMPT exceeded ${DEADLINE}s, killing"; kill -9 $PID 2>/dev/null; break; }
      sleep 10
    done
    wait $PID 2>/dev/null
    W=$(( $(date +%s) - S ))

    STATUS=$(python3 - "$RAW" "$OUT/$B.md" <<'PY'
import json,sys,os
raw,out=sys.argv[1],sys.argv[2]
try:
    d=json.load(open(raw))
except Exception:
    print("no-json|0|0|0|0"); raise SystemExit
u=d.get("usage",{}) or {}
res=(d.get("result") or "").strip()
turns=d.get("num_turns",0)
shaped = bool(res) and not d.get("is_error") and "## Findings" in res
# A worker that finishes in one turn made no tool call, so it did not investigate,
# whatever its report claims. Run 1 of arm C produced two such reports and the
# old check passed them as ok. Turn count is the real signal.
if shaped and turns<=1: st="no-tools"
elif shaped: st="ok"
elif not res: st="empty"
else: st="malformed"
if shaped: open(out,"w").write(res+"\n")
print("%s|%s|%s|%s|%s" % (st, u.get("input_tokens",0), u.get("output_tokens",0), turns, d.get("duration_api_ms",0)))
PY
)
    ST=${STATUS%%|*}; REST=${STATUS#*|}
    IN=${REST%%|*}; REST=${REST#*|}
    OUTT=${REST%%|*}; REST=${REST#*|}
    TURNS=${REST%%|*}; APIMS=${REST##*|}

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$B" "$MODEL" "$ATTEMPT" "$IN" "$OUTT" "$TURNS" "$APIMS" "$W" "$ST" >> "$OUT/_metrics.tsv"
    say "brief $B attempt $ATTEMPT -> $ST (in=$IN out=$OUTT turns=$TURNS wall=${W}s)"

    [ "$ST" = "ok" ] && break
    [ $ATTEMPT -eq 2 ] && say "brief $B FAILED after 2 attempts, recording incomplete"
  done
done

date +"%Y-%m-%dT%H:%M:%S" > "$OUT/_end.txt"
say "arm $ARM complete"
