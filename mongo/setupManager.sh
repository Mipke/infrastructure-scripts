# This line will produce a token used to subscribe other nodes to the swarm
docker swarm init --advertise-addr $1

# Open up the necessary ports for a manager:
ufw allow 22/tcp
ufw allow 2376/tcp
ufw allow 2377/tcp
ufw allow 7946/tcp
ufw allow 7946/udp
ufw allow 4789/udp
ufw reload
