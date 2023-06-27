#!/usr/bin/env fish
set caller $argv[1]

echo asyncing
sleep 1
set -U prompt_$caller (date)
kill $caller

# while true
#     echo hi &
#     sleep 1
# end
