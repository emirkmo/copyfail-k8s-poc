# syntax=docker/dockerfile:1

ARG UBUNTU_VERSION=24.04

# Stage: observer
#
# Contains:
#   - /copyfail-probe/testfile baked into the image layer
#   - /usr/local/bin/observer.sh copied from repo
FROM ubuntu:${UBUNTU_VERSION} AS observer

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       coreutils \
       ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system observer \
    && useradd \
       --system \
       --gid observer \
       --home-dir /nonexistent \
       --shell /usr/sbin/nologin \
       observer

RUN mkdir -p /copyfail-probe \
    && printf 'COPYFAIL_BASELINE_2026_LAB_ONLY\n' > /copyfail-probe/testfile \
    && chmod 0444 /copyfail-probe/testfile \
    && chown root:root /copyfail-probe/testfile

COPY observer.sh /usr/local/bin/observer.sh
RUN chmod 0555 /usr/local/bin/observer.sh

USER observer
WORKDIR /copyfail-probe

ENTRYPOINT ["/usr/local/bin/observer.sh"]


################################################################################
# Stage: mutator-builder
#
# Build-only stage.
# Contains compiler, linker, headers, and dummy mutator source.
#
# This stage is NOT the runtime image.
################################################################################

FROM ubuntu:${UBUNTU_VERSION} AS builder

LABEL copyfail.role="dummy-mutator-builder"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       binutils \
       linux-libc-dev \
       make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY copy-fail-c/ ./

RUN make vulnerable


################################################################################
# Stage: mutator
#
# Runtime mutator-shaped image.
#
# IMPORTANT:
#   This stage inherits FROM observer.
#   Therefore /copyfail-probe/testfile comes from the observer stage.
#
# It adds only:
#   - /usr/local/bin/dummy-mutator
#
# It does NOT modify:
#   - /copyfail-probe/testfile
################################################################################

FROM observer AS mutator

COPY --from=builder /src/vulnerable /usr/local/bin/dummy-mutator
# Below not actually needed, I was curious.
COPY --from=builder /src/utils.o /usr/local/bin/utils.o

USER observer
WORKDIR /copyfail-probe

ENTRYPOINT ["/usr/local/bin/dummy-mutator"]
# Technically not needed:
CMD ["/copyfail-probe/testfile"]