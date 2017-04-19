#!/bin/bash

# Loop all directories inside the current directory and call 'git pull'

for dir in */
do
  dir=${dir%*/}
  cd ${dir##*/}

  echo Pull ${dir##*/}
  git pull

  cd ..
done