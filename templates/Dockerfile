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


FROM debian:latest as terratest_log_parser
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates openssl 
RUN curl -OLs https://github.com/gruntwork-io/terratest/releases/download/v0.17.5/terratest_log_parser_linux_amd64 && \
  chmod +x terratest_log_parser_linux_amd64 && \
  mv terratest_log_parser_linux_amd64 /usr/local/bin/terratest_log_parser

FROM hashicorp/terraform:${TERRAFORM_VERSION} AS terratest_base_image
RUN apk add --no-cache bash
ENV LOCK_TIMEOUT_SECONDS=300
ENV STACK_INSTANCE_NAME_FINAL=""
ENV STACK_INSTANCE_NAME="${STACK_INSTANCE_NAME}"
ENV TERRAFORM_PROVIDER="${TERRAFORM_PROVIDER}"
ENV TERRAFORM_BACKEND="${TERRAFORM_BACKEND}"

FROM terratest_base_image AS package
ADD  .ssh/                                 /root/.ssh/
ADD  credentials_provider.conf             /opt/terraform/credentials_provider.conf
ADD  credentials_backend.conf              /opt/terraform/credentials_backend.conf
ADD  environment_variables.conf            /opt/environment_variables.conf
ADD  templates/                            /opt/templates
ADD  scripts/                              /opt/scripts
ADD  src/                                  /opt/src
ADD  test/                                 /opt/test

FROM golang:1.20 as final
COPY --from=terratest_log_parser /usr/local/bin/terratest_log_parser /usr/local/bin/terratest_log_parser
COPY --from=terraform-cli             /workspace/terraform /usr/local/bin/terraform
COPY --from=package /opt/            /opt/
COPY --from=package /root/.ssh/     /root/.ssh/

RUN mkdir -p /opt/test/result && \
    chmod 600 /root/.ssh/config 

WORKDIR /opt/test

RUN go mod download

ENTRYPOINT [ "/opt/scripts/entrypoint.sh" ]