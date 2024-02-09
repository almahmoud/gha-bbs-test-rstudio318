#!/bin/bash
set -x
PKG="$1"
LIBRARY="$2"
WORKPATH="$3"

runstart=$(cat $WORKPATH/runstarttime)
containername=$(cat $WORKPATH/containername)
mkdir -p $LIBRARY
mkdir -p /tmp/tars/
mkdir -p /tmp/pkglogs/

# Get unique dependencies (only in Suggests, but doesn't appear in the list anywhere else) list to also build their binaries
sed -n "/^    \"$PKG\"/,/^    \"/p" uniquedeps.json | grep '^        "' | awk -F'"' '{print $2}' > /tmp/uniquedeps

# Build package, and exit with code 0 only on success
# Redirect all stout/stderr to log
(time Rscript -e "Sys.setenv(BIOCONDUCTOR_USE_CONTAINER_REPOSITORY=FALSE); p <- .libPaths(); p <- c('$LIBRARY', p); .libPaths(p); if(BiocManager::install('$PKG', INSTALL_opts = '--build', update = FALSE, quiet = FALSE, dependencies='strong', force = TRUE, keep_outputs = TRUE) %in% rownames(installed.packages())) q(status = 0) else q(status = 1)" 2>&1 ) 2>&1 | tee /tmp/pkglogs/$PKG
  
cat /tmp/uniquedeps | xargs -i Rscript -e "Sys.setenv(BIOCONDUCTOR_USE_CONTAINER_REPOSITORY=FALSE); p <- .libPaths(); p <- c('$LIBRARY', p); .libPaths(p); BiocManager::install('{}', INSTALL_opts = '--build', update = FALSE, quiet = FALSE, dependencies='strong', force = TRUE, keep_outputs = TRUE)" 2>&1 >> /tmp/pkglogs/$PKG

mv *.tar.gz /tmp/tars/ || true

cd $WORKPATH

ls /tmp/tars | awk -F'_' '{print $1}' | grep -v "$PKG" | xargs -i bash -c 'if grep -q "tar.gz$" lists/{}; then rm /tmp/tars/$(cat lists/{}); else echo "{} tar not found."; fi'
