FROM golang:1.13

COPY LICENSE README.md /

COPY src/deps.sh /deps.sh
RUN /deps.sh && \
    apt update && \
    apt install -y parallel

COPY src/hrval.sh /usr/local/bin/hrval.sh
COPY src/hrval-all.sh /usr/local/bin/hrval

ENTRYPOINT ["hrval"]
