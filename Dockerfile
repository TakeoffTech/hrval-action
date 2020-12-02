FROM alpine:3.12.1 AS compile-image

ENV VERSION2="2.16.7" \
    VERSION3="3.2.1" \
    BASE_URL="https://get.helm.sh"
ENV TAR_FILEV2="helm-v${VERSION2}-linux-amd64.tar.gz" \
    TAR_FILEV3="helm-v${VERSION3}-linux-amd64.tar.gz"

RUN apk add --update --no-cache curl ca-certificates bash git openssh-client && \
    curl -L ${BASE_URL}/${TAR_FILEV2} |tar xvz && \
    mv linux-amd64/helm /bin/helm && \
    chmod +x /bin/helm && \
    rm -rf linux-amd64 && \
    curl -L ${BASE_URL}/${TAR_FILEV3} |tar xvz && \
    mv linux-amd64/helm /bin/helmv3  && \
    chmod +x /bin/helmv3 && \
    rm -rf linux-amd64 && \
    curl -sL https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64 -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    curl -sL https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz | tar xz && \
    mv kubeval /bin/kubeval && \
    curl -sL https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

FROM alpine:3.12.1 AS build-image
COPY --from=compile-image /bin/helm /bin/helm
COPY --from=compile-image /bin/helmv3  /bin/helmv3 
COPY --from=compile-image /usr/local/bin/yq  /usr/local/bin/yq 
COPY --from=compile-image /bin/kubeval  /bin/kubeval 
COPY --from=compile-image /usr/local/bin/kubectl  /usr/local/bin/kubectl

COPY LICENSE README.md /

RUN apk add --update --no-cache curl ca-certificates bash git openssh-client parallel && \
    helm init --client-only --kubeconfig=$HOME/.kube/kubeconfig && \
    chmod +x /usr/local/bin/kubectl /bin/kubeval /usr/local/bin/yq /bin/helmv3 /bin/helm && \
    mkdir ~/.ssh && \
    ssh-keyscan -H github.com > ~/.ssh/known_hosts

COPY src/hrval.sh /usr/local/bin/hrval.sh
COPY src/hrval-all.sh /usr/local/bin/hrval

ENTRYPOINT ["hrval"]