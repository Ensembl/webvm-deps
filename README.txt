This repository contains (generally large) installed & deployable
libraries.

It should be checked out as webvm.git/apps/webvm-deps/

See webvm.git/README.txt


The "other end" which expects files to be present is Otter::Paths
  http://git.internal.sanger.ac.uk/cgi-bin/gitweb.cgi?p=anacode/webvm.git;a=history;f=lib/bootstrap/Otter/Paths.pm;hb=HEAD

The "small" branch is intended to be safe for rapid checkouts onto
small machines,
  git clone -b small intcvs1:/repos/git/anacode/webvm-deps.git



More history
------------

Before 9d4e2671 (fetch-ensemblNN - reduce the amount of "cvs checkout")
each ensembl-branch-NN was ~300 MiB because it included everything
present in the /nfs/WWWdev/SHARED_docs/lib/ensembl-branch-*/ style.


In order to shrink the size of the Git packfiles, I rewrote the
history:

 git tag -a -m 'HEAD of master, as it was before shrinking the ensembl checkouts' attic/huge-master master
 # git branch -D master; git branch master attic/huge-master
 git filter-branch -f -d /tmp/gfb-deps \
   --index-filter 'git rm -r --cached --ignore-unmatch ensembl-branch-{65,66,70,71}/{cbuild,conf,ctrl_scripts,htdocs,ensembl-compara/{docs,modules/t,scripts,sql},ensembl-draw/modules/Sanger/,ensembl-external/{family,modules/t,scripts,sql},ensembl-functgenomics/{DAS,docs,modules/t,scripts,sql},ensembl/{docs,misc-scripts,modules/t,sql},ensembl-tools/scripts,ensembl-variation/{C_code,documentation,modules/t,schema,scripts,sql}}' \
 --msg-filter 'cat; perl -e "exit( (shift) =~ /^(b949368d|48c17ecb|75202075)/ ? 0 : 1)" $GIT_COMMIT || [ "$( git merge-base $GIT_COMMIT 5769ba2b208a03f8f755e090155bf9994de08cc9 )" = "17335b976b4d756452d2ab4e5751c0640675105e" ] || printf "\nHistory rewritten per %s\n" $( git rev-parse small )' \
 --prune-empty master
