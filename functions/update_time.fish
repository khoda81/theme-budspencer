set -U time_updator_pid %self

while true
    sleep (math (date +%s) + 1 - (date +%s.%N))
    set -U time (date +%s)

    if [ $time_updator_pid != %self ]
        break
    end
end
