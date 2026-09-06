ARG EE_BASE_IMAGE="quay.io/centos/centos:stream9"
ARG PYCMD="/usr/bin/python3.12"
ARG PYPKG="python3.12 python3.12-pip python3.12-devel"
ARG PKGMGR_PRESERVE_CACHE=""
ARG ANSIBLE_GALAXY_CLI_COLLECTION_OPTS=""
ARG ANSIBLE_GALAXY_CLI_ROLE_OPTS=""
ARG ANSIBLE_INSTALL_REFS="ansible-core>=2.17,<2.18 ansible-runner"
ARG PKGMGR="/usr/bin/dnf"

# Base build stage
FROM $EE_BASE_IMAGE AS base
USER root
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ARG EE_BASE_IMAGE
ARG PYCMD
ARG PYPKG
ARG PKGMGR_PRESERVE_CACHE
ARG ANSIBLE_GALAXY_CLI_COLLECTION_OPTS
ARG ANSIBLE_GALAXY_CLI_ROLE_OPTS
ARG ANSIBLE_INSTALL_REFS
ARG PKGMGR

COPY _build/scripts/ /output/scripts/
COPY _build/scripts/entrypoint /opt/builder/bin/entrypoint
RUN $PKGMGR install -y dnf-plugins-core && $PKGMGR config-manager --set-enabled crb || true
RUN $PKGMGR install $PYPKG -y ; if [ -z $PKGMGR_PRESERVE_CACHE ]; then $PKGMGR clean all; fi
RUN /output/scripts/pip_install $PYCMD
RUN $PYCMD -m pip install --no-cache-dir $ANSIBLE_INSTALL_REFS

# Galaxy build stage
FROM base AS galaxy
ARG EE_BASE_IMAGE
ARG PYCMD
ARG PYPKG
ARG PKGMGR_PRESERVE_CACHE
ARG ANSIBLE_GALAXY_CLI_COLLECTION_OPTS
ARG ANSIBLE_GALAXY_CLI_ROLE_OPTS
ARG ANSIBLE_INSTALL_REFS
ARG PKGMGR

ADD _build/configs/ansible.cfg /etc/ansible/ansible.cfg
RUN /output/scripts/check_galaxy
COPY _build /build
WORKDIR /build

RUN mkdir -p /usr/share/ansible
RUN ansible-galaxy role install $ANSIBLE_GALAXY_CLI_ROLE_OPTS -r requirements.yml --roles-path "/usr/share/ansible/roles"
RUN ANSIBLE_GALAXY_DISABLE_GPG_VERIFY=1 ansible-galaxy collection install $ANSIBLE_GALAXY_CLI_COLLECTION_OPTS -r requirements.yml --collections-path "/usr/share/ansible/collections"

# Builder build stage
FROM base AS builder
ENV PIP_BREAK_SYSTEM_PACKAGES=1
WORKDIR /build
ARG EE_BASE_IMAGE
ARG PYCMD
ARG PYPKG
ARG PKGMGR_PRESERVE_CACHE
ARG ANSIBLE_GALAXY_CLI_COLLECTION_OPTS
ARG ANSIBLE_GALAXY_CLI_ROLE_OPTS
ARG ANSIBLE_INSTALL_REFS
ARG PKGMGR

RUN $PYCMD -m pip install --no-cache-dir bindep pyyaml packaging

COPY --from=galaxy /usr/share/ansible /usr/share/ansible

COPY _build/requirements.txt requirements.txt
COPY _build/bindep.txt bindep.txt
RUN $PYCMD /output/scripts/introspect.py introspect --user-pip=requirements.txt --user-bindep=bindep.txt --write-bindep=/tmp/src/bindep.txt --write-pip=/tmp/src/requirements.txt
RUN /output/scripts/assemble

# Final build stage
FROM base AS final
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ARG EE_BASE_IMAGE
ARG PYCMD
ARG PYPKG
ARG PKGMGR_PRESERVE_CACHE
ARG ANSIBLE_GALAXY_CLI_COLLECTION_OPTS
ARG ANSIBLE_GALAXY_CLI_ROLE_OPTS
ARG ANSIBLE_INSTALL_REFS
ARG PKGMGR

RUN /output/scripts/check_ansible $PYCMD

COPY --from=galaxy /usr/share/ansible /usr/share/ansible

COPY --from=builder /output/ /output/
RUN /output/scripts/install-from-bindep && rm -rf /output/wheels
RUN chmod ug+rw /etc/passwd
RUN mkdir -p /runner && chgrp 0 /runner && chmod -R ug+rwx /runner
WORKDIR /runner
RUN $PYCMD -m pip install --no-cache-dir 'dumb-init==1.2.5'
RUN set -eux; \
  ARCH="$(uname -m)"; \
  case "$ARCH" in \
    x86_64)  TOFU_ARCH=amd64 ;; \
    aarch64) TOFU_ARCH=arm64 ;; \
    *) echo "unsupported arch: $ARCH" >&2; exit 1 ;; \
  esac; \
  curl -fsSL -o /tmp/tofu.tar.gz \
    "https://github.com/opentofu/opentofu/releases/download/v1.8.8/tofu_1.8.8_linux_${TOFU_ARCH}.tar.gz"; \
  tar -xzf /tmp/tofu.tar.gz -C /usr/local/bin tofu; \
  chmod 0755 /usr/local/bin/tofu; \
  rm -f /tmp/tofu.tar.gz; \
  ln -sf /usr/local/bin/tofu /usr/local/bin/terraform

RUN mkdir -p /opt/tofu/plugin-cache /opt/tofu/data && chgrp -R 0 /opt/tofu && chmod -R g=u /opt/tofu
ENV TF_PLUGIN_CACHE_DIR=/opt/tofu/plugin-cache
ENV TF_DATA_DIR=/opt/tofu/data
ENV TF_IN_AUTOMATION=1
ENV TF_INPUT=0
ENV TF_CLI_ARGS_plan="-lock-timeout=300s"
ENV TF_CLI_ARGS_apply="-lock-timeout=300s"
RUN $PKGMGR clean all && rm -rf /var/cache/dnf /root/.cache
RUN /usr/bin/python3.12 --version
RUN ansible --version | grep -E 'python version = 3\.12'
RUN tofu version
RUN ansible-galaxy collection list 2>/dev/null | grep -E 'cloud\.terraform'
RUN rm -rf /output
LABEL ansible-execution-environment=true
USER 1000
ENTRYPOINT ["/opt/builder/bin/entrypoint", "dumb-init"]
CMD ["bash"]
