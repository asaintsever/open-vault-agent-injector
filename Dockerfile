FROM golang:1.14.4 AS buildOVAI

COPY . /ovai-src
RUN cd /ovai-src && make build OFFLINE=true

FROM centos:7.9.2009 AS baseImage

# Update CentOS (note that --security flag does not work on CentOS: https://forums.centos.org/viewtopic.php?t=59369)
RUN set -x \
    && yum -y update \
    && yum clean all \
    && rm -rf /var/cache/yum

FROM scratch

USER root

# OVAI home, OVAI user/user group/user id
ENV OVAI_HOME=/opt/ovai
ENV OVAI_USER=ovai
ENV OVAI_USERGROUP=$OVAI_USER
ENV OVAI_UID=61000

COPY --from=baseImage / /

# Create non-root user $OVAI_USER
RUN set -x \
    && mkdir -p $OVAI_HOME \
    && groupadd -r $OVAI_USERGROUP -g $OVAI_UID \
    && useradd -l -u $OVAI_UID -r -g $OVAI_USERGROUP -m -d /home/$OVAI_USER -s /sbin/nologin $OVAI_USER \
    && chmod 755 /home/$OVAI_USER \
    && chmod -R "g+rwX" $OVAI_HOME \
    && chown -R $OVAI_USER:$OVAI_USERGROUP $OVAI_HOME

WORKDIR $OVAI_HOME
USER $OVAI_UID

LABEL com.ovai.maintainer="asaintsever" \
      com.ovai.name="Open Vault Agent Injector" \
      com.ovai.application="open-vault-agent-injector" \
      com.ovai.service="open-vault-agent-injector" \
      com.ovai.description="Kubernetes Webhook Admission Server for Vault Agent injection"

COPY --chown=ovai:ovai --from=buildOVAI /ovai-src/target/vaultinjector-webhook ${OVAI_HOME}/webhook/
COPY --chown=ovai:ovai --from=buildOVAI /ovai-src/target/vaultinjector-env ${OVAI_HOME}/

ENTRYPOINT ["/opt/ovai/webhook/vaultinjector-webhook"]
