#!/bin/bash

. config.sh

aws_cli="${AWS_CLI:="aws"}"
policy_name="${POLICY_NAME:="example-iot-policy"}"

echo "Remove iot authorizer $FUNCTION_NAME: In Progress"
"$aws_cli" iot update-authorizer --authorizer-name "$FUNCTION_NAME" --status INACTIVE
"$aws_cli" iot delete-authorizer --authorizer-name "$FUNCTION_NAME"
echo "Remove iot authorizer $FUNCTION_NAME: Complete"

echo "Remove lambda function $FUNCTION_NAME: In Progress"
"$aws_cli" lambda delete-function --function-name "$FUNCTION_NAME"
echo "Remove lambda function $FUNCTION_NAME: Complete"

echo "Detach role policy $FUNCTION_ROLE_NAME $FUNCTION_POLICY_ARN: In Progress"
"$aws_cli" iam detach-role-policy --role-name "$FUNCTION_ROLE_NAME" --policy-arn "$FUNCTION_POLICY_ARN"
echo "Detach role policy $FUNCTION_ROLE_NAME $FUNCTION_POLICY_ARN: Complete"


echo "Remove role $FUNCTION_ROLE_NAME: In Progress"
"$aws_cli" iam delete-role --role-name "$FUNCTION_ROLE_NAME"
echo "Remove role $FUNCTION_ROLE_NAME: Complete"

echo "Remove policy $FUNCTION_POLICY_ARN: In Progress"
"$aws_cli" iam delete-policy --policy-arn "$FUNCTION_POLICY_ARN"
echo "Remove policy $FUNCTION_POLICY_ARN: Complete"

echo "Remove client certificates and policies: In Progress"
for cert_arn in $(aws iot list-targets-for-policy --policy-name "$policy_name" --output text --query targets)
do
    cert_id="${cert_arn#"arn:aws:iot:$REGION:$ACCOUNT_ID:cert/"}"
    aws iot update-certificate --certificate-id "$cert_id" --new-status INACTIVE
    aws iot detach-policy --policy-name "$policy_name" --target "$cert_arn"
    aws iot delete-certificate --certificate-id "$cert_id"
done

for policy_version in $(aws iot list-policy-versions --policy-name example-iot-policy --output text --query policyVersions[].versionId)
do
    aws iot delete-policy-version --policy-name "$policy_name" --policy-version-id "$policy_version"
done

aws iot delete-policy --policy-name "$policy_name"
echo "Remove client certificates and policies: Complete"

rm -rf target/certs