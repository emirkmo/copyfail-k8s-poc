ARG PROBE_BASE_IMAGE=registry.example.com/lab/copyfail-safe-observer@sha256:<digest>

FROM ubuntu:24.04 AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential \
       binutils \
       linux-libc-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Copy your mutator source here.
# Do not copy it into the runtime stage.
COPY . /src

# Build command goes here.
# Example placeholder only:
RUN make

FROM ${PROBE_BASE_IMAGE} AS runtime

# Copy only the final binary.
COPY --from=builder /src/path/to/mutator /usr/local/bin/mutator

USER observer
WORKDIR /copyfail-probe

ENTRYPOINT ["/usr/local/bin/mutator"]