#!/bin/bash
aws cloudformation deploy \
     --stack-name teamcity-ecs \
     --template-file CloudFormation.yml \
     --capabilities "CAPABILITY_NAMED_IAM" 
exit $?