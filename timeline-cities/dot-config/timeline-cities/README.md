# timeline-cities

this package installs the user-level systemd service and timer for the timeline-cities application.

the application bundle lives at `~/opt/apps/timeline-cities/`. deploy it from the application repository:

```sh
DEPLOY_PATH='hostname.tld:~/opt/apps/timeline-cities' make deploy/prod
```

the bundle contains a standalone `uv` executable. uv downloads the required python version and packages on the first run, so the server needs network access.

set `TIMELINE_DATA_DIRECTORY` in this directory's `env` file. the application repository does not choose the location of the synced data.

enable the timer after the bundle and environment file are ready:

```sh
systemctl --user daemon-reload
systemctl --user enable --now timeline-cities.timer
```

the timer runs at 02:45. the backup timer runs independently at 03:15.

the initial package does not install a `.path` unit. add one in the future if faster refreshes become useful. a path unit can watch the synced GPX and Google Timeline directories and start the same service after a file change. keep the wrapper's settle delay because Syncthing can update several files in one transfer.
