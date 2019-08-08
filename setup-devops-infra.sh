#!/bin/bash

# Add three projects:  CI/CD, DEV, and QA.
oc new-project cicd --display-name="CI/CD Tools" --description="CI/CD Tools and Image Registry."
echo "Created project CI/CD."

oc new-project app-dev --display-name="DEV: App" --description="Development environment for app."
echo "Created project DEV: App."

oc new-project app-qa --display-name="QA: App" --description="QA environment for app."
echo "Created project QA: App."

# Add a new project to keep service accounts for external tools such as Azure DevOps.
# oc new-project serviceaccounts --display-name="Service Accounts" --description="Service accounts for external tools."

# Allow DEV to pull from CI/CD
oc policy add-role-to-user system:image-puller system:serviceaccount:app-dev:default -n cicd
echo "Services in DEV can pull images from CI/CD."

# Allow QA to pull from CI/CD
oc policy add-role-to-user system:image-puller system:serviceaccount:app-qa:default -n cicd
echo "Services in QA can pull images from CI/CD."

# Spin up DevOps tools.
# Using Nexus 2 simply because it takes fewer resources.
#oc process -n cicd -f https://raw.githubusercontent.com/OpenShiftDemos/nexus/master/nexus2-persistent-template.yaml | oc create -n cicd -f -
# SonarQube.
#oc new-app -f https://raw.githubusercontent.com/pittar/sonarqube-openshift-docker/master/sonarqube-postgresql-template.yaml --param=SONARQUBE_VERSION=7.0 -n cicd
# Dependency Track.
#oc new-app -f https://raw.githubusercontent.com/pittar/openshift-dependency-track/master/dependency-track.yaml -n cicd

# Add build and app templates to cicd.
oc apply -f resources/build-template.yaml -n cicd
oc apply -f resources/app-template.yaml -n cicd
echo "Added build template and app template."

# Create app deployments in DEV and QA.
oc process demo-app-template -n cicd | oc create -n app-dev -f -
oc process demo-app-template -n cicd | oc create -n app-qa -f -
echo "Created deployments.  Wait 5 seconds then cancel since there are no images yet."
sleep 5
oc rollout cancel dc/backend -n app-dev && oc rollout cancel dc/frontend -n app-dev
oc rollout cancel dc/backend -n app-qa && oc rollout cancel dc/frontend -n app-qa
echo "Instantiated app in DEV and QA."

# Create the frontend and backend builds.
oc process jenkins-pipeline -p APP_NAME=frontend -p GIT_SOURCE_URL=https://github.com/pittar/springboot-frontend -n cicd | oc create -n cicd -f -
oc process jenkins-pipeline -p APP_NAME=backend -p GIT_SOURCE_URL=https://github.com/pittar/springboot-backend -n cicd | oc create -n cicd -f -

# Grant Jenkins service account access to dev and qa projects.
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n app-dev
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n app-qa

# Create ImageStreams for the frontend and backend images.
# oc tag docker.io/pittar/springboot-backend:latest springboot-backend:latest --scheduled=true -n cicd
# oc tag docker.io/pittar/springboot-frontend:latest springboot-frontend:latest --scheduled=true -n cicd


