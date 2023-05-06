# exit when any command fails
set -e

export AWS_PAGER=""

. config.sh

policy_document_json_default="$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Action": [
        "iot:Connect"
        ],
        "Resource": [
        "arn:aws:iot:$REGION:$ACCOUNT_ID:client/\${iot:ClientId}"
        ],
        "Condition": {
        "ArnEquals": {
            "iot:LastWillTopic": [
            "arn:aws:iot:$REGION:$ACCOUNT_ID:topic/$LS_AWS_TOPIC_ROOT/s/\${iot:ClientId}"
            ]
        }
        }
    },
    {
        "Effect": "Allow",
        "Action": [
        "iot:Receive"
        ],
        "Resource": [
        "arn:aws:iot:$REGION:$ACCOUNT_ID:topic/$LS_AWS_TOPIC_ROOT/*"
        ],
        "Condition": {}
    },
    {
        "Effect": "Allow",
        "Action": [
        "iot:Publish"
        ],
        "Resource": [
        "arn:aws:iot:$REGION:$ACCOUNT_ID:topic/$LS_AWS_TOPIC_ROOT/d/*/\${iot:ClientId}",
        "arn:aws:iot:$REGION:$ACCOUNT_ID:topic/$LS_AWS_TOPIC_ROOT/p/*/\${iot:ClientId}",
        "arn:aws:iot:$REGION:$ACCOUNT_ID:topic/$LS_AWS_TOPIC_ROOT/s/\${iot:ClientId}"
        ],
        "Condition": {}
    },
    {
        "Effect": "Allow",
        "Action": [
        "iot:Subscribe"
        ],
        "Resource": [
        "arn:aws:iot:$REGION:$ACCOUNT_ID:topicfilter/$LS_AWS_TOPIC_ROOT/d/\${iot:ClientId}/*",
        "arn:aws:iot:$REGION:$ACCOUNT_ID:topicfilter/$LS_AWS_TOPIC_ROOT/p/*/*",
        "arn:aws:iot:$REGION:$ACCOUNT_ID:topicfilter/$LS_AWS_TOPIC_ROOT/s/*",
        "arn:aws:iot:$REGION:$ACCOUNT_ID:topicfilter/$LS_AWS_TOPIC_ROOT/f/*"
        ],
        "Condition": {}
    }
    ]
}
EOF
)"

certs_folder="${CERTS_FOLDER:="target/certs/"}"
aws_cli="${AWS_CLI:="aws"}"
amazon_root_ca_1="${AMAZON_ROOT_CA1_PEM:="${certs_folder}AmazonRootCA1.pem"}"
certificate_pem_crt="${CERTIFICATE_PEM_CRT:="${certs_folder}certificate.pem.crt"}"
public_pem_key="${PUBLIC_PEM_KEY:="${certs_folder}public.pem.key"}"
private_pem_key="${PRIVATE_PEM_KEY:="${certs_folder}private.pem.key"}"
combined_pem="${COMBINED_PEM:="${certs_folder}combined_cert.pem"}"
certs_arn_txt="${CERTS_ARN_TXT:="${certs_folder}certs-arn.txt"}"
policy_name="${POLICY_NAME:="example-iot-policy"}"
policy_document="${POLICY_DOCUMENT:="$policy_document_json_default"}"

if ! "$aws_cli" iot get-policy --policy-name "$policy_name"
then
    "$aws_cli" iot create-policy \
        --policy-name "$policy_name" \
        --policy-document "$policy_document"
fi

mkdir -p "$certs_folder"

if ! test -f "$amazon_root_ca_1"
then
    curl -o "$amazon_root_ca_1" https://www.amazontrust.com/repository/AmazonRootCA1.pem
fi

if ! test -f "$amazon_root_ca_1"
then
    echo "ERROR: Failed downloading $amazon_root_ca_1 from https://www.amazontrust.com/repository/AmazonRootCA1.pem"
    exit 1
fi

if ! test -f "$certificate_pem_crt" || ! test -f "$private_pem_key"
then
    # Assign the certificate's arn and id fields to the respective variables
    certs_arn="$("$aws_cli" iot create-keys-and-certificate \
        --set-as-active \
        --certificate-pem-outfile "$certificate_pem_crt" \
        --public-key-outfile "$public_pem_key" \
        --private-key-outfile "$private_pem_key" \
        --query certificateArn \
        --output text)"

    "$aws_cli" iot attach-policy --policy-name "$policy_name" --target "$certs_arn"
fi

if ! test -f "$combined_pem"
then
    cat "$private_pem_key" "$certificate_pem_crt" > "$combined_pem"
fi

if ! test -f "$combined_pem"
then
    echo "ERROR: Failed to combine '$certificate_pem_crt' and '$private_pem_key' into '$combined_pem'"
    exit 1
fi

# if we created a new cert, write out the arn
if ! test -z "$certs_arn"
then
    echo -n "$certs_arn" > "$certs_arn_txt"
elif test -f "$certs_arn_txt"
then
    certs_arn="$(cat "$certs_arn_txt")"
fi

echo "Certificate arn: $certs_arn"
echo "Manage certs at: https://console.aws.amazon.com/iot/home#/certificatehub"