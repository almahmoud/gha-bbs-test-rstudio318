#!/bin/bash
set -xe
git pull origin main || true
git reset --hard origin/main

STARTTIME="$(cat runstarttime)"

mkdir -p lists/auto
touch tobuild.txt
if [ ! -s tobuild.txt ]; then
      # Get all packages with no deps in the working list
      # Make a file with "readytobuild" for each path lists/{pkg}
      grep -Pzo "(?s)\s*\"\N*\":\s*\[\s*\]" packages.json | awk -F'"' '{print $2}' | grep -v '^$' | xargs -i bash -c 'touch lists/{} && if ! [ -s "lists/failed/{}" ]; then if ! [ -s "lists/{}" ]; then echo "readytobuild" > lists/{}; else if grep -q "tar.gz$" lists/{}; then bash -c "mv lists/{} lists/auto/ && echo readytobuild > lists/{}"; fi; fi; fi'

      # Add list of packages to build
      grep -lr "readytobuild" lists/ | sed 's#lists/##g' > tobuild.txt


      if [ ! -s tobuild.txt ] && [ -f "packages.json" ]; then
            mkdir -p logs/$STARTTIME
            counter=0
            # Retrieve existing counter
            if [ -f "logs/$STARTTIME/empty_retries" ]; then
                counter=$(<logs/$STARTTIME/empty_retries)
            fi
            # Bump and store counter
            counter=$((counter+1))
            echo $counter > "logs/$STARTTIME/empty_retries"

            if [ $counter -gt 10 ]; then
                # Get list of packages that aren't marked as either failed or successful (errored out or timed out)
                grep -Ervl "(failed|tar.gz$)" lists | grep -v "failed" > /tmp/resetpkgs || true
                if [ -s /tmp/resetpkgs ]; then
                    mkdir -p logs/$STARTTIME/pkgretries
                    # If package counter on 2-5 attempt (1-4 retries), reset the empty list retries counter and rm the pkg claim file so it gets rescheduled
                    cat /tmp/resetpkgs | xargs -i bash -c 'pkgcounter=0; retrypath="logs/$STARTTIME/pkgretries/{}"; if [ -f "$retrypath" ]; then pkgcounter=$(<$retrypath); fi; pkgcounter=$((pkgcounter+1)); mkdir -p $(dirname $retrypath); echo $pkgcounter > "$retrypath"; if [ $pkgcounter -lt 5 ]; then rm {} && rm logs/$STARTTIME/empty_retries || true; fi'
                    if [ $counter -gt 20 ]; then
                        echo 'switch' > /tmp/self-hosted
                        rm -rf "logs/$STARTTIME/pkgretries" || true
                    fi
                    git add lists
                    git add logs
                fi
            fi
            if [ $counter -eq 25 ]; then
                echo "READY" > /tmp/write_PACKAGES
            fi
            git add logs/$STARTTIME
            git commit -m "Increment counter for empty tobuild lists"
      # tobuild is not empty
      else
            if [ -f "logs/$STARTTIME/empty_retries" ]; then
                rm logs/$STARTTIME/empty_retries
                git add logs/$STARTTIME
            fi
            git add lists
            git add tobuild.txt
            git commit -m "Adding tobuild list"
      fi
      git push
fi
