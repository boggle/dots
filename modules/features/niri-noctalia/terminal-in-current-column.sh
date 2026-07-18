        old_id="$(niri msg -j focused-window | "$py" -c 'import sys,json; print(json.load(sys.stdin).get("id",""))')"

        "$term" "$@" >/dev/null 2>&1 &

        i=0
        while [ $i -lt 80 ]; do
          fw="$(niri msg -j focused-window 2>/dev/null || true)"
          new_id="$(printf %s "$fw" | "$py" -c 'import sys,json; d=json.load(sys.stdin); print(d.get("id",""))')"
          app_id="$(printf %s "$fw" | "$py" -c 'import sys,json; d=json.load(sys.stdin); print(d.get("app_id",""))')"

          if [ -n "$new_id" ] && [ "$new_id" != "$old_id" ] && [ "$app_id" = "$appid" ]; then
            break
          fi

          i=$((i + 1))
          sleep 0.025
        done

        niri msg action consume-or-expel-window-left >/dev/null 2>&1 || true
