#!/bin/bash

. config.sh

aws_cli="${AWS_CLI:="aws"}"

iot_endpoint="$("$aws_cli" iot describe-endpoint --endpoint-type iot:Data-ATS --output text)"

# dotnet run --project aws-iot-custom-auth-mqttnet \ # csproj
#     "$CLIENT_ID" \ # the mqtt client id
#     "$LS_AWS_PASSWORD" \ # the authorizer password
#     "$iot_endpoint" \ # the endpoint of aws iot to connect to
#     "$LS_AWS_TOPIC_ROOT" \ # the root topic. Example: open/sub/otherclientid
#     "lambda" \ # the authentication type to use: lambda | cert
#     "$FUNCTION_NAME" \ # the custom authorizer or if cert, the path to the certificate file
#     "websocket4net" \ # the implementation to use. Options: dotnet | websocket4net
#     "websocket" # the transport layer to use. Options: tcp | websocket
dotnet run --project  aws-iot-custom-auth-mqttnet \
    "$CLIENT_ID" \
    "$LS_AWS_PASSWORD" \
    "$iot_endpoint" \
    "$LS_AWS_TOPIC_ROOT" \
    "lambda" \
    "$FUNCTION_NAME" \
    "dotnet" \
    "tcp"