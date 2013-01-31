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
    {
        cd SHARED.core
        cvs -qn up 2>&1
        cvs -q diff -u 2>&1
    } > diff.SHARED.core.log+
    mv diff.SHARED.core.log+ diff.SHARED.core.log

#    find SHARED.core -type d -name CVS -print0 | xargs -r0 rm -rf
# tidier, but will make churn on the rsync

    git add -A SHARED.core nb.SHARED.core.diff
    git commit -m "$( basename $0 ): update"
fi

echo Done.
