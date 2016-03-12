#!/bin/sh

cd test-stack

for file in $( find . | grep -v '^.$' ) ; do
  echo "$ cat $file"
  cat $file
  echo ''
done
