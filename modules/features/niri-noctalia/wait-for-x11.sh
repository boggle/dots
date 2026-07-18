        display=":0"
        sock="/tmp/.X11-unix/X0"

        i=0
        while [ $i -lt 200 ]; do
          if [ -S "$sock" ] && DISPLAY="$display" $XLSCLIENTS_BIN >/dev/null 2>&1; then
            break
          fi
          i=$((i + 1))
          sleep 0.05
        done

        export DISPLAY="$display"
        exec "$@"
