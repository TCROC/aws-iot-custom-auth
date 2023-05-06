#!/bin/bash

# exit when any command fails
set -e

. config.sh

aws_cli="${AWS_CLI:="aws"}"

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

if ! role_arn="$("$aws_cli" iam get-role \
    --role-name "$FUNCTION_ROLE_NAME" \
    --output text \
    --query Role.Arn)"
then
    role_arn="$("$aws_cli" iam create-role \
        --path "/service-role/" \
        --role-name "$FUNCTION_ROLE_NAME" \
        --assume-role-policy-document "$FUNCTION_ROLE_JSON" \
        --output text \
        --query Role.Arn)"
fi

if ! "$aws_cli" iam get-policy --policy-arn "$FUNCTION_POLICY_ARN"
then
    "$aws_cli" iam create-policy \
        --policy-name "$FUNCTION_POLICY_NAME" \
        --path "$FUNCTION_POLICY_PATH" \
        --policy-document "$FUNCTION_POLICY_JSON"
fi

"$aws_cli" iam attach-role-policy --role-name "$FUNCTION_ROLE_NAME" --policy-arn "$FUNCTION_POLICY_ARN"

if function_arn="$("$aws_cli" lambda get-function \
    --function-name "$FUNCTION_NAME" \
    --output text \
    --query Configuration.FunctionArn)"
then
    "$aws_cli" lambda update-function-code \
        --function-name "$FUNCTION_NAME" \
        --zip-file "fileb://aws-iot-custom-auth-lambda/target/lambda/bootstrap/bootstrap.zip"

    echo "Sleeping for 5 seconds while function is updating..."
    sleep 5

    while [[ 
        "$("$aws_cli" lambda get-function \
            --function-name aws_iot_auth_example \
            --output text \
            --query Configuration.LastUpdateStatus)" == "InProgress" ]]
    do
        echo "Sleeping for 5 seconds while function is updating..."
        sleep 5
    done

    "$aws_cli" lambda update-function-configuration \
        --function-name "$FUNCTION_NAME" \
        --environment "Variables={$FUNCTION_ENV_VARS}"
else
    function_arn="$("$aws_cli" lambda create-function \
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

if ! authorizer_arn="$("$aws_cli" iot describe-authorizer \
    --authorizer-name "$FUNCTION_NAME" \
    --output text \
    --query authorizerDescription.authorizerArn)"
then
    authorizer_arn="$("$aws_cli" iot create-authorizer \
        --authorizer-name "$FUNCTION_NAME" \
        --authorizer-function-arn "$function_arn" \
        --signing-disabled \
        --status ACTIVE \
        --output text \
        --query authorizerArn)"
fi

"$aws_cli" lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --action lambda:InvokeFunction \
    --statement-id iot-authorizer \
    --principal iot.amazonaws.com \
    --source-arn "$authorizer_arn"