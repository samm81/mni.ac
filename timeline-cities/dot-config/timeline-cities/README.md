# timeline-cities

this package installs the refresh wrapper, user-level systemd service, and timer for the timeline-cities application.

the application bundle lives at `~/opt/apps/timeline-cities/`. deploy it from the application repository:

```sh
DEPLOY_PATH='hostname.tld:~/opt/apps/timeline-cities' make deploy/prod
```

the bundle contains a standalone `uv` executable. uv downloads the required python version and packages on the first run, so the server needs network access.

the refresh wrapper is installed at `~/opt/scripts/refresh-timeline.bash`. the application repository does not contain this server-specific script. when called with only the application directory, it reads simple values from `.env`, adds only the options that are set, and invokes `timeline_cities.py`. it also accepts explicit `timeline_cities.py` arguments for manual runs.

copy `env.example` to `.env` and set the input and output paths. optional settings are commented out with example values. uncomment and edit them only when overriding an application default; copied configurations then remain free to receive future default changes. the service passes these values to `timeline_cities.py`; the application repository does not choose the location of the synced data.

the Google Timeline input is optional. uncomment `TIMELINE_GOOGLE_TIMELINE` when an export is available. unset values produce no corresponding arguments. `--overwrite` is enabled for unattended runs. `timeline_cities.py` stages its CSV outputs and atomically replaces the published files.

to monitor successful runs with Uptime Kuma, create a Push monitor and uncomment `TIMELINE_UPTIME_KUMA_PUSH_URL` in `.env`. the script calls that URL only after a successful refresh. if the heartbeat request fails, the service exits non-zero. keep `.env` private because the push URL contains the monitor token. `curl` must be installed on the server when push monitoring is enabled.

enable the timer after the bundle and `.env` file are ready:

```sh
systemctl --user daemon-reload
systemctl --user enable --now timeline-cities.timer
```

the timer runs at 02:45. the backup timer runs independently at 03:15.

the initial package does not install a `.path` unit. add one in the future if faster refreshes become useful. a path unit can watch the synced GPX and Google Timeline directories and start the same service after a file change. add a debounce step at that time because Syncthing can update several files in one transfer.
