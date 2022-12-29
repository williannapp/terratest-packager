#!/bin/bash

export PATH=/opt/scripts/:${PATH}


initialization() {
  PROVIDER_CREDENTIALS_FILE="credentials_provider.conf"
  BACKEND_CREDENTIALS_FILE="credentials_backend.conf"

  if [ -e "${PROVIDER_CREDENTIALS_FILE}" ]; then
    # shellcheck disable=SC2039
    # shellcheck disable=SC1090
    source "${PROVIDER_CREDENTIALS_FILE}"

    # shellcheck disable=SC2039
    # shellcheck disable=SC1090
    source "${BACKEND_CREDENTIALS_FILE}"
  fi

  SED_REPLACE_EXPRESSION=$(printf '/  backend/{r %s' "/opt/templates/backend/${TERRAFORM_BACKEND}/backend.hcl")

  # Change backend config from local to a new one
  sed -i -e "${SED_REPLACE_EXPRESSION?}" -e 'd;}' /opt/src/provider.tf

  # shellcheck disable=SC1090
  . "/opt/environment_variables.conf"

  TERRAFORM_REMOTE_STATE_FILE_PATH_CUSTOM="$(terraform_remote_state_file_path)"

  if [ -z "${TERRAFORM_REMOTE_STATE_FILE_PATH_CUSTOM}" ]; then
    echo "Please ensure the script 'terraform_remote_state_file_path' return a valid Terraform State File Path."
    exit 1
  fi

  TERRAFORM_REMOTE_STATE_FILE_PATH="stacks/${STACK_NAME?}/${TERRAFORM_REMOTE_STATE_FILE_PATH_CUSTOM?}"

  export TERRAFORM_REMOTE_STATE_FILE_PATH

  generate_backend_configuration_file > /opt/src/backend.conf && \

  show_debug_information

}

initialization

cd ..
cd test
# go mod init test > /dev/null
# go mod tidy > /dev/null
cd integration
go test

