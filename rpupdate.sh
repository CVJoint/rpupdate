#!/bin/sh
# https://mikefarah.gitbook.io/yq/
MAX_GAS="150"
mkdir -p ~/bin
wget https://github.com/rocket-pool/smartnode-install/releases/latest/download/rocketpool-cli-linux-amd64 -O ~/bin/rocketpool && chmod +x ~/bin/rocketpool
mkdir -p ~/.rocketpool_backups
cp -r ~/.rocketpool ~/.rocketpool_backups/rocketpool.`date +"%Y%m%d_%H%M%S"` 2> /dev/null
rocketpool service pause -y
rocketpool service install -d -y
for file in ~/.rocketpool/docker-compose.yml; do
    yq eval 'del(.services.eth1)' -i "$file"
    yq eval 'del(.services.eth2)' -i "$file"
    yq eval 'del(.. | select(has("depends_on")).depends_on)' -i "$file"
    yq eval 'del(.volumes)' -i "$file"
    yq eval '.networks.net = .networks.net + {"external": true}' -i "$file"
    yq eval '.services.validator.volumes = .services.validator.volumes + "./data/graffiti.txt:/graffiti.txt"' -i "$file"
done
sed -i '/services:/a\
  graffiti:\
    image: ramirond/graffiti:rp\
    container_name: ${COMPOSE_PROJECT_NAME}_graffiti\
    restart: unless-stopped\
    volumes:\
      - ./data/graffiti.txt:/graffiti.txt\
    environment:\
      - ROCKET_POOL_VERSION=${ROCKET_POOL_VERSION}\
    networks:\
      - net\
    command: "--client $VALIDATOR_CLIENT --out-file /graffiti.txt --eth2-url eth2 --eth2-port 5052"' ~/.rocketpool/docker-compose.yml
for file in ~/.rocketpool/docker-compose-metrics.yml; do
    yq eval '(.services.prometheus.volumes.[] | select(. == "prometheus-data:/prometheus")) = "./data/grafana/prometheus:/prometheus"' -i "$file"
    yq eval '(.services.grafana.volumes.[] | select(. == "grafana-storage:/var/lib/grafana")) = "./data/grafana/grafana:/var/lib/grafana"' -i "$file"
    yq eval 'del(.volumes)' -i "$file"
    yq eval '.networks.net = .networks.net + {"external": true}' -i "$file"
done
sed -i '/container_name: ${COMPOSE_PROJECT_NAME}_prometheus/a\
    user: "1000:1000"' ~/.rocketpool/docker-compose-metrics.yml
sed -i '/container_name: ${COMPOSE_PROJECT_NAME}_grafana/a\
    user: "1000:1000"' ~/.rocketpool/docker-compose-metrics.yml
for file in ~/.rocketpool/docker-compose-fallback.yml; do
    yq eval '(.services.eth1-fallback.volumes.[] | select(. == "eth1fallbackclientdata:/ethclient")) = "./data/eth1fallback:/ethclient"' -i "$file"
    yq eval 'del(.volumes)' -i "$file"
    yq eval '.networks.net = .networks.net + {"external": true}' -i "$file"
done
sed -i '/container_name: ${COMPOSE_PROJECT_NAME}_eth1-fallback/a\
    user: "1000:1000"' ~/.rocketpool/docker-compose-fallback.yml
sed -e 's/\ \ \ \ exec\ \${CMD}\ --validators-graffiti="\$GRAFFITI"/\ \ \ \ exec\ \${CMD}\ --validators-graffiti-file=\/graffiti.txt/' -i  ~/.rocketpool/chains/eth2/start-validator.sh
sed -e s/rplClaimGasThreshold:\ 150/rplClaimGasThreshold:\ $MAX_GAS/ -i  ~/.rocketpool/config.yml
rocketpool service start
rocketpool service version
