        display=":0"
        sock="/tmp/.X11-unix/X0"

        "$XWAYLAND_SATELLITE_BIN" "$display" &
        sat_pid=$!

        ready=0
        i=0
        while [ $i -lt 200 ]; do
          if [ -S "$sock" ] && DISPLAY="$display" $XLSCLIENTS_BIN >/dev/null 2>&1; then
            ready=1
            break
          fi
          i=$((i + 1))
          sleep 0.05
        done

        if command -v systemctl >/dev/null 2>&1; then
          if [ "$ready" -eq 1 ]; then
            systemctl --user set-environment DISPLAY="$display" >/dev/null 2>&1 || true
          fi
        fi

        wait "$sat_pid"
