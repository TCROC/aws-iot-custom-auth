#!/bin/bash

. config.sh

aws_cli="${AWS_CLI:="aws"}"

iot_endpoint="$("$aws_cli" iot describe-endpoint --endpoint-type iot:Data-ATS --output text)"

# dotnet run --project aws-iot-custom-auth-mqttnet \ # csproj
#     "testid" \ # the mqtt client id
#     "testpassword" \ # the authorizer password
#     "$iot_endpoint" \ # the endpoint of aws iot to connect to
#     "open" \ # the root topic. Example: open/sub/otherclientid
#     "cert" \ # the authentication type to use: lambda | cert
#     "target/certs/AmazonRootCA1.pem,target/certs/certificate.pem.crt,target/certs/private.pem.key" \ # the custom authorizer or if cert, the ca, cert, and key seperated by commas
#     "websocket4net" \ # the implementation to use. Options: dotnet | websocket4net
#     "websocket" # the transport layer to use. Options: tcp | websocket
dotnet run --project  aws-iot-custom-auth-mqttnet \
    "$CLIENT_ID" \
    "$LS_AWS_PASSWORD" \
    "$iot_endpoint" \
    "$LS_AWS_TOPIC_ROOT" \
    "cert" \
    "target/certs/AmazonRootCA1.pem,target/certs/certificate.pem.crt,target/certs/private.pem.key" \
    "websocket4net" \
    "websocket"