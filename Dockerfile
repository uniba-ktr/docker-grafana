ARG IMAGE_TARGET=debian:stretch-slim
ARG BUILD_BASE

# first image to download qemu and make it executable
FROM ${BUILD_BASE} AS qemu
ARG QEMU=x86_64
ARG QEMU_VERSION=v2.11.0
ADD https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VERSION}/qemu-${QEMU}-static /qemu-${QEMU}-static
RUN chmod +x /qemu-${QEMU}-static


FROM ${IMAGE_TARGET}
ARG QEMU=x86_64
COPY --from=qemu /qemu-${QEMU}-static /usr/bin/qemu-${QEMU}-static
ARG ARCH=amd64
ARG XGO_ARCH=amd64
ARG GRAFANA_VERSION="latest"
ARG GRAFANA_URL="https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-$GRAFANA_VERSION.linux-x64.tar.gz"
ARG GF_UID="472"
ARG GF_GID="472"

ENV PATH=/usr/share/grafana/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

COPY --from=qemu /build/grafana-linux-${CADVISOR_ARCH} /usr/bin/grafana

RUN apt-get update && apt-get install -qq -y tar libfontconfig curl ca-certificates && \
    mkdir -p "$GF_PATHS_HOME/.aws" && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -r -g $GF_GID grafana && \
    useradd -r -u $GF_UID -g grafana grafana && \
    mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
             "$GF_PATHS_PROVISIONING/dashboards" \
             "$GF_PATHS_LOGS" \
             "$GF_PATHS_PLUGINS" \
             "$GF_PATHS_DATA" && \
    cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" && \
    cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml && \
    chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" && \
    chmod 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS"

EXPOSE 3000

COPY ./run.sh /run.sh

USER grafana
WORKDIR /
ENTRYPOINT [ "/run.sh" ]

LABEL de.uniba.ktr.grafana.version=$VERSION \
      de.uniba.ktr.grafana.name="grafana" \
      de.uniba.ktr.grafana.docker.cmd="docker run -d --name=grafana -p 3000:3000 unibaktr/grafana" \
      de.uniba.ktr.grafana.vendor="Marcel Grossmann" \
      de.uniba.ktr.grafana.architecture=$ARCH \
      de.uniba.ktr.grafana.vcs-ref=$VCS_REF \
      de.uniba.ktr.grafana.vcs-url=$VCS_URL \
      de.uniba.ktr.grafana.build-date=$BUILD_DATE
