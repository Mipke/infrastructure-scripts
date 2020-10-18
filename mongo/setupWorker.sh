# Open up the necessary ports for a worker:
ufw allow 22/tcp
ufw allow 2376/tcp
ufw allow 7946/tcp
ufw allow 7946/udp
ufw allow 4789/udp
ufw reload

docker swarm join --token $1 $2:2377
