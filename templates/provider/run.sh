

LIST_FOLDERS=$(ls -d */ | cut -f1 -d'/')

# echo "resultado: ${LIST_FOLDERS}"


while read FOLDER_TEST_NAME; do
#   echo "      - ${FOLDER_TEST_NAME}"

  if [[ "${FOLDER_TEST_NAME}" == *_test ]]
  then
    echo "${FOLDER_TEST_NAME}"
  fi
done <<< "${LIST_FOLDERS}"