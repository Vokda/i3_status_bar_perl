# i3_status_bar_perl
A status bar for i3wm
Theoretically any script can be run as a job and any output that can be expressed as text should
work. 
NOTE: This software could use more testing. 
Any feedback is welcome! :)

# Installing
1. Clone this git repo to some suitable place
2. Add bar.pl to the bar block in your i3 config. Here is an example of what my config
   `~/.i3/config` looks like 
```
bar
{
	status_command exec perl -I ~/Projects/i3_status_bar_perl/ ~/Projects/i3_status_bar_perl/bar.pl
}
```
3. Configure what jobs your status bar should be running. You can find the config file at `i3_status_bar_perl/cmds/cmds.conf`. 
4. Configure where the log files will be put. You do this under `i3_status_bar_perl/logs/conf`.
   It is not possible to not log at the moment.
5. You may need to reload i3 for it to take effect.

# Configuration
## Jobs
The configuration file is used to tell `bar.pl` which jobs to run and their scheduling.

Each line is interpreted as a perl array. (follow the examples below if you are unfamiliar with
perl arrays)

Each line should be in the structure of
('name_of_job', 'job_script', update_time => [seconds], format => 'see below', priority => [1 or higher, higher means lower priority])

First two elements of the array are mandatory. I.e. name and script name are mandatory.

update-time = 0 -> wait for signal SIGUSR1

update-time > 0 -> update every x seconds

Default values for update_time and priority is 1, i.e. update every second and lowest priority

```
('keyboard_layout', 'keyboard_layout.sh', update_time => 0, format => 'KBD[%]');
('loadavg', 'loadavg.sh', update_time => 5)
('vpn', 'is_on_vpn.sh', update_time => 0, format => 'On VPN: %')
('date_time', "date_time.sh", update_time => 1)
('gpu_temp', "gpu_temp.sh", update_time => 5, format => 'GPU %c')
('cpu_temp', "cpu_temp.sh", update_time => 5, format => 'CPU Cores 0[%c] 1[%c] 2[%c] 3[%c]')
```

### Formating
Format can be any string. 
% are special, they will be replaced with output from the job script.
One % per output of the job script. See `cpu_temp.sh` as an example.

## Logs
The logs are not filled with a lot at the moment, but will be expanded in the future.
If the job scheduling were to run very slow, warnings may be shown there.
Jobs scheduled can be seen in the beginning of the log.

# Debugging
Run `debug/test.sh` for help with debugging

# TODO
Priority actually not implremented yet.
More logging
