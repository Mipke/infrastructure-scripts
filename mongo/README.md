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
   docker node update --label-add mongo.replica=1 mongo1
   docker node update --label-add mongo.replica=2 mongo2
   docker node update --label-add mongo.replica=3 mongo3
   ... so on and so forth
    ```
    
5. Be sure to set the root user password inside of `mongod.env`
(This file can be deleted once the service starts on the swarm):

    `nano mongodb.env`
    
6. Next it is necessary to create a key to encrypt communication between the replicas and to put this key on each 
of the nodes in the swarm:

    ```
   cd ~ && mkdir mongo-conf
   nano mongo_replica_keys.yml
   ```
   
   Make the contents of mongo_replica_keys.yml:
   
   ```
   - <SOME RANDOM REALLY LONG STRING>
   ```
   
   Set permissions on the new file (mongo is very particular):
   
   ```
   chmod 600 mongo_replica_keys.yml
   chown 999 mongo_replica_keys.yml
   ```
   
   Create the same directory and file on each of the other nodes. Copy/paste the contents of the first node's 
   file contents so that all nodes have the same set of keys. Be sure to also permission each node's file.
    
7. Next ensure the details within `docker-compose.yml` are accurate. (Paths to attached
 volumes and such) Then deploy the replica set by running:

    `docker stack deploy --compose-file docker-compose.yml mongo-stack`
    
8. Initiate the replica set from a mongo shell:

    ```
   mongosh "mongodb://<ROOT USER>:<ROOT PASSWORD>@<MONGO1 HOST>:27017/?replSet=rs0"
   rs.initiate(
       {
          "_id":"rs0",
          "members":[
             {
                "_id":0,
                "host":"<MONGO1 HOST>:27017"
             },
             {
                "_id":1,
                "host":"<MONGO2 HOST>:27018"
             },
             {
                "_id":2,
                "host":"<MONGO3 HOST>:27019"
             }
          ]
       }
   );
   ```

9. Prioritize the first node to have priority as the primary mongo node (from the same mongo shell as the last
step):

    ```
    conf = rs.config();
    conf.members[0].priority = 2;
    rs.reconfig(conf);
    ```
    
10. In the mongo shell, now create an additional user to act as the cluster admin:

    ```
    use admin;
    db.createUser({user: "cluster_admin",pwd: "password",roles: [ { role: "userAdminAnyDatabase", db: "admin" },  { "role" : "clusterAdmin", "db" : "admin" } ]});
    ```
    
11. In the mongo shell, authenticate as the new cluster admin and create a user for the desired app database:

    ```
    use my_data;
    db.createUser({user: "my_user",pwd: "password",roles: [ { role: "readWrite", db: "my_data" } ]});
    ```
    
12. Now you should be able to connect to the replica set from a mongo shell with a URI like this:

    `mongodb://my_user:password@<MONGO1 HOST>:27017,<MONGO2 HOST>:27018,<MONGO3 HOST>:27019/my_data?replicaSet=rs0`
    
13. Optionally, you can loop back and make the worker swarm nodes managers as well to increase the resiliency of
the replica set:

    `docker node promote <NODE NAME>` or `docker node update --role manager <NODE NAME>`

#### Resources
- https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/
- https://www.digitalocean.com/community/tutorials/how-to-configure-the-linux-firewall-for-docker-swarm-on-ubuntu-16-04
- https://www.digitalocean.com/community/tutorials/how-to-create-a-cluster-of-docker-containers-with-docker-swarm-and-digitalocean-on-ubuntu-16-04
- https://medium.com/@kalahari/running-a-mongodb-replica-set-on-docker-1-12-swarm-mode-step-by-step-a5f3ba07d06e
- https://docs.docker.com/engine/swarm/stack-deploy/
- https://github.com/willitscale/learning-docker/tree/master/tutorial-12