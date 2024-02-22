# Docker - Experience Builder Developer Edition

This repository contains the Docker sources to run ESRI's *ArcGIS Experience Builder Developer Edition* with *docker compose* in a Linux environment.

Esri instructions for installing are [here](https://developers.arcgis.com/experience-builder/guide/install-guide/).

**Supported version**: *Experience Builder Developer Edition*, `1.13` (November 2023).

***Node.js*** is a requirement for *Experience Builder Developer Edition* and the *Dockerfile* uses the version `20`.

:bulb: The repository is based on/inspired by this [tuto](https://www.spatial-innovation.co.nz/post/using-docker-to-speed-experience-builder-development) and [Wildsong's github repository](https://github.com/Wildsong/docker-experience-builder/tree/master).

## Prerequisites

* A Linux server with an Apache web server or a local Linux/MacOS environment.
* [A Docker](https://docs.docker.com/engine/install/) and [docker compose](https://docs.docker.com/compose/install/linux/) installation.
* An *ArcGIS Enterprise Portal* platform or an *ArcGIS Online* "organization" account.

## Set up

### Clone the repository

* Clone this repository:

```bash
git clone git@github.com:smartorigin/docker-experience-builder-dev-ed.git
```

### Download and unzip the Experience Builder sources

* Download [Experience Builder Dev Edition v.1.13](https://developers.arcgis.com/experience-builder/guide/downloads/) in the same folder as your `Dockerfile` and `docker-compose.yml` files.

* Unzip the downloaded file. When you are done there should be a folder called `ArcGISExperienceBuilder` in the same folder as your `Dockerfile` and `docker-compose.yml` files.

```bash
unzip arcgis-experience-builder-1.13.zip
```

### Choose your environment

#### Run the app locally on your machine (for devs)

* You can run *ExB Dev Ed* locally on your machine (Linux/MacOS) on https://localhost:3001.
* :bulb: To avoid cross-domain errors, you will need to [authorize *ExB Dev Ed*](https://enterprise.arcgis.com/en/portal/11.0/administer/windows/restrict-cross-domain-requests-to-your-portal.htm) on your *ArcGIS Enterprise Portal* or *ArcGIS Online*. On your *local* env, modify the `/etc/hosts` file as following:

```bash
## Open and edit the file
sudo nano /etc/hosts/
## Add the following entry to the file
## where "myexbdeved.example.com" is the custom local domain name 
## that needs to be also added to your Portal for ArcGIS or Arcgis Online
## in Organization > Settings > Security -> Allow Origins: https://myexbdeved.example.com:3001
127.0.0.1 myexbdeved.example.com
```

#### Run the app on a server

* On a server env, configure Apache with reverse proxy to https://localhost:3001.
* Here is a reverse proxy config example for Apache Vhost (443). This configuration snippet should be adapted to your specific environment: replace *IP* in `IP:443` with your actual IP address :

```bash
<VirtualHost IP:443>

  # Other config: servername, SSL, etc.
  # ...
  # ...

  # Configure reverse proxy and forward requests to docker container
  ProxyPass /.well-known !

  # Proxy to https server 
  SSLProxyEngine On
  SSLProxyCheckPeerCN Off
  SSLProxyCheckPeerName Off
  SSLProxyVerify none

  ProxyPreserveHost On        

  ProxyPass "/"  "https://localhost:3001/"
  ProxyPassReverse "/"  "https://localhost:3001/"
</VirtualHost>
```

* Keep in mind that the SSL configuration (certificates and keys) must also be properly set up in the Apache configuration for HTTPS to work correctly.

### Set up docker environment

#### Modify the Docker env variables

* Copy and modify the `.env.sample` file to match your environment:

```bash
cp .env.sample .env && nano .env
```

* `EXB_USER` is the UID of the user that will be created in the container. On a Linux server, to avoid writing permissions, use the same UID as the Linux (docker) user running on your system, e.g., if your Linux UID is 1001, set the `EXB_USER` to 1001.
* `EXB_PORT_HTTP` is the http port exposed on the machine, by default `3000`.
* `EXB_PORT_HTTPS` is the https port exposed on the machine, by default `3001`.

#### Create the Docker Volumes directories

* This step is necessary only if your Docker compose configuration specifically refers to these directories as external volumes.
* Docker compose uses 3 volumes: `public`, `themes` and `widgets`.
* To make sure you have `rw` permissions inside the Docker volumes, create them beforehand:

```bash
mkdir -p volumes/{public,themes,widgets}
```

#### Run docker compose

* Create the container and build the app with the following command (the command `docker-compose up -d` might be `docker compose up -d` depending on the Docker Compose version and installation method):

```bash
docker-compose up -d
```

* Stop the container:

```bash
docker-compose down
```

* Rebuild the project:

```bash
docker-compose down --rmi all
docker-compose up -d
### OR ### 
docker-compose up -d --build --force-recreate exb
```

## Portal (or ArcGIS Online) set up

### Register App with your ArcGIS platform

* See the [official docs](https://developers.arcgis.com/experience-builder/guide/install-guide/#create-client-id-using-arcgis-online-or-arcgis-enterprise).
* Once *EXB Dev Ed* is up and running you still have to connect it to an Esri server.
* Go to either your ArcGIS Enterprise Portal or your ArcGIS.com developer account to create a new `AppId`.

   * In your *Portal for ArcGIS*:
     * `Content tab->My Content`,
     * `Add Item->Application`,
     * `Type of application`: *Other application*,
     * `Title`: whatever you like,
     * `Tags`: whatever you like.

     * Then go into the settings of the newly created application:
        * Add your `URL`: https://mydomainname.com or if you modified your `/etc/hosts`: https://myexbdeved.example.com:3001, 
        * Go into `Update` and add as `Redirect URI` the same URL from the step above. Depending on your ArcGIS Portal configuration you may need to add a second URL: https://mydomainname.com/jimu-core/oauth-callback.html.
        * That gets you the `AppId`. Retrieve it for the EXB login web page (see next step).

* Connect to *EXB Dev Ed* from a browser (e.g. https://myexbdeved.example.com:3001/) and enter the URL of your server (Portal or ArcGIS.com) and the `AppId` you just created.

### Change the AppId

* To change the client ID later, you may have to delete `signininfo.json`
file from the Docker and restart it.
* With the docker running, change directory to the dir containing the `docker-compose.yml` file:

```bash
# Replace exb-dev-ed-docker-exb-1 with your exb container name
# docker compose ps to get the name of the container
docker exec -it exb-dev-ed-docker-exb-1 rm public/signin-info.json
```

* Alternatively, you can directly delete the `signin-info.json` file, outside the container, in the `volume/public/` folder.

* Then refresh the browser connection to *EXB Dev Ed* and it should prompt again for `AppId`.

## Security Notice

:shield: Make sure to secure the Docker environment and Apache configuration, especially when exposing services over the internet.:shield:

For example, if you are using UFW on your system, there is a security issues with Docker. Take a look at [this fix](https://github.com/chaifeng/ufw-docker).