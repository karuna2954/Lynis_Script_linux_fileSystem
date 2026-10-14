
#!/usr/bin/env bash

# Filesystem Health and Mount Audit
# Purpose: Check capacity, mounts, and filesystem configuration.

set -u

REPORT="filesystem_health_$(date +%F_%H-%M-%S).txt"
THRESHOLD=80

{
    echo "======================================"
    echo " LINUX FILESYSTEM HEALTH AUDIT"
    echo "======================================"
    date
    echo

    echo "[1] Disk usage"
    df -hT
    echo

    echo "[2] Filesystems at or above ${THRESHOLD}% usage"
    df -P -x tmpfs -x devtmpfs |
    awk -v limit="$THRESHOLD" '
        NR == 1 { print; next }
        {
            usage = $5
            sub(/%/, "", usage)
            if (usage + 0 >= limit) print
        }
    '
    echo

    echo "[3] Mounted filesystems and mount options"
    findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS
    echo

    echo "[4] Read-only mounts"
    findmnt -rn -o TARGET,FSTYPE,OPTIONS |
    awk '$3 ~ /(^|,)ro(,|$)/ {
        print "READ-ONLY MOUNT: " $0
    }'
    echo "Note: read-only mounts may be intentional."
    echo

    echo "[5] /etc/fstab configuration"
    if [[ -r /etc/fstab ]]; then
        awk '
            /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
            NF >= 4 {
                printf "Device=%s Mountpoint=%s Type=%s Options=%s\n",
                       $1, $2, $3, $4
            }
        ' /etc/fstab
    else
        echo "Cannot read /etc/fstab."
    fi
    echo

    echo "[6] Check fstab entries against current mounts"
    if command -v findmnt >/dev/null 2>&1; then
        findmnt --verify --verbose 2>&1
        echo "findmnt verification exit code: $?"
    fi
    echo

    echo "[7] Lynis storage checks"
    if command -v lynis >/dev/null 2>&1; then
        lynis audit system --tests-from-group storage --quick
    else
        echo "Lynis is not installed; skipped Lynis checks."
    fi

} 2>&1 | tee "$REPORT"

echo
echo "Audit output saved to: $REPORT"
