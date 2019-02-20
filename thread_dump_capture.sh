#!/usr/bin/env bash


get_thread_dump() {
    while read -r _pid ; do

        TIMESTAMP=$(date -d "now" +'%F_%H%M')
        NODE_NAME=$(ps aux | grep "${_pid}" | grep -Eo '[D]weblogic.Name=[A-Za-z]*([0-9]{0,2})' | awk -F '=' '{print $NF}')
        TD_DIR="/acme/threaddumps/${NODE_NAME}"
        FILE="${TD_DIR}/${NODE_NAME}ThreadDumpCapture_${TIMESTAMP}_${_pid}.log"

        # If _pid is not empty then create the thread dump
        if [[ ! -z "${_pid}" ]]; then
            mkdir -p "${TD_DIR}"
            jstack -l "${_pid}" > "${FILE}" 2>&1 &
        fi

    # Loop over output of ps command (starts at bottom of while loop)
    done < <(ps aux | grep -E '[D]weblogic.Name=[A-Za-z]*(Admin|Server[0-9]{0,2})' | awk '{print $2}')

    # Remove NODE_NAME from TD_DIR
    TD_DIR="${TD_DIR//${NODE_NAME}}"

    # Compress old thread dumps
    find "${TD_DIR}" \
        -type f \
        -mmin +60 \
        -not -name "*.gz*" \
        -name "*ThreadDumpCapture*.log*" \
        -exec gzip -f {} \; 2>/dev/null

    # Remove old compressed files
    find "${TD_DIR}" \
        -type f \
        -mtime +31 \
        -name "*ThreadDumpCapture*.log.gz*" \
        -exec rm -fv {} \; 2>/dev/null
}


get_thread_dump
