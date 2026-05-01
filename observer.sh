#!/bin/sh
set -eu

TARGET="${TARGET:-/copyfail-probe/testfile}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-2}"
MAX_READS="${MAX_READS:-0}"

echo "[observer] safe observer started"
echo "[observer] target: ${TARGET}"
echo "[observer] interval_seconds: ${INTERVAL_SECONDS}"
echo "[observer] max_reads: ${MAX_READS}"
echo "[observer] uid: $(id -u), gid: $(id -g)"
echo "[observer] initial stat:"
ls -l "${TARGET}"

LAST_SHA="$(sha256sum "${TARGET}" | awk '{print $1}')"
echo "[observer] initial sha256: ${LAST_SHA}"

echo "[observer] initial content begin"
cat "${TARGET}"
echo "[observer] initial content end"

count=0

while :; do
    count=$((count + 1))

    CURRENT_SHA="$(sha256sum "${TARGET}" | awk '{print $1}')"

    echo "[observer] read #${count}"
    echo "[observer] sha256: ${CURRENT_SHA}"

    if [ "${CURRENT_SHA}" != "${LAST_SHA}" ]; then
        echo "[observer] HASH CHANGED!"
        echo "[observer] previous sha256: ${LAST_SHA}"
        echo "[observer] current sha256:  ${CURRENT_SHA}"
        LAST_SHA="${CURRENT_SHA}"
    fi

    echo "[observer] content begin"
    cat "${TARGET}"
    echo "[observer] content end"

    if [ "${MAX_READS}" -gt 0 ] && [ "${count}" -ge "${MAX_READS}" ]; then
        echo "[observer] completed after ${count} reads"
        exit 0
    fi

    sleep "${INTERVAL_SECONDS}"
done