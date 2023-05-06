#!/bin/bash

aws_cli_region="$(aws configure get region)"
aws_cli_account_id="$(aws sts get-caller-identity --output text --query Account)"

export AWS_PAGER=""
export AWS_CLI="aws"
export REGION="$aws_cli_region"
export ACCOUNT_ID="$aws_cli_account_id"
export CLIENT_ID="testid"

# arm64 or x86-64 or x86_64
export ARCHITECTURE="arm64"

export LS_AWS_TOPIC_ROOT="open"
export LS_AWS_PASSWORD="testpassword"

export FUNCTION_NAME="iot-lambda-authorizer"
export FUNCTION_ROLE_NAME="${FUNCTION_NAME}-role"
export FUNCTION_ENV_VARS="\
LS_AWS_TOPIC_ROOT=$LS_AWS_TOPIC_ROOT,\
LS_AWS_ACCOUNT_ID=$ACCOUNT_ID,\
LS_AWS_PASSWORD=$LS_AWS_PASSWORD,\
LS_AWS_REGION=$REGION,\
LS_AWS_DISCONNECT_AFTER_IN_SECONDS=86400,\
LS_AWS_REFRESH_AFTER_IN_SECONDS=86400\
"

export FUNCTION_POLICY_NAME="${FUNCTION_NAME}-policy"
export FUNCTION_POLICY_PATH="/service-role/"
export FUNCTION_POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy${FUNCTION_POLICY_PATH}${FUNCTION_POLICY_NAME}"

function_policy_json="$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:us-east-1:${ACCOUNT_ID}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-east-1:${ACCOUNT_ID}:log-group:/aws/lambda/${FUNCTION_NAME}:*"
            ]
        }
    ]
}
EOF
)"

export FUNCTION_POLICY_JSON="$function_policy_json"

function_role_json="$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
)"

export FUNCTION_ROLE_JSON="$function_role_json"