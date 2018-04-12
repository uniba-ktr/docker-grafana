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
ARG GF_UID="472"
ARG GF_GID="472"
ARG VERSION=master

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

COPY --from=qemu /build/grafana-server-linux-${XGO_ARCH} /usr/sbin/grafana-server
COPY --from=qemu /usr/share/grafana/conf/defaults.ini    /usr/share/grafana/conf/defaults.ini
COPY --from=qemu /etc/grafana/ldap.toml                  /etc/grafana/ldap.toml
COPY --from=qemu /etc/grafana/grafana.ini                /etc/grafana/grafana.ini
COPY --from=qemu /usr/share/grafana/public               /usr/share/grafana/public
COPY --from=qemu /usr/share/grafana/scripts              /usr/share/grafana/scripts
COPY --from=qemu /usr/share/grafana/vendor               /usr/share/grafana/vendor

COPY ./run.sh /run.sh

# TODO: Build with ca-certificates takes too long
RUN apt-get -q update && apt-get install -y --no-install-recommends libfontconfig curl file && \
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
    chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" /run.sh && \
    chmod 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" && \
    chmod +x /run.sh

EXPOSE 3000

USER grafana
WORKDIR /
ENTRYPOINT [ "/run.sh" ]

LABEL de.uniba.ktr.grafana.version=$VERSION \
      de.uniba.ktr.grafana.name="grafana" \
      de.uniba.ktr.grafana.docker.cmd="docker run -d --name=grafana  -e \"GF_SECURITY_ADMIN_PASSWORD=secret\" -p 3000:3000 unibaktr/grafana" \
      de.uniba.ktr.grafana.vendor="Marcel Grossmann" \
      de.uniba.ktr.grafana.architecture=$ARCH \
      de.uniba.ktr.grafana.vcs-ref=$VCS_REF \
      de.uniba.ktr.grafana.vcs-url=$VCS_URL \
      de.uniba.ktr.grafana.build-date=$BUILD_DATE
