# DevOps Setup on OpenShift

## Full Install

This is a step-by-step guide to setting up this CI/CD demo.  By the end you will have:
* Three projects:  CI/CD, DEV: App, QA: App
* Persistent Jenkins master
* Angular Jenkins agent
* Sonatype Nexus 2
* SonarQube
* Dependency Track
* Selenium Grid, with Chrome and FireFox nodes.
* Jenkins pipeline for both frontend and backend apps.
* Frontend and Backend apps deployed to both DEV and QA environments.

## Login as Admin

Login with the `oc` cli as an admin user to execute the steps below.

## Create a "developer" Group

Groups help you manage users more effectively.  We will create a `developer` group and add developers to this group.  This way, you only need to give the `developer` group access to a project, and not every dev individually.

```
oc adm groups new developer
oc adm groups add-users developer <username>
```

## Create the Projects

Create the CI/CD, DEV, and QA projects:

```
oc new-project cicd --display-name="CI/CD Tools" --description="CI/CD Tools and Image Registry."
echo "Created project CI/CD."

oc new-project app-dev --display-name="DEV: App" --description="Development environment for app."
echo "Created project DEV: App."

oc new-project app-qa --display-name="QA: App" --description="QA environment for app."
echo "Created project QA: App."
```

## Grant Developers Access to Projects

```
# Allow developers view access on CI/CD and edit on dev and qa.
oc adm policy add-role-to-group view developer -n cicd
oc adm policy add-role-to-group edit developer -n app-dev
oc adm policy add-role-to-group edit developer -n app-qa
```

## Allow DEV and QA Projects to Pull from CI/CD

I find it handy to have images kept in one or two projects.  For example, *snapshot* builds would be kept in the `CI/CD` project and *release* builds might be kept in a `image-registry` project.  For the sake of simplicity in this demo, we are going to keep all images in the `CI/CD` project.  This means the `DEV` and `QA` projects are going to need access to the images in `CI/CD`.

```
# Allow DEV to pull from CI/CD
oc policy add-role-to-user system:image-puller system:serviceaccount:app-dev:default -n cicd
echo "Services in DEV can pull images from CI/CD."

# Allow QA to pull from CI/CD
oc policy add-role-to-user system:image-puller system:serviceaccount:app-qa:default -n cicd
echo "Services in QA can pull images from CI/CD."
```

## Create a ConfigMap with Jenkins Configuration

Since we will be using our own Nexus repository, we need to tell our Jenkins Maven agent where to find it.  That could be configured manually after Jenkins is running, or you can create a ConfigMap with the Jenkins Maven agent configuration.  I like this option because it removes a human task and can be kept in source control.

```
# Add Jenkins ConfigMap with default env vars (such as MAVEN_MIRROR_URL).
oc apply -f resources/jenkins-cm.yaml -n cicd
```

## Start Jenkins Persistent

Next, we will start a persistent instance of Jenkins.  Notice there are a few plugins listed with the `INSTALL_PLUGINS` environment variable.  By setting this variable, Jenkins will install these plugins when it starts for the first time.  We need dependency-track for a later step.  The `structs` plugin is included so that we can set a specific version (the default verrsion fails withe certain versions of Jenkins).

```
# Start Jenkins Persistent
oc new-app openshift/jenkins-persistent -e INSTALL_PLUGINS=structs:1.17,dependency-track:2.1.0 -n cicd
echo "Launching Jenkins."
```

## Start Sonatype Nexus 2

The following command stats Nexus.  Make sure you give it lots of storage, or you will run into all sorts of strange build problems if you fill up the volume with dependencies.

```
# Using Nexus 2 simply because it takes fewer resources.
oc new-app -f https://raw.githubusercontent.com/OpenShiftDemos/nexus/master/nexus2-persistent-template.yaml --param=VOLUME_CAPACITY=10Gi -n cicd
echo "Launching Nexus 2."
```

## Start SonarQube

And now SonarQube for code quality / static code analysis.

```
# SonarQube.
oc new-app -f https://raw.githubusercontent.com/pittar/sonarqube-openshift-docker/master/sonarqube-postgresql-template.yaml --param=SONARQUBE_VERSION=7.0 -n cicd
echo "Launching SonarQube."
```

## Start Dependency Track

Dependency Track allows you to report on any vulnerabilities in your applications's dependencies.

```
# Dependency Track.
oc new-app -f https://raw.githubusercontent.com/pittar/openshift-dependency-track/master/dependency-track.yaml -n cicd
```

## Grant Jenkins Admin on DEV and QA Projects

The Jenkins pipelines we will use include instantiating templates in the `DEV` and `QA` projects.  Because of this, we will need to grant the `Jenkins` service account `admin` access on these projects.

```
# Grant Jenkins service account access to dev and qa projects.
oc policy add-role-to-user admin system:serviceaccount:cicd:jenkins -n app-dev
oc policy add-role-to-user admin system:serviceaccount:cicd:jenkins -n app-qa
echo "Jenkins granted admin on DEV and QA projects."
```

## Templates!

Time to add templates for build, frontend, and backend.

```
# Add build and app templates to cicd.
oc apply -f resources/build-template.yaml -n cicd
oc apply -f resources/backend-template.yaml -n cicd
oc apply -f resources/frontend-template.yaml -n cicd
echo "Added build template and app template."
```

## Create Builds for Fronend and Backend

Create some builds!

```
# Create the frontend and backend builds.
oc new-app cicd/jenkins-pipeline -p APP_NAME=frontend -p GIT_SOURCE_URL=https://github.com/pittar/springboot-frontend -n cicd
oc new-app cicd/jenkins-pipeline -p APP_NAME=backend -p GIT_SOURCE_URL=https://github.com/pittar/springboot-backend -n cicd
echo "Created frontend and backend builds and pipelines."
```

**Note:** Monitor the CI/CD project and wait for all pods to start before moving on to the next step.  It's not a bad idea to let thing settle for a few minutes even after everything looks like it has started.  Some of the apps still do quite a bit of initialization behind the scenes.

## Setup Jenkins to use Dependency Track

* Open Dependency Track from the URL exposed by the Dependency Track route in the CI/CD project.
* The first time you login, use the credentials "admin/admin", then change your password when prompted.
* Log back in.
* Go to `Administration -> Access Management -> Teams -> Administrators`
* Under `API keys`, click the `plus` icon to generate a new API key.  Copy it.
* Open Jenkins from the URL exposed by the Jenkins route in the CI/CD project.  Login with your OpenShift credentials.
* Click "Manage Jenkins" from the left menu.
* Scroll down and click "Conifigure System".
* Search for `Dependency-Track`
* For `Dependency-Track URL`: `http://dependency-track:8080`
* For `API Key`: Paste the API key you copied.
* Check `Auto Create Projects`
* Click **Test Connection**.  If this is successful, click **Save**.

# Start the Builds!

* In the CI/CD Project, navigate to `Builds -> Pipelines`
* You should see two pipelines; one for *frontend* and one for *backend*.  Start the pipelines by clicking the **Start pipeline** buttons associated with each build.
* The first time a pipeline runs it may take several minutes to start. This is because OpenShift will have to pull the "maven" Jenkins agent and start it up.  This is normal, once a build runs on each of your app nodes, it starts much faster as the image will be cached.
* You can see the progress from the pipeline screen, or by clicking **View Log** and watching the build logs in Jenkins.
* If you go to `DEV: App` or `QA: App` before running the pipline you'll notice they are empty.  This is normal.  The first time the pipeline runs it will setup each environment.
* Subsequent pipeline funs simply "rollout" the new container images to each environemnt.

# Did it work?

* Once the apps have been deployed to an enviornment, click on the route URL for the **frontend** app.  If it works, you'll get a very plain screen that shows a random number.  This is actually being generated by the backend app.  The frontend app calls a RESTful web service to get the next random number from the backend app.
