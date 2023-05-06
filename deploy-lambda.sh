#!/bin/bash

# exit when any command fails
set -e

. config.sh

if [[ "$ARCHITECTURE" == "arm64" ]]
then
    build_architecture_arg="arm64"
    lambda_architecture_arg="arm64"
elif [[ "$ARCHITECTURE" == "x86-64" || "$ARCHITECTURE" == "x86_64" ]]
then
    build_architecture_arg="x86-64"
    lambda_architecture_arg="x86_64"
else
    echo "ERROR: Invalid architecture: $ARCHITECTURE"
    exit 1
fi

if ! test -f aws-iot-custom-auth-lambda/target/lambda/bootstrap/bootstrap.zip
then
    cargo lambda build --manifest-path aws-iot-custom-auth-lambda/Cargo.toml --release --$build_architecture_arg -o zip
fi

if ! role_arn="$(aws iam get-role \
    --role-name "$FUNCTION_ROLE_NAME" \
    --output text \
    --query Role.Arn)"
then
    role_arn="$(aws iam create-role \
        --path "/service-role/" \
        --role-name "$FUNCTION_ROLE_NAME" \
        --assume-role-policy-document "file://lambda-policy.json" \
        --output text \
        --query Role.Arn)"
fi

if function_arn="$(aws lambda get-function \
    --function-name "$FUNCTION_NAME" \
    --output text \
    --query Configuration.FunctionArn)"
then
    aws lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file "fileb://aws-iot-custom-auth-lambda/target/lambda/bootstrap/bootstrap.zip"

    echo "Sleeping for 5 seconds while function is updating..."
    sleep 5

    while [[ 
        "$(aws lambda get-function \
            --function-name aws_iot_auth_example \
            --output text \
            --query Configuration.LastUpdateStatus)" == "InProgress" ]]
    do
        echo "Sleeping for 5 seconds while function is updating..."
        sleep 5
    done

    aws lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --environment "Variables={$FUNCTION_ENV_VARS}"
else
    function_arn="$(aws lambda create-function \
        --function-name "${FUNCTION_NAME}" \
        --handler bootstrap \
        --runtime provided.al2 \
        --role "$role_arn" \
        --zip-file "fileb://aws-iot-custom-auth-lambda/target/lambda/bootstrap/bootstrap.zip" \
        --environment "Variables={$FUNCTION_ENV_VARS}" \
        --architectures "$lambda_architecture_arg" \
        --output text \
        --query FunctionArn)"
fi

if ! authorizer_arn="$(aws iot describe-authorizer \
    --authorizer-name "$FUNCTION_NAME" \
    --output text \
    --query authorizerDescription.authorizerArn)"
then
    authorizer_arn="$(aws iot create-authorizer \
        --authorizer-name "$FUNCTION_NAME" \
        --authorizer-function-arn "$function_arn" \
        --signing-disabled \
        --statis ACTIVE \
        --output text \
        --query authorizerArn)"
fi

aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --action lambda:InvokeFunction \
    --statement-id iot-authorizer \
    --principal iot.amazonaws.com \
    --source-arn "$authorizer_arn"