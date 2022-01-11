# rpupdate
My setup:
- Hybrid setup running in dockerized containers.
- Docker network created with: `docker network create --gateway 192.168.32.1 --subnet 192.168.32.0/24 net`
- Hybrid eth1 and eth2 containers are named `eth1` and `eth2`, with the same port config as Rocket Pool default settings.
- All containers connect to the external `net` network.
  This could be simulated by adding a `name:` to the RP stack. As an example, this would change the
  network name from `rocketpool_net` to just `net`:
```yml
networks:
  net:
    name: net
    driver: bridge
    ipam:
    ...
```
- I changed the user ID on certain containers because I prefer to not use docker volumes, and this way
  I can include them with my backups when running this script.
