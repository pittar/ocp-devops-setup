# DevOps Setup on OpenShift

A bare bones DevOps setup with three projects:
* Service Accoutns - Service accounts for external systems (not used in this demo).
* CI/CD - For `ImageStream`s and `Build`s.
* DEV - For *dev* version of the project.
* QA - for *qa* version of the project.

# Setup

Run `./setup-devops.sh` to:
* Create all projects.
* Grant `image-puller` access on the CI/CD project to the app-dev and app-qa projects.
* Create `ImageStream`s for backend and frontend images (from DockerHub).
* Create application template in the app-dev and app-qa projects so users can create the projets.

# Run the Apps from a Template

From the OpenShift UI, navigate to one of the projects (e.g. DEV: App) and click the **Select from Project** button.  You should now see an option called "Demo App Example with Database".  Click on this option and hit **Next**.

Read the description and click **Next** again.

Accept the defaults by clicking **Create**.  Your application should now be starting up.  It will include:
* A backend Spring Boot app that serves a single REST endpoint through a `Service`.
* A frontend Spring Boot app that consumes the backend REST endpoing through the service.  It also has a `Service` that is exposed externally as a `Route`.
* Configuration for the frontend app (port that is expoesed as well as the URL to use for the backend app) is configured with a `ConfigMap` called `frontend-cm` and is injected into the frontend container as environment variables.

# Setup Jenkins to use Nexus

* Open Jenkins from the URL exposed by the Jenkins route in the CI/CD project.  Login with your OpenShift credentials.
* Click "Manage Jenkins" from the left menu.
* Scroll down and click "Conifigure System".
* Search for "Kubernetes Pod Template".  In the "Container Template" section, add an environment variable with key=`MAVEN_MIRROR_URL` and value=`http://nexus:8081/content/groups/public`
* Click **Save**

# Setup Jenkins to use Dependency Track

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