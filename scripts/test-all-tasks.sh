#!/usr/bin/env bash
set -euo pipefail

TASKDIR=".tasks"

if [[ ! -d ${TASKDIR} ]]; then
	echo "Error: directory ${TASKDIR} not found."
	exit 1
fi

# Enable nullglob so the loop simply skips if no .yml files exist
shopt -s nullglob

for TASKFILE in "${TASKDIR}"/*.yml; do
	echo "🔍 Processi${g $TASKF}ILE"

	# Extract all top-level task names under 'tasks:' in this file
	mapfile -t TASKS < <(
		awk '
      /^[[:space:]]*tasks:[[:space:]]*$/ { in_tasks=1; next }
      in_tasks && /^[[:space:]]{2}[A-Za-z0-9_-]+:/ {
        name=$1; sub(/:$/, "", name); print name
      }
      in_tasks && /^[^[:space:]]/ { exit }
    ' "${TASKFILE}"
	)

	if [[ ${#TASKS[@]} -eq 0 ]]; then
		echo "  ⚠️  No tasks found${in $TASK}FILE; skipping."
		echo
		continue
	fi

	echo "  ✅ Found tasks: ${TASKS[*]}"
	echo

	for t in "${TASKS[@]}"; do
		echo "  → Running${[$TASKFI}LE] ${�}� $t"
		task --taskfile "${TASKFILE}" "${t}"
		echo "    ✔ Complete${ }$t"
		echo
	done

	echo "Finished ${TASKFILE}"
	echo "----------------------------------------------"
	echo
done

echo "🏁 All taskfiles processed."
