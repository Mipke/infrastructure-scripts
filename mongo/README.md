## MongoDB

This subdirectory enables creating a MongoDB replica set via a Docker swarm
cluster.

1. (Prerequisite) git clone this project to target machines and cd into the mongo directory

2. First create a Docker swarm. Run `setupWorker.sh` on the first node to make it
the cluster's first manager node:
    
    `./setupManager.sh <NODE IP ADDRESS>`

3. Next setup the other nodes to be workers. Use the token generated in step 1
to authenticate the worker nodes with the manager:

    `./setupWorker.sh <TOKEN> <MANAGER NODE IP ADDRESS>`

4. Next we will label each of the nodes (from the manager). This is important as it will allow 
us to pin each running instance of mongo to a particular node. The name of each node is the hostname
of the corresponding node found in the output of `docker node ls`:

    ```
   docker node update --label-add mongo.replica=1 $(docker node ls -q -f name=manager1)
   docker node update --label-add mongo.replica=2 $(docker node ls -q -f name=worker1)
   docker node update --label-add mongo.replica=3 $(docker node ls -q -f name=worker2)
   ... so on and so forth
    ```

5. Create a network overlay for the replicas to communicate with each other:

    `docker network create --driver overlay --internal mongo`
    
6. Be sure to set the root user password inside of `mongod.env`
(This file can be deleted once the service starts on the swarm):

    `nano mongodb.env`
    
7. Next create a key to encrypt communication between the replicas. To do this, deploy a stack
whose only purpose is to maintain the authentication key used to authentication replicas:

    `docker stack deploy --compose-file mongo-keys-dc.yml mongo-keys-stack`
    
8. Next ensure the details within `docker-compose.yml` are accurate. (Paths to attached
 volumes and such) Then deploy the replica set by running:

    `docker stack deploy --compose-file docker-compose.yml mongo-stack`

#### Resources
- https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/
- https://www.digitalocean.com/community/tutorials/how-to-configure-the-linux-firewall-for-docker-swarm-on-ubuntu-16-04
- https://www.digitalocean.com/community/tutorials/how-to-create-a-cluster-of-docker-containers-with-docker-swarm-and-digitalocean-on-ubuntu-16-04
- https://medium.com/@kalahari/running-a-mongodb-replica-set-on-docker-1-12-swarm-mode-step-by-step-a5f3ba07d06e
- https://docs.docker.com/engine/swarm/stack-deploy/
- https://github.com/willitscale/learning-docker/tree/master/tutorial-12