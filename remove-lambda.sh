. config.sh

echo "Removing iot authorizer $FUNCTION_NAME..."
aws iot delete-authorizer --authorizer-name "$FUNCTION_NAME"
echo "Removed iot authorizer $FUNCTION_NAME!"
echo "Removing lambda function $FUNCTION_NAME..."
aws lambda delete-function --function-name "$FUNCTION_NAME"
echo "Removed lambda function $FUNCTION_NAME!"
echo "Removing role $FUNCTION_ROLE_NAME..."
aws iam delete-role --role-name "$FUNCTION_ROLE_NAME"
echo "Removed role $FUNCTION_ROLE_NAME!"