#!/bin/bash

sudo cp ~/.ssh/id_rsa.pub ./dotssh/authorized_keys
sudo chown root:root ./dotssh/authorized_keys

docker run -ti \
    -p 8000:443 \
    -p 5984:5984 \
    -p 9101:9101 \
    -p 9104:9104 \
    -p 8001:8001 \
    -p 2222:22 \
    -v $(pwd)/dotssh:/root/.ssh \
    cozy/dev
