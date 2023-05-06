#!/bin/bash

. config.sh

iot_endpoint="$(aws iot describe-endpoint --endpoint-type iot:Data-ATS --output text)"

# dotnet run --project aws-iot-custom-auth-mqttnet \ # csproj
#     "testid" \ # the mqtt client id
#     "testpassword" \ # the authorizer password
#     "$iot_endpoint" \ # the endpoint of aws iot to connect to
#     "open" \ # the root topic. Example: open/sub/otherclientid
#     "MyAuthorizer" \ # the custom authorizer
#     "websocket4net" \ # the implementation to use. Options: dotnet | websocket4net
#     "websocket" # the transport layer to use. Options: tcp | websocket
dotnet run --project  aws-iot-custom-auth-mqttnet \
    "testid" \
    "$LS_AWS_PASSWORD" \
    "$iot_endpoint" \
    "$LS_AWS_TOPIC_ROOT" \
    "$FUNCTION_NAME" \
    "websocket4net" \
    "websocket"