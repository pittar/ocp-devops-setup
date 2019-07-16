#!/bin/bash

# Add three projects:  CI/CD, DEV, and QA.
oc new-project cicd --display-name="CI/CD Tools" --description="CI/CD Tools and Image Registry."
echo "Created project CI/CD."
oc new-project app-dev --display-name="DEV: App" --description="Development environment for app."
echo "Created project DEV: App."
oc new-project app-qa --display-name="QA: App" --description="QA environment for app."
echo "Created project QA: App."

# Add a new project to keep service accounts for external tools such as Azure DevOps.
oc new-project serviceaccounts --display-name="Service Accounts" --description="Service accounts for external tools."

# Allow DEV to pull from CI/CD
oc policy add-role-to-user system:image-puller system:serviceaccount:app-dev -n cicd
echo "Services in DEV can pull images from CI/CD."
# Allow QA to pull from CI/CD
oc policy add-role-to-user system:image-puller system:serviceaccount:app-qa -n cicd
echo "Services in QA can pull images from CI/CD."

# Create ImageStreams for the frontend and backend images.
oc tag docker.io/pittar/springboot-backend:latest springboot-backend:latest --scheduled=true -n cicd
oc tag docker.io/pittar/springboot-frontend:latest springboot-frontend:latest --scheduled=true -n cicd

# Add the app template to dev and uat projects.
oc apply -f resources/app-template.yaml -n app-dev
oc apply -f resources/app-template.yaml -n app-qa