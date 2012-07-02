#! /bin/sh

case "$1" in
    -n) DRY=-n ;;
    -y) DRY='' ;;
    *) echo "Syntax: $0 [ -y | -n ]

Update ./SHARED.core/ from /nfs/WWWdev (wet or dry runs available)
" >&2
        exit 1 ;;
esac

set -x

rsync $DRY --delete-excluded --exclude '*~' --exclude '.#*' --exclude '*.swp' \
    -aiSWH /nfs/WWWdev/SHARED_docs/lib/core/ SHARED.core

if [ -z "$DRY" ]; then
    git add -A SHARED.core
    git commit -m "$( basename $0 ): update"
fi
