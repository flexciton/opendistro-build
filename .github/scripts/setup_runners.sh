#!/bin/bash
set -e

# This script allows users to manually assign parameters
if [ "$#" -le 2 ] || [ "$#" -gt 3 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]
then
  echo "Please assign at least 2 / at most 3 parameters when running this script"
  echo "Example: $0 \$ACTION \$EC2_INSTANCE_NAME [\$GITHUB_TOKEN]"
  echo "Example: $0 \"run\" \"odfe-rpm-ism,odfe-rpm-sql\" \"<GitHub PAT>\""
  echo "Example: $0 \"terminate\" \"odfe-rpm-*\""
  exit 1
fi

SETUP_ACTION=$1
SETUP_INSTANCE=`echo $2 | sed 's/,/ /g'`
SETUP_TOKEN=$3
SETUP_AMI_ID="ami-01c504b077bde0476"
SETUP_AMI_USER="ec2-user"
SETUP_INSTANCE_TYPE="m5.xlarge"
SETUP_KEYNAME="odfe-release-runner"
SETUP_SECURITY_GROUP="odfe-release-runner"
SETUP_IAM_NAME="odfe-release-runner"
GIT_URL_API="https://api.github.com/repos"
GIT_URL_BASE="https://github.com"
GIT_URL_REPO="opendistro-for-elasticsearch/opendistro-build"


# Run / Start instances and bootstrap as runners
if [ "$SETUP_ACTION" = "run" ]
then

#  # Provision VMs
#  for instance_name1 in $SETUP_INSTANCE
#  do
#    echo "provisioning ${instance_name1}"
#    aws ec2 run-instances --image-id $SETUP_AMI_ID --count 1 --instance-type $SETUP_INSTANCE_TYPE \
#                          --key-name $SETUP_KEYNAME --security-groups $SETUP_SECURITY_GROUP \
#                          --iam-instance-profile Name=$SETUP_IAM_NAME \
#                          --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance_name1}}]"
#                          --quiet
#    echo $?
#    sleep 3
#  done
#
#  sleep 60
#

  aws configure list
  aws ssm describe-instance-information --output text

  # Setup VMs to register as runners
  for instance_name2 in $SETUP_INSTANCE
  do
    echo "get runner token and bootstrap on Git"
    instance_runner_token=`curl --silent -H "Authorization: token ${SETUP_TOKEN}" --request POST "${GIT_URL_API}/${GIT_URL_REPO}/actions/runners/registration-token" | jq -r .token`
    aws ssm send-command --targets Key=Name,Values=$instance_name2 --document-name "AWS-RunShellScript" \
                         --parameters '{"commands": ["#!/bin/bash", "sudo su - '${SETUP_AMI_USER}' && cd actions-runner && ./config.sh --unattended --url '${GIT_URL_BASE}/${GIT_URL_REPO}' --labels '${instance_name2}' --token '${instance_runner_token}'", "nohup ./run.sh &"]}' \
                         --output text
    sleep 3
  done

fi

# Terminate / Delete instances and remove as runners
if [ "$SETUP_ACTION" = "terminate" ]
then
  echo "Not Ready Yet"
fi


