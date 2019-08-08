#!/bin/bash

oc delete project cicd && \
    oc delete project app-dev && \
    oc delete project app-qa
