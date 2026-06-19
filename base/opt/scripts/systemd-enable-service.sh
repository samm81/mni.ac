sudo systemctl enable --now compose-app@"${1:?missing directory}".service
sudo systemctl status compose-app@"${1:?missing directory}".service --no-pager
