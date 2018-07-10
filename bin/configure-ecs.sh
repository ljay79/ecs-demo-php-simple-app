#!/usr/bin/env bash
set -ea
source .env

echo "In configure-ecs.sh"
script_dir="$(dirname "$0")"
bin_dir="$(dirname $0)/../bin"

echo AWS Region = ${AWS_REGION}

echo The value of arg 0 = $0
echo The value of arg 1 = $1
echo The value of arg 2 = $2 
echo The value of arg 3 = $3 
echo The value of arg 4 = $4  
echo The value of arg script_dir = $script_dir
echo UPDATED 201807091552

MY_STACK=$1
MY_ACCTID=$2
MY_ECR=$3
MY_URL=$4

echo The value of MY_STACK is $MY_STACK
echo The value of MY_ACCTID is $MY_ACCTID 
echo The value of MY_ECR is $MY_ECR

# Unique ID for Docker tag
uuid=$(date +%s)
awsacctid="$MY_ACCTID"
ecr_repo="$MY_ECR"
ecs_stack_name="$MY_STACK"
ecs_template_url="$MY_URL"

echo The value of arg uuid = $uuid
# remove "-e none", causes error "unknown option -e"
# use hostname only, remote optional https
eval $(aws ecr get-login --region ${AWS_REGION} | sed 's|https://||' | sed -e 's/-e none//g')

# Build, Tag and Deploy Docker
docker build -t $ecr_repo:$uuid .
docker tag $ecr_repo:$uuid $awsacctid.dkr.ecr.${AWS_REGION}.amazonaws.com/$ecr_repo:$uuid
docker push $awsacctid.dkr.ecr.${AWS_REGION}.amazonaws.com/$ecr_repo:$uuid

aws cloudformation update-stack --stack-name $ecs_stack_name --template-url $ecs_template_url --region ${AWS_REGION} --capabilities="CAPABILITY_IAM" --parameters ParameterKey=AppName,UsePreviousValue=true ParameterKey=ECSRepoName,UsePreviousValue=true ParameterKey=DesiredCapacity,UsePreviousValue=true ParameterKey=KeyName,UsePreviousValue=true ParameterKey=RepositoryBranch,UsePreviousValue=true ParameterKey=RepositoryName,UsePreviousValue=true ParameterKey=InstanceType,UsePreviousValue=true ParameterKey=MaxSize,UsePreviousValue=true ParameterKey=S3ArtifactBucket,UsePreviousValue=true ParameterKey=S3ArtifactObject,UsePreviousValue=true ParameterKey=SSHLocation,UsePreviousValue=true ParameterKey=YourIP,UsePreviousValue=true ParameterKey=ImageTag,ParameterValue=$uuid ParameterKey=ECSCFNURL,ParameterValue=$ecs_template_url

sleep 10
