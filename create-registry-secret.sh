#!/bin/bash

### Not actually used for this demo, but a nice script to have if you need to create a pull secret for an external secure registry.

read -p "Secret name: "  SECRET_NAME
read -p "Registry server (e.g. docker.io): "  REGISTRY_SERVER
read -p "Username: "  USERNAME
read -p "Password: "  PASSWORD

# Create secret in CI/CD project.
oc create secret docker-registry $SECRET_NAME --docker-server=$REGISTRY_SERVER --docker-username=$USERNAME --docker-password=$PASSWORD -n cicd

# Link to "default" service account
oc secrets link default $SECRET_NAME --for=pull -n cicd
