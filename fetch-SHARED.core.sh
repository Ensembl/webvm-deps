#! /bin/sh

SHARED=SHARED.core
SHARED_DIFF=diff.$SHARED.log
case "$1" in
    -n) DRY=-n ;;
    -y) DRY='' ;;
    *) echo "Syntax: $0 [ -y | -n ]

Update ./$SHARED/ from /nfs/WWWdev (wet or dry runs available)
" >&2
        exit 1 ;;
esac

set -x
set -e

rsync $DRY --delete-excluded --exclude '*~' --exclude '.#*' --exclude '*.swp' \
    -iSWH -rltgD -E /nfs/WWWdev/SHARED_docs/lib/core/ $SHARED

if [ -z "$DRY" ]; then
    (
        cd $SHARED
        set +e
        cvs -qn up 2>&1
        cvs -q diff -u 2>&1
        true
    ) > $SHARED_DIFF+
    mv  $SHARED_DIFF+ $SHARED_DIFF

#    find $SHARED -type d -name CVS -print0 | xargs -r0 rm -rf
# tidier, but will make churn on the rsync

    git add -A $SHARED $SHARED_DIFF
    git commit -m "ran $( basename $0 ): update"
fi

echo Done.
