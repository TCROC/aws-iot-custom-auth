#!/bin/bash

. config.sh

echo "Remove iot authorizer $FUNCTION_NAME: In Progress"
aws iot update-authorizer --authorizer-name "$FUNCTION_NAME" --status INACTIVE
aws iot delete-authorizer --authorizer-name "$FUNCTION_NAME"
echo "Remove iot authorizer $FUNCTION_NAME: Complete"

echo "Remove lambda function $FUNCTION_NAME: In Progress"
aws lambda delete-function --function-name "$FUNCTION_NAME"
echo "Remove lambda function $FUNCTION_NAME: Complete"

echo "Detach role policy $FUNCTION_ROLE_NAME $FUNCTION_POLICY_ARN: In Progress"
aws iam detach-role-policy --role-name "$FUNCTION_ROLE_NAME" --policy-arn "$FUNCTION_POLICY_ARN"
echo "Detach role policy $FUNCTION_ROLE_NAME $FUNCTION_POLICY_ARN: Complete"


echo "Remove role $FUNCTION_ROLE_NAME: In Progress"
aws iam delete-role --role-name "$FUNCTION_ROLE_NAME"
echo "Remove role $FUNCTION_ROLE_NAME: Complete"

echo "Remove policy $FUNCTION_POLICY_ARN: In Progress"
aws iam delete-policy --policy-arn "$FUNCTION_POLICY_ARN"
echo "Remove policy $FUNCTION_POLICY_ARN: Complete"