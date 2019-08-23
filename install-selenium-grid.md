# Selenium Grid for Automated Functional Testing

This next part uses a repository from the Red Hat Open Innovation Labs GithHub space.

(https://github.com/rht-labs)[Red Hat Open Innovation Labs]

This process will build and deploy Selenium Grid, along with Chrome and Firefox nodes.

## First, Add CentOS Base

In your CI/CD project, import the `centos7` base image.

```
oc tag docker.io/centos/s2i-base-centos7 centos:centos7 -n cicd
```

## Clone and Run

Next, clone the repository.

```
git clone https://github.com/rht-labs
```

Make sure you are in your CI/CD project, then run the build script.

```
oc project cicd
./build-all-openshift.sh
```

Confirm that you want to deploy Selenium to your cicd project.  After a few minnutes
you will have everything up and running.

# oc import-image ubi7/s2i-base --from=registry.access.redhat.com/ubi7/s2i-base --confirm
# oc import-image rhel7-minimal --from=registry.access.redhat.com/rhel7-minimal --confirm
# oc import-image rhscl/s2i-base-rhel7 --from=registry.access.redhat.com/rhscl/s2i-base-rhel7 --confirm
