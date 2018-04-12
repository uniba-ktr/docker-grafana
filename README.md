[![CircleCI](https://circleci.com/gh/uniba-ktr/docker-grafana.svg?style=svg)](https://circleci.com/gh/uniba-ktr/docker-grafana)

[![](https://images.microbadger.com/badges/version/unibaktr/grafana.svg)](https://microbadger.com/images/unibaktr/grafana "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/unibaktr/grafana.svg)](https://microbadger.com/images/unibaktr/grafana "Get your own image badge on microbadger.com")

# Grafana Docker image

This project builds a multiarch Docker image for Grafana.

## Supported Architectures

This multiarch image supports `amd64`, `i386`, `arm32v5`, `arm32v7`, and `arm64v8` on Linux

## Running your Grafana container

Start your container binding the external port `3000`.

```
docker run -d --name=grafana -p 3000:3000 unibaktr/grafana
```

Try it out, default admin user is admin/admin.

In case port 3000 is closed for external clients or there is no access
to the browser - you may test it by issuing:
  curl -i localhost:3000/login
Make sure that you are getting "...200 OK" in response.
After that continue testing by modifying your client request to grafana.

## Configuring your Grafana container

All options defined in conf/grafana.ini can be overriden using environment
variables by using the syntax `GF_<SectionName>_<KeyName>`.
For example:

```
docker run \
  -d \
  -p 3000:3000 \
  --name=grafana \
  -e "GF_SERVER_ROOT_URL=http://grafana.server.name" \
  -e "GF_SECURITY_ADMIN_PASSWORD=secret" \
  unibaktr/grafana
```

You can use your own grafana.ini file by using environment variable `GF_PATHS_CONFIG`.

More information in the grafana configuration documentation: http://docs.grafana.org/installation/configuration/

## Grafana container with persistent storage (recommended)

```
# create a persistent volume for your data in /var/lib/grafana (database and plugins)
docker volume create grafana-storage

# start grafana
docker run \
  -d \
  -p 3000:3000 \
  --name=grafana \
  -v grafana-storage:/var/lib/grafana \
  unibaktr/grafana
```

Note: An unnamed volume will be created for you when you boot Grafana,
using `docker volume create grafana-storage` just makes it easier to find
by giving it a name.

## Installing plugins for Grafana

Pass the plugins you want installed to docker with the `GF_INSTALL_PLUGINS` environment variable as a comma seperated list. This will pass each plugin name to `grafana-cli plugins install ${plugin}`.

```
docker run \
  -d \
  -p 3000:3000 \
  --name=grafana \
  -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" \
  unibaktr/grafana
```

## Building a custom Grafana image with pre-installed plugins

The `custom/` folder includes a `Dockerfile` that can be used to build a custom Grafana image.  It accepts `GRAFANA_VERSION` and `GF_INSTALL_PLUGINS` as build arguments.

Example of how to build and run:
```bash
cd custom
docker build -t grafana:latest-with-plugins \
  --build-arg "GRAFANA_VERSION=latest" \
  --build-arg "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" .
docker run \
  -d \
  -p 3000:3000 \
  --name=grafana \
  grafana:latest-with-plugins
```
