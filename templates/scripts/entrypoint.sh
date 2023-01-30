#!/bin/bash

export PATH=/opt/scripts/:${PATH}

initialization() {
  PROVIDER_CREDENTIALS_FILE="/opt/terraform/credentials_provider.conf"
  BACKEND_CREDENTIALS_FILE="/opt/terraform/credentials_backend.conf"

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


LIST_FOLDERS=$(ls -d */ | cut -f1 -d'/')

if [[ -z "${LIST_FOLDERS}" ]]; then
  echo "Folders with termination _test dind't found: ${SOURCE_CODE_DIRECTORY}"
  exit 1
fi 

cd result

echo ${LIST_FOLDERS}

while read FOLDER_TEST_NAME; do
  if [[ "${FOLDER_TEST_NAME}" == *_test ]]
  then
    array+=(${FOLDER_TEST_NAME})
    go test -v ../${FOLDER_TEST_NAME}/ | tee ${FOLDER_TEST_NAME}.log 
    terratest_log_parser -testlog ${FOLDER_TEST_NAME}.log -outputdir ${FOLDER_TEST_NAME}_result
    mv ${FOLDER_TEST_NAME}_result/report.xml ${FOLDER_TEST_NAME}.xml 
  fi
done <<< "${LIST_FOLDERS}"


if [ -z "${array}" ]; then
    echo "Not found folders with termination '_test'"
    exit 1
fi
