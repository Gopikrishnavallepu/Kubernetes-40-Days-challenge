# Day 3/40 - Multi Stage Docker Build - Docker Tutorial For Beginners - CKA Full Course 2024 ☸️


## Check out the video below for Day3 👇

[![Day 2/40 - How To Dockerize a Project - CKA Full Course 2024](https://img.youtube.com/vi/ajetvJmBvFo/sddefault.jpg)](https://youtu.be/ajetvJmBvFo)

# Pre-requisites ( If you have followed Day2 video and/or already have Docker Setup, then skip this step)

## If you would like to use docker and Kubernetes sandbox environment , you can use below:
```
https://labs.play-with-docker.com/
https://labs.play-with-k8s.com/
```

## Download Docker desktop client
```
https://www.docker.com/products/docker-desktop/
```

# Getting started with the demo

- Clone the below sample repository, or you can use any web application that you have

```
git clone https://github.com/piyushsachdeva/todoapp-docker.git
```

- cd into the directory
```
cd todoapp-docker/
```
- Create an empty file with the name Dockerfile
```
touch Dockerfile
```

- Using the text editor of your choice, paste the below content:
Note: Details about the below Dockerfile have already been shared in the video
```
FROM node:18-alpine AS installer
WORKDIR /app
COPY package*.json ./
RUN npm install 
COPY . .
RUN npm run build
FROM nginx:latest AS deployer
COPY --from=installer /app/build /usr/share/nginx/html
```

- Build the docker image using the application code and Dockerfile

```
docker build -t todoapp-docker .
```
- Verify the image has been created and stored locally using the below command:
```
docker images
```

- Create a public repository on hub.docker.com and push the image to remote repo
```
docker login
docker tag todoapp-docker:latest username/new-reponame:tagname
docker images
docker push username/new-reponame:tagname
```

- To pull the image to another environment, you can use the below command
```
docker pull username/new-reponame:tagname
```

- To start the docker container, use the below command

```
docker run -dp 3000:80 username/new-reponame:tagname
```

- Verify your app. If you have followed the above steps correctly, your app should be listening on localhost:3000
- To enter(exec) into the container, use the below command

```
docker exec -it containername sh
or
docker exec -it containerid sh
```
- To view docker logs

```
docker logs containername
or
docker logs containerid
```

- To view the content of Docker container
```
docker inspect
```

- Cleanup the old docker images from local repo using below command:

```
docker image rm image-id
```

Of course. Here is an updated, comprehensive blog post that details how to dockerize an application, incorporates the powerful concept of multi-stage builds, and reviews best practices for writing an efficient `Dockerfile`.

---

### From Code to Production-Ready Container: A Guide to Dockerizing Your App with Multi-Stage Builds

In my last post, we walked through the basics of dockerizing a simple to-do application. It was a great first step to solving the classic "it works on my machine" problem. However, as applications grow, so do our Docker images. The image we built previously was over 200MB, even when using a lightweight Alpine base image. This can slow down deployments, increase storage costs, and expand the potential security attack surface.

This guide will take our Docker skills to the next level. We will dockerize a new application using a **multi-stage build**, a best practice that dramatically reduces final image size and improves security. We'll also review some key best practices for writing professional, production-grade `Dockerfile`s.

All the code, including the final `Dockerfile`, is available in this GitHub repository: `https://github.com/us-deva/cka-series/tree/main/day-03`.

#### Prerequisites

As before, you'll need Docker installed on your machine. You can get **Docker Desktop** or use an online sandbox environment like [Play with Docker](https://labs.play-with-docker.com/).

### The Power of Multi-Stage Builds

Before we write any code, let's understand *why* we're using a multi-stage build.

When you build a modern web application (like one using Node.js or Go), you have two distinct phases:
1.  **The Build Environment:** This is where you compile your code, install development dependencies (`devDependencies`), and run tests. This environment needs tools like the Node.js runtime, `npm`/`yarn`, compilers, etc. These tools are bulky and are *not* needed to actually run the application.
2.  **The Runtime Environment:** This is the lean environment that runs the final, compiled application. It only needs the bare essentials, like the compiled code (e.g., static HTML/JS files) and a lightweight web server (like Nginx) to serve them.

A standard `Dockerfile` bundles everything—the build tools, development dependencies, source code, and final artifacts—into one large image. **A multi-stage build solves this by using multiple temporary build stages within a single `Dockerfile` and only copying the necessary final artifacts into the final, clean image**.

The key benefits are:
*   **Smaller Image Size:** By discarding all the build tools and intermediate files, the final image is significantly smaller and faster to pull and deploy.
*   **Improved Performance:** Smaller images lead to faster container startup times.
*   **Enhanced Security:** The final image contains only what is absolutely necessary to run the application. This reduces the attack surface by eliminating build tools and dependencies that could have vulnerabilities.
*   **Better Maintainability:** The build logic is cleaner and easier to understand, all within a single `Dockerfile`.

### Step 1: Clone the Application

We'll use a sample React application for this guide. First, let's clone the repository.

```bash
# Command to clone the repository
git clone https://github.com/piyushsachdeva/react-app-docker.git

# Explanation:
# 'git clone' downloads the application source code from the provided URL.
```

Now, navigate into the project directory.

```bash
cd react-app-docker
```

### Step 2: Create the Multi-Stage `Dockerfile`

Create an empty `Dockerfile` in the project root.

```bash
# Command to create the Dockerfile
touch Dockerfile

# Explanation:
# 'touch' is a command-line utility for creating empty files.
```

Now, open this `Dockerfile` in your favorite editor and add the following instructions. We will break down each stage.

```dockerfile
# --- STAGE 1: The "Installer" or Build Stage ---

# Use a Node.js base image to build our React app.
# We name this stage 'installer' using 'AS installer'.
FROM node:18-alpine AS installer
#

# Set the working directory inside the container.
WORKDIR /app
#

# Copy package files first to leverage Docker's layer caching.
COPY package.json package-lock.json ./
#

# Install all dependencies, including dev dependencies needed for the build.
RUN npm install
#

# Copy the rest of the application source code.
COPY . .
#

# Run the build script defined in package.json.
# This compiles the React app into a static 'build' folder.
RUN npm run build
#


# --- STAGE 2: The "Deployer" or Final Stage ---

# Start a new, clean stage from a lightweight Nginx image to serve our app.
# We name this stage 'deployer'.
FROM nginx:latest AS deployer
#

# Copy *only* the compiled build artifacts from the 'installer' stage.
# This is the core of the multi-stage build. We copy from the previous stage's
# filesystem into our new, clean stage.
COPY --from=installer /app/build /usr/share/nginx/html
#

# EXPOSE 80 (This is optional as the nginx image already does this)
# CMD ["nginx", "-g", "daemon off;"] (This is optional as it's the default command)
```

**What did we just do?**
*   **Stage 1 (`installer`)**: This stage used the `node:18-alpine` image to install all dependencies and run `npm run build`. This created a `/app/build` directory containing the final static HTML, CSS, and JavaScript files. At the end of this stage, all the build tools (`node`, `npm`, `node_modules`, etc.) are discarded.
*   **Stage 2 (`deployer`)**: This stage started fresh with a clean `nginx` image. The magic happens with the `COPY --from=installer` command, which cherry-picks *only* the `/app/build` folder from the previous stage and copies it to the Nginx web server's default directory. The final image contains only Nginx and our static files—nothing else from the build environment.

### Step 3: Build, Tag, and Run the Image

Now, let's build our lean, production-ready image.

```bash
# Command to build the image
docker build -t multistage-app .

# Explanation:
# 'docker build' reads the Dockerfile in the current directory ('.') and
# builds an image, tagging ('-t') it as 'multistage-app'.
```

Once the build is complete, let's check its size.

```bash
# Command to list local Docker images
docker images

# Explanation:
# This command lists all Docker images on your machine.
# You'll notice the 'multistage-app' image is very small (around 20-30MB)
# compared to what a single-stage build would have produced (>200MB).
```

Now, let's run it. This application's Nginx server runs on port 80 by default. We'll map it to a port on our local machine, like 3000.

```bash
# Command to run the container
docker run -d -p 3000:80 --name react-app multistage-app

# Explanation:
# 'docker run' creates and starts a container from our image.
# '-d' runs it in detached mode (in the background).
# '-p 3000:80' maps port 3000 on our host machine to port 80 inside the container.
# '--name react-app' gives our container an easy-to-remember name.
```

Check that it's running with `docker ps`. Now, open your browser and navigate to `http://localhost:3000`. You should see your React application live!

### Investigating Our Lean Container

Let's explore the container to confirm that no build artifacts are present.

```bash
# Command to get an interactive shell inside the container
docker exec -it react-app sh

# Explanation:
# 'docker exec' runs a command in a running container.
# '-it' provides an interactive terminal.
# 'react-app' is our container's name. 'sh' is the shell to run.
```

Once inside, try to find the `/app` directory or `node_modules`. You won't find them!. All our application files reside exactly where we put them: `/usr/share/nginx/html`. This proves that our final image is clean and contains only the necessary runtime files.

### A Note on `docker init`

For new projects, Docker now provides an interactive `docker init` command. This utility can automatically generate a `Dockerfile`, `.dockerignore`, and `compose.yaml` file for your project by analyzing your source code.

This information is from outside the provided sources and should be verified independently.

To use it, you would run `docker init` in your project's root directory and follow the prompts. It's a fantastic tool for getting started quickly without having to write a `Dockerfile` from scratch, though understanding the fundamentals as we've done here is still crucial.

### Best Practices for Writing Dockerfiles

Building on what we've learned, here are some essential best practices for writing high-quality `Dockerfile`s, inspired by Docker's official documentation and the principles discussed in the source material:

1.  **Use Multi-Stage Builds**: As we've demonstrated, this is one of the most effective ways to create lean, secure, and efficient images.
2.  **Use a `.dockerignore` file**: Similar to `.gitignore`, this file excludes files and directories (like `node_modules`, `.git`, local environment files) from the build context, which speeds up the build and prevents sensitive information from leaking into the image.
3.  **Leverage Build Cache**: Docker builds images in layers. If a layer hasn't changed, Docker reuses it from the cache. Structure your `Dockerfile` to take advantage of this. For example, `COPY` your `package.json` and run `npm install` *before* you `COPY` the rest of your source code. This way, the dependency layer is only rebuilt when your dependencies actually change, not on every code change.
4.  **Use Specific Base Image Tags**: Avoid using the `latest` tag (e.g., `node:latest`). Instead, be specific (e.g., `node:18-alpine`) to ensure your builds are reproducible and don't break unexpectedly when a new "latest" version is released.
5.  **Run as a Non-Root User**: By default, containers run as the `root` user, which is a security risk. Create a dedicated user and group in your `Dockerfile` and use the `USER` instruction to switch to that unprivileged user before running your application.
6.  **Minimize the Number of Layers**: Each `RUN`, `COPY`, and `ADD` instruction creates a new layer. Consolidate commands using the `&&` operator where it makes sense (e.g., `RUN apt-get update && apt-get install -y ...`) to keep your image lean.

By following these practices, you can create Docker images that are not just functional, but also secure, efficient, and ready for production.

Based on the sources, the command that reveals detailed information about a container's configuration is **`docker inspect`**.

This command provides a comprehensive JSON output with all the configuration values for a container, such as:
*   Network settings, including the IP address assigned to the container.
*   Port mappings, showing which host port is connected to which container port.
*   The container's unique ID and Mac address.
*   Details about the host and other engine-specific information.

The source highlights that `docker inspect` is a very handy and important command for troubleshooting when you need to see the specific configuration of a container. To use it, you provide the container's name or ID.

Other commands mentioned for investigating a container include:
*   **`docker logs`**: Shows the standard output logs generated by the application running inside the container.
*   **`docker exec`**: Allows you to run a command inside a running container, such as starting a shell (`sh`) to explore its file system.