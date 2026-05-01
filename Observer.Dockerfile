FROM ubuntu:24.04

LABEL org.opencontainers.image.title="copyfail-safe-observer"
LABEL copyfail.role="safe-observer"
LABEL copyfail.contains_mutator="false"

RUN groupadd --system observer \
    && useradd --system --gid observer --home-dir /nonexistent --shell /usr/sbin/nologin observer

RUN mkdir -p /copyfail-probe \
    && printf 'COPYFAIL_BASELINE_2026_LAB_ONLY\n' > /copyfail-probe/testfile \
    && chmod 0444 /copyfail-probe/testfile \
    && chown root:root /copyfail-probe/testfile

COPY observer.sh /usr/local/bin/observer.sh
RUN chmod 0555 /usr/local/bin/observer.sh

USER observer
WORKDIR /copyfail-probe

ENTRYPOINT ["/usr/local/bin/observer.sh"]