Cozy Dev Dockerfile
===================

This is an unofficial dev dockerfile for CozyCloud.

## Security

DON'T USE IN PRODUCTION.

DON'T FORGET TO CLOSE THE CONTAINER.

READ ALL THE STEPS BEFORE YOU START.

KNOW WHAT YOU'RE DOING.

## Install steps

These steps are meant to be run only once.

* Install [Docker](https://www.docker.com/). This recipe has been tested on **Docker v1.11**.
* Install node dependencies:

  `npm i`

* Build the image:

  `./build.sh`

* Go grab yourself a coffee.
    * Note that errors like `Cannot uninstall an application not installed`
      should actually be warnings and don't matter too much at this point.
    * That being said, the installation of mailcatcher may need some retries,
      so if you see an error saying that `rubygems` can't be found, just
      relaunch `./build.sh` until it works.
* Make sure to have at least one RSA public key in your `~/.ssh` called
  `id_rsa.pub`. This key will be copied into the container to be able to SSH
  into it without a password. (If some haters come around and say "hell no,
  this is not the docker way", please go to the pull requests tab of this repo
  and submit a better solution :-))
* Run a container, once the image is ready to use:

  `./spawn.sh`

Note that it can take up to 2 minutes (on my local machine) before I can reach
the home page, because the init script may take some time to set up the Cozy
stack.

Also, because the certificates generated are self-signed, you **will** get a
warning from your web browser when going to your development environment. If
you don't get a warning, say farewell to bad choices in your life and consider
downloading a [better browser](https://www.mozilla.org/en-US/firefox/new/).

## Run steps

These steps are needed every time you want to use the image in development:

* Restart the container with `./start.sh` or by hand: the container is named
  `cozy-dev` by default (see in `spawn.sh`).
* Create the port forwarding between the host and the container, thanks to
  `index.js`. If your app is going to run on port 1337, use this command:

  ```./index.js /path/to/my/app/package.json 1337```

* In another terminal, start your app on the same port:

  ```cd /path/to/my/app && PORT=1337 npm start```

* Then, you can access the following web ui:

    * the cozy ui at `https://localhost:8000`
    * mailcatcher at `http://localhost:8001`

* Once you're done with coding, hit `Ctrl+C` in both terminals.

## Addendum: How this works

Docker runs most of the software and ports are bound so that they're reachable
from the host. So far, so good. The tricky part is being able to run apps on
the host while they appear from within the docker. The hack used here is to
use SSH port tunnelling between the container and the host. That's what the JS
tool `index` is used for.


## Troubleshooting

**`sync.sh` hangs when trying to download packages.**

By default, Ubuntu will try to use IPv6 to fetch the packages it needs. If IPv6 is not available on your network, you can force the use of IPv4 by adding the following line [at the beginning of your Dockerfile](https://github.com/bnjbvr/cozy-docker-dev/blob/master/Dockerfile#L5):

  ```RUN echo 'Acquire::ForceIPv4 "true";' | tee /etc/apt/apt.conf.d/99force-ipv4```
