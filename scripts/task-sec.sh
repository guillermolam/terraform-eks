#!/usr/bin/env bash
set -euo pipefail

TASKFILE=".tasks/security.yml"

if [[ ! -f ${TASKFILE} ]]; then
	echo "Error: ${TASKFILE} not found"
	exit 1
fi

# Extract the list of task names under the `tasks:` key
mapfile -t TASKS < <(
	awk '
    /^[[:space:]]*tasks:[[:space:]]*$/ { in_tasks=1; next }
    in_tasks && /^[[:space:]]{2}[a-zA-Z0-9_-]+:/ {
      name=$1
      sub(/:$/, "", name)
      print name
    }
    in_tasks && /^[^[:space:]]/ { exit }
  ' "${TASKFILE}"
)

if [[ ${#TASKS[@]} -eq 0 ]]; then
	echo "No tasks found in ${TASKFILE}"
	exit 1
fi

echo "Found tasks: ${TASKS[*]}"
echo

for t in "${TASKS[@]}"; do
	echo "→ Running task${ }$t"
	task --taskfile "${TASKFILE}" "${t}"
	echo "✔ Completed${ }$t"
	echo
done

echo "✅ All security tasks passed."
