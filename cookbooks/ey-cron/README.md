ey-cron
========

Sets up cron jobs specific to the EY Stack on top of whatever ones are defined on the AMI:

 - sets env variables `PATH`, `RAILS_ENV`, `RACK_ENV` on both `root`'s and user's crontab
 - adds cronjob for executing `ey-snapshot`.
 - adds cronjobs that were configured through the web UI.
 - adds cronjob to monitor/restart `ntp`

