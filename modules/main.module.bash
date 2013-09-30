#!/bin/bash

# Displays a default message, useful in case of a failure
function failed {
  echo $1;
  exit 1;
}

# Finds a group of files and applies them in the script
# $1 -> file_delimiter
function apply_file_type() {
  for current_file in $( find ./ -iname $1 ); do
    . $current_file || failed "Failed to retrieve the files, exitting! ($1)";
  done;
}
