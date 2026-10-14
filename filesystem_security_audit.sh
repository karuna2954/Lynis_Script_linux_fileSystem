
#!/usr/bin/env bash

# Filesystem Security Audit
# Purpose: Check risky permissions and sensitive-file access.

set -u

REPORT="filesystem_security_$(date +%F_%H-%M-%S).txt"

{
    echo "======================================"
    echo " LINUX FILESYSTEM SECURITY AUDIT"
    echo "======================================"
    date
    echo

    echo "[1] Sensitive file permissions"
    for file in /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/sudoers; do
        if [[ -e "$file" ]]; then
            stat -c '%A | owner=%U:%G | %n' "$file"
        fi
    done
    echo

    echo "[2] World-writable files and directories"
    echo "Searching common system locations..."
    for dir in /etc /usr/local /var; do
        if [[ -d "$dir" ]]; then
            find "$dir" -xdev -type f -perm -0002 \
                -printf 'WORLD-WRITABLE FILE: %m %u:%g %p\n' \
                2>/dev/null
            find "$dir" -xdev -type d -perm -0002 ! -perm -1000 \
                -printf 'WORLD-WRITABLE DIR WITHOUT STICKY BIT: %m %u:%g %p\n' \
                2>/dev/null
        fi
    done
    echo

    echo "[3] SUID and SGID files"
    find /usr /bin /sbin -xdev -type f \
        \( -perm -4000 -o -perm -2000 \) \
        -printf '%m %u:%g %p\n' 2>/dev/null
    echo

    echo "[4] Lynis file-permission checks"
    if command -v lynis >/dev/null 2>&1; then
        lynis audit system --tests-from-group file_permissions --quick
    else
        echo "Lynis is not installed; skipped Lynis checks."
    fi

} 2>&1 | tee "$REPORT"

echo
echo "Audit output saved to: $REPORT"
