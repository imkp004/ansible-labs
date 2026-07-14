#!/usr/bin/env bash
set -euo pipefail

INVENTORY_FILE="${1:-inventory}"
KNOWN_HOSTS_FILE="${HOME}/.ssh/known_hosts"

mkdir -p "${HOME}/.ssh"
touch "${KNOWN_HOSTS_FILE}"

echo "Reading inventory: ${INVENTORY_FILE}"

awk '
BEGIN { in_group=0 }
{
  gsub(/\r/, "")
}
# skip blank lines and comments
/^[[:space:]]*$/ { next }
/^[[:space:]]*#/ { next }

# group headers like [servers]
/^\[.*\]$/ {
  in_group=1
  next
}

# host lines
in_group {
  alias=$1

  host=""
  ansible_host=""
  for (i=2; i<=NF; i++) {
    if ($i ~ /^ansible_host=/) {
      split($i, a, "=")
      ansible_host=a[2]
    } else if ($i !~ /=/) {
      host=$i
    }
  }

  if (ansible_host != "") {
    target=ansible_host
  } else if (host != "") {
    target=host
  } else {
    target=alias
  }

  print alias, target
}
' "${INVENTORY_FILE}" | while read -r alias target; do
  echo "Updating key for ${alias} (${target})"

  ssh-keygen -R "${alias}" -f "${KNOWN_HOSTS_FILE}" >/dev/null 2>&1 || true
  ssh-keygen -R "${target}" -f "${KNOWN_HOSTS_FILE}" >/dev/null 2>&1 || true

  ssh-keyscan -H -T 10 "${target}" 2>/dev/null | sed "s/^${target}/${alias},${target}/" >> "${KNOWN_HOSTS_FILE}"
done

echo "known_hosts updated: ${KNOWN_HOSTS_FILE}"
