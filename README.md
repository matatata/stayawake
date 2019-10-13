# Stayawake

Examples:

## Listening mode
`stayawake -t /some/program/toTestIfSleepShouldBePrevented.sh` will simply run and wait, but will call the script `/some/program/toTestIfSleepShouldBePrevented.sh` whenever the darwin notification `org.github.matatata.stayawake.notify` is received. If the script returns `1`, then a power management assertion of type "NetworkClientActive" is created. This will prevent macOS from sleeping. If the script returns `0` the the assertion will be released again.

## Trigger the test
`stayawake -p` will post the notification, causing any listening `stayawake -t ...` processes to either create or remove the sleep assertion. Note that I haven't tested this with multiple instances of stayawake in listening mode.

`stayawake -p -i 30` will post the notification every 30 seconds.

## Combination

`stayawake -p -i 30 -t /some/program/toTestIfSleepShouldBePrevented.sh` will post a notification every 30 seconds causing the process to test the given script and thus creating and releasing the sleep assertion accordingly.

## Tips
Add the `-v` option to see some verbose/debugging output. Also use `pmset -g assertions` to see what assertions are present.
You can use the included org.github.matatata.stayawake.plist LaunchDaemon config as a template to start the processes automatically.

## Compatibilty
To my knowlege and from my experience the program compiles and runs fine in EL Capitan and Mojave. I expect it to also run on other versions.




