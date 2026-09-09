#!/bin/sh
if [ "$1" = "-c" ]; then
    printf 'planted rejection\n' >&2
    exit 1
fi
exit 99
