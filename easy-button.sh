#!/bin/bash

# This script will create and run everything.  No manual steps required.

# Add three projects:  CI/CD, DEV, and QA.
oc new-project cicd --display-name="CI/CD Tools" --description="CI/CD Tools and Image Registry."
# oc apply -f resources/cicd-quota.yaml -n cicd
echo "Created project CI/CD with quota."

oc new-project app-dev --display-name="DEV: App" --description="Development environment for app."
oc apply -f resources/small-project-quota.yaml -n app-dev
echo "Created project DEV: App with quota."

oc new-project app-qa --display-name="QA: App" --description="QA environment for app."
oc apply -f resources/small-project-quota.yaml -n app-qa
echo "Created project QA: App with quota."

# Allow developers view access on CI/CD and edit on dev and qa.
oc adm policy add-role-to-group view developer -n cicd
oc adm policy add-role-to-group edit developer -n app-dev
oc adm policy add-role-to-group edit developer -n app-qa

# Add a new project to keep service accounts for external tools such as Azure DevOps.
# Not required in this demo, but leavnig this in here for demonstration purposes.
# oc new-project serviceaccounts --display-name="Service Accounts" --description="Service accounts for external tools."
# oc create sa azdevops -n serviceaccounts
# oc policy add-role-to-user admin system:serviceaccount:serviceaccounts:azdevops -n app-dev
# oc policy add-role-to-user admin system:serviceaccount:serviceaccounts:azdevops -n app-qa

# Allow DEV to pull from CI/CD
oc policy add-role-to-user system:image-puller system:serviceaccount:app-dev:default -n cicd
echo "Services in DEV can pull images from CI/CD."

# Allow QA to pull from CI/CD
oc policy add-role-to-user system:image-puller system:serviceaccount:app-qa:default -n cicd
echo "Services in QA can pull images from CI/CD."

# Add Jenkins ConfigMap with default env vars (such as MAVEN_MIRROR_URL).
oc apply -f resources/jenkins-cm.yaml -n cicd

# Start Jenkins Persistent
oc new-app openshift/jenkins-persistent -e INSTALL_PLUGINS=structs:1.17,dependency-track:2.1.0 -n cicd
echo "Launching Jenkins."

# Spin up DevOps tools.
# Using Nexus 2 simply because it takes fewer resources.
oc new-app -f https://raw.githubusercontent.com/OpenShiftDemos/nexus/master/nexus2-persistent-template.yaml --param=VOLUME_CAPACITY=10Gi -n cicd
echo "Launching Nexus 2."

# SonarQube.
oc new-app -f https://raw.githubusercontent.com/pittar/sonarqube-openshift-docker/master/sonarqube-postgresql-template.yaml --param=SONARQUBE_VERSION=7.0 -n cicd
echo "Launching SonarQube."

# Dependency Track.
oc new-app -f https://raw.githubusercontent.com/pittar/openshift-dependency-track/master/dependency-track.yaml -n cicd

# Grant Jenkins service account access to dev and qa projects.
oc policy add-role-to-user admin system:serviceaccount:cicd:jenkins -n app-dev
oc policy add-role-to-user admin system:serviceaccount:cicd:jenkins -n app-qa
echo "Jenkins granted admin on DEV and QA projects."

# Add build and app templates to cicd.
oc apply -f resources/build-template.yaml -n cicd
oc apply -f resources/backend-template.yaml -n cicd
oc apply -f resources/frontend-template.yaml -n cicd
echo "Added build template and app template."

# Create the frontend and backend builds.
oc new-app cicd/jenkins-pipeline -p APP_NAME=frontend -p GIT_SOURCE_URL=https://github.com/pittar/springboot-frontend -n cicd
oc new-app cicd/jenkins-pipeline -p APP_NAME=backend -p GIT_SOURCE_URL=https://github.com/pittar/springboot-backend -n cicd
echo "Created frontend and backend builds and pipelines."

# Create ImageStreams for the frontend and backend images. 
# DON'T DO THIS IF BUILDING THE IMAGES FROM SOURCE! 
# oc tag docker.io/pittar/springboot-backend:latest springboot-backend:latest --scheduled=true -n cicd
# oc tag docker.io/pittar/springboot-frontend:latest springboot-frontend:latest --scheduled=true -n cicd


