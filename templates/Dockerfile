FROM debian:latest as terraform-cli
ARG TERRAFORM_VERSION
RUN apt-get update
RUN apt-get install --no-install-recommends -y curl ca-certificates unzip gnupg
WORKDIR /workspace
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN curl -Os https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig
RUN grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c -
RUN unzip -j terraform_${TERRAFORM_VERSION}_linux_amd64.zip


# Install Go and project dependencies
FROM debian:latest as go-cli
ARG TERRATEST_VERSION
WORKDIR /workspace/test
RUN apt-get update
RUN apt-get install -y --no-install-recommends golang-go git curl ca-certificates openssl
COPY /src /workspace/src
COPY /test /workspace/test

ARG cert_location=/usr/local/share/ca-certificates

RUN openssl s_client -showcerts -connect github.com:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > ${cert_location}/github.crt
RUN update-ca-certificates

RUN curl -OLs https://github.com/gruntwork-io/terratest/releases/download/v0.17.5/terratest_log_parser_linux_amd64 && \
  chmod +x terratest_log_parser_linux_amd64 && \
  mv terratest_log_parser_linux_amd64 /usr/local/bin/terratest_log_parser


FROM hashicorp/terraform:${TERRAFORM_VERSION} AS terraform_base_image
RUN apk add --no-cache bash
ENV LOCK_TIMEOUT_SECONDS=300
ENV STACK_INSTANCE_NAME_FINAL=""
ENV STACK_INSTANCE_NAME="${STACK_INSTANCE_NAME}"
ENV TERRAFORM_PROVIDER="${TERRAFORM_PROVIDER}"
ENV TERRAFORM_BACKEND="${TERRAFORM_BACKEND}"
RUN mkdir -p /opt/output/


FROM terraform_base_image AS package
ADD  .ssh/                                 /root/.ssh/
ADD  credentials_provider.conf             /opt/terraform/credentials_provider.conf
ADD  credentials_backend.conf              /opt/terraform/credentials_backend.conf
ADD  environment_variables.conf            /opt/environment_variables.conf
ADD  templates/                            /opt/templates
ADD  scripts/                              /opt/scripts
ADD  src/                                  /opt/src
ADD  test/                                 /opt/test

FROM golang:1.19 as final
LABEL maintainer="Cloud Ops Integration"

COPY --from=terraform-cli /workspace/terraform /usr/local/bin/terraform
COPY --from=go-cli /workspace /opt/go
COPY --from=go-cli /usr/local/bin/terratest_log_parser /usr/local/bin/terratest_log_parser

COPY --from=package /opt/environment_variables.conf /opt/environment_variables.conf
COPY --from=package /opt/templates/                 /opt/templates/
COPY --from=package /opt/scripts/                   /opt/scripts/
COPY --from=package /opt/src                        /opt/src
COPY --from=package /root/.ssh/                     /root/.ssh/
COPY --from=package /opt/terraform                  /opt/terraform
COPY --from=package /opt/test                       /opt/test
RUN   mkdir -p /opt/test/result

RUN chmod 600 /root/.ssh/config

WORKDIR /opt/test

ENTRYPOINT [ "/opt/scripts/entrypoint.sh" ]
