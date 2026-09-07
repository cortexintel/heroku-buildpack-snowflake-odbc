#!/bin/bash

export ODBCSYSINI=${HOME}/.apt/usr/lib/snowflake/odbc/conf/

# PE-4382: prefer key pair auth when SNOWFLAKE_PRIVATE_KEY (PEM content) is set;
# fall back to password otherwise. The key is delivered as env var content, not a
# checked-in file, since dynos have no persistent disk to hold one — this script
# runs on every boot, so materializing it here into a runtime-only file is safe.
if [ -n "${SNOWFLAKE_PRIVATE_KEY}" ]; then
  KEY_FILE="${ODBCSYSINI}/snowflake_key.p8"
  echo "${SNOWFLAKE_PRIVATE_KEY}" > "${KEY_FILE}"
  chmod 600 "${KEY_FILE}"
  AUTH_LINES="authenticator=SNOWFLAKE_JWT
priv_key_file=${KEY_FILE}
priv_key_file_pwd=${SNOWFLAKE_PRIVATE_KEY_PASSPHRASE}"
else
  AUTH_LINES="pwd=${SNOWFLAKE_PASSWORD}"
fi

echo "[snowflake]
Description=SnowflakeDB
Driver=SnowflakeDSIIDriver
Locale=en-US
PORT=443
SSL=on
CLIENT_SESSION_KEEP_ALIVE=true
uid=${SNOWFLAKE_USERNAME}
${AUTH_LINES}
server=${SNOWFLAKE_SERVER}
database=${SNOWFLAKE_DATABASE}
" > ${ODBCSYSINI}/odbc.ini
