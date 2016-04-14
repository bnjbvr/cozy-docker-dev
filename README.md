Cozy Dev Dockerfile
===================

This is an unofficial dev dockerfile for CozyCloud.

## Security

DON'T USE IN PRODUCTION.

DON'T FORGET TO CLOSE THE CONTAINER.

KNOW WHAT YOU'RE DOING.

## Install steps

These steps are meant to be run only once.

* Install [Docker](https://www.docker.com/). This recipe has been tested on **Docker v1.11**.
* Build the image:

`./build.sh`

* Go grab yourself a coffee.
* Make sure to have at least one RSA public key in your `~/.ssh` called
  `id_rsa.pub`. This key will be copied into the container to be able to SSH
  without password into it. (If some haters come around and say "hell no, this
  is not the docker way", please go to the pull requests tab of this repo and
  submit a better solution :-))
* Run a container, once the image is ready to use:

`./start.sh`

## Run steps

These steps are needed every time you want to use the image in development:

* Make sure the same container is running (using `docker restart $ID_CONTAINER`
  -- the id can be found thanks to `docker ps -a`).
* Create the port forwarding between the host and the container, thanks to
  `index.js`. If your app is going to run on port 1337, use this command:

  ```./index.js /path/to/my/app/package.json 1337```

* In another terminal, start your app on the same port:

  ```cd /path/to/my/app && PORT=1337 npm start```

* Then, you can access the following web ui:

    * the cozy ui at `https://localhost:8000`
    * mailcatcher at `http://localhost:8001`

* Once you're done with coding, hit `Ctrl+C` in both terminals.
