#!/bin/bash

oc new-project rl-dev --display-name="DEV: Record Linking" --description="Development environment for RL."
echo "Created project DEV: Record Linking."

oc new-project rl-qa --display-name="QA: Record Linking" --description="QA environment for RL."
echo "Created project QA: Record Linking with quota."

# Allow developers view access on CI/CD and edit on dev and qa.
oc adm policy add-role-to-group edit developer -n rl-dev
oc adm policy add-role-to-group edit developer -n rl-qa

# Allow DEV to pull from CI/CD
oc policy add-role-to-user system:image-puller system:serviceaccount:rl-dev:default -n cicd
oc policy add-role-to-user system:image-puller system:serviceaccount:rl-dev -n cicd
echo "Services in DEV can pull images from CI/CD."

# Allow QA to pull from CI/CD
oc adm policy add-role-to-user system:image-puller system:serviceaccount:rl-qa:default -n cicd
oc adm policy add-role-to-user system:image-puller system:serviceaccount:rl-qa -n cicd
echo "Services in QA can pull images from CI/CD."

# Grant Jenkins service account access to dev and qa projects.
oc adm policy add-role-to-user admin system:serviceaccount:cicd:jenkins -n rl-dev
oc adm policy add-role-to-user admin system:serviceaccount:cicd:jenkins -n rl-qa
echo "Jenkins granted admin on DEV and QA projects."

# Create the frontend and backend builds.
#oc new-app cicd/azure-jenkins-pipeline -p APP_NAME=rlbackend -p GIT_SOURCE_URL=git@ssh.dev.azure.com:v3/iets-innovation/record-linking/spring-boot-hw -p GIT_CONTEXT_DIR=rl_rest-api -n cicd
#oc new-app cicd/jenkins-pipeline -p APP_NAME=brl-user-interface -p GIT_SOURCE_URL=https://github.com/pittar/springboot-backend -n cicd
#echo "Created frontend and backend builds and pipelines."

# Create ImageStreams for the frontend and backend images. 
# DON'T DO THIS IF BUILDING THE IMAGES FROM SOURCE! 
# oc tag docker.io/pittar/springboot-backend:latest springboot-backend:latest --scheduled=true -n cicd
# oc tag docker.io/pittar/springboot-frontend:latest springboot-frontend:latest --scheduled=true -n cicd


