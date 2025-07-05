- Replication:

1. on a terminal, run ```bash start-cluster.sh``` to start cluster on docker
2. on a new terminal, run ```docker exec -it redis-client sh -c "npm run dev"``` to run the code.
3. once the keys are added, on a new terminal, run ```bash get-dbsize```.

- Availabilty:
4. once the keys are added, on a new terminal, run ```docker kill master-A``` to simulate a crash.
5. run ```bash get-dbsize``` to see changes.