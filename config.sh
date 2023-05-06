#!/bin/bash

aws_cli_region="$(aws configure get region)"

export AWS_PAGER=""
export REGION="$aws_cli_region"

# arm64 or x86-64 or x86_64
export ARCHITECTURE="arm64"

export FUNCTION_NAME="iot-lambda-authorizer"
export FUNCTION_POLICY_NAME="${FUNCTION_NAME}-policy"
export FUNCTION_ROLE_NAME="${FUNCTION_NAME}-role"
export FUNCTION_ENV_VARS="\
LS_AWS_TOPIC_ROOT=open,\
LS_AWS_ACCOUNT_ID=test,\
LS_AWS_REGION=$REGION,\
LS_AWS_PASSWORD=testpassword,\
LS_AWS_DISCONNECT_AFTER_IN_SECONDS=86400,\
LS_AWS_REFRESH_AFTER_IN_SECONDS=86400\
"