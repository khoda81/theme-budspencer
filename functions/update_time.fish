set -U time_updator_pid %self

while true
    sleep (math max\((date +%s) + 1 - (date +%s.%N)\, 0\))
    set -U time (date +%s)

    if [ $time_updator_pid != %self ]
        # TODO: don't break out of the loop and activate when the current updator is dead
        break
    end
end
