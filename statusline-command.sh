#!/usr/bin/env bash
#
# Claude Code status line script
# Shows: directory | model | context usage | today's API spend
#
# Requires: ccusage (npm install -g ccusage)
# Setup:    See README.md

input=$(cat)

get_val() {
    echo "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" |
    head -1 | sed 's/.*:[[:space:]]*"//;s/"$//'
}

get_num() {
    echo "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[0-9.]*" |
    head -1 | sed 's/.*:[[:space:]]*//'
}

cwd=$(get_val "current_dir")
[ -z "$cwd" ] && cwd=$(get_val "cwd")
[ -z "$cwd" ] && cwd="unknown"

model=$(get_val "display_name")
[ -z "$model" ] && model="unknown"

used=$(get_num "used_percentage")
dir=$(basename "$cwd")

# --- Today's spend (cached for 60s) ---
cache_file="/tmp/.ccusage_daily_cache"
cache_date_file="/tmp/.ccusage_daily_date"
now=$(date +%s)
today=$(date +%Y%m%d)
cached_date=""
[ -f "$cache_date_file" ] && cached_date=$(cat "$cache_date_file")

refresh=0
if [ -f "$cache_file" ] && [ "$cached_date" = "$today" ]; then
    cache_age=$(( now - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null) ))
    [ "$cache_age" -ge 60 ] && refresh=1
else
    refresh=1
fi

if [ "$refresh" -eq 1 ]; then
    cost_json=$(ccusage daily --since "$today" --json --offline 2>/dev/null)
    spend=$(echo "$cost_json" | grep -o '"totalCost"[[:space:]]*:[[:space:]]*[0-9.]*' | head -1 | sed 's/.*:[[:space:]]*//')
    if [ -n "$spend" ]; then
        printf "%s" "$spend" > "$cache_file"
        printf "%s" "$today" > "$cache_date_file"
    fi
else
    spend=$(cat "$cache_file" 2>/dev/null)
fi

[ -z "$spend" ] && spend="--"
if [ "$spend" != "--" ]; then
    spend_display=$(printf "$%.2f" "$spend")
else
    spend_display="$--"
fi

# --- Context display ---
if [ -n "$used" ]; then
    used_int=${used%.*}
    if [ -n "$used_int" ] && [ "$used_int" -ge 90 ]; then
        ctx_display="ctx: ${used}% [!!!]"
    elif [ -n "$used_int" ] && [ "$used_int" -ge 75 ]; then
        ctx_display="ctx: ${used}% [!!]"
    elif [ -n "$used_int" ] && [ "$used_int" -ge 50 ]; then
        ctx_display="ctx: ${used}% [!]"
    else
        ctx_display="ctx: ${used}%"
    fi
    printf "%s | %s | %s | today: %s" "$dir" "$model" "$ctx_display" "$spend_display"
else
    printf "%s | %s | ctx: -- | today: %s" "$dir" "$model" "$spend_display"
fi
