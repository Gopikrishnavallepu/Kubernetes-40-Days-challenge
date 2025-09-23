

### From Code to Container: A Beginner's Guide to Dockerizing Your First Application

In modern software development, the phrase "it works on my machine" is a notorious sign of trouble ahead. Differences between development, testing, and production environments can cause applications to fail unexpectedly, leading to deployment headaches. Docker solves this by packaging an application with all its dependencies—libraries, configurations, and even a base operating system—into a single, portable unit called a container.

This guide will walk you through the entire process of dockerizing a sample application, from cloning the code to running it as a container. We'll follow the fundamental Docker workflow: **Build, Ship, and Run**.

All the code, including the final `Dockerfile`, is available in this GitHub repository: `https://github.com/us-deva/cka-series/tree/main/day-02`.

#### Prerequisites

Before we begin, you'll need Docker installed on your machine. You can download **Docker Desktop** for your specific operating system (Mac, Windows, or Linux). The installation is straightforward. Alternatively, if you can't install it locally, you can use a free, temporary sandbox environment like [Play with Docker](https://labs.play-with-docker.com/).

### Step 1: Get the Application Code

First, we need an application to containerize. We will use a sample to-do list application from a public Git repository.

Open your terminal and create a new directory for this project.

```bash
# Create a new folder for our project
mkdir day02-code

# Change into the new directory
cd day02-code
```

Next, clone the application's source code using the `git clone` command.

```bash
# Command to clone the repository
git clone https://github.com/docker/getting-started-app.git

# Explanation:
# 'git clone' downloads the entire git repository from the provided URL 
# into your current local directory.
```

After cloning, you will have a new folder named `getting-started-app`. Navigate into it.

```bash
cd getting-started-app
```

You can list the files with `ls` to see the application's source code, including `package.json` and a `src` folder.

### Step 2: Create the `Dockerfile`

The `Dockerfile` is a text file that contains a set of instructions for building a Docker image. It's the blueprint for our container.

Create the file using the `touch` command. The standard naming convention is `Dockerfile` with a capital 'D'.

```bash
# Command to create the Dockerfile
touch Dockerfile

# Explanation:
# 'touch' is a command-line utility for creating empty files.
```

Now, open this file in a text editor (the source uses `vi`, but you can use any editor like VS Code, Nano, etc.) and add the following instructions.

```dockerfile
# 1. Specify the base image
FROM node:18-alpine

# Explanation: Every Dockerfile starts with a base image. This app needs Node.js,
# so we use an official Node image. 'node:18-alpine' is a lightweight, Linux-based
# image with Node.js version 18 pre-installed, making our final image smaller.

# 2. Set the working directory inside the container
WORKDIR /app

# Explanation: This command sets the current working directory for subsequent
# instructions. If the directory doesn't exist, it will be created. All our
# work inside the container will happen in the `/app` folder.

# 3. Copy application files into the container
COPY . .

# Explanation: This copies files from the build context (the first '.') on your
# local machine into the working directory (the second '.') inside the container.
# This brings our application code into the image.

# 4. Install application dependencies
RUN yarn install --production

# Explanation: The 'RUN' command executes commands inside the container during the
# image build process. Here, we use the 'yarn' package manager to install the
# Node.js dependencies defined in 'package.json'.

# 5. Expose the application port
EXPOSE 3000

# Explanation: This instruction informs Docker that the container listens on the
# specified network port at runtime. Our application runs on port 3000.

# 6. Define the command to run the application
CMD ["node", "src/index.js"]

# Explanation: 'CMD' provides the default command to execute when the container
# starts. This command starts our Node.js application.
```

### Step 3: Build the Docker Image

With the `Dockerfile` ready, we can now build our image. This is the **"Build"** step of our workflow.

```bash
# Command to build the Docker image
docker build -t day02-todo .

# Explanation:
# 'docker build' is the command to build an image from a Dockerfile.
# '-t' (tag) assigns a name to our image, in this case, 'day02-todo'.
# '.' specifies that the build context (the location of the Dockerfile and
# application code) is the current directory.
```

During the build process, Docker executes each instruction in the `Dockerfile`, creating a new layer for each step. This layered architecture makes builds and transfers more efficient. Once complete, you can verify that the image was created.

```bash
# Command to list local Docker images
docker images

# Explanation:
# This command lists all the Docker images stored on your local machine.
# You should see your 'day02-todo' image with the tag 'latest'.
```

### Step 4: Ship the Image to a Registry

The **"Ship"** step involves pushing our image to a central registry, like Docker Hub, so it can be accessed from other environments.

First, you need to log in to your Docker Hub account from the terminal.

```bash
# Command to log into Docker Hub
docker login

# Explanation:
# This command authenticates you with Docker Hub using the same credentials
# you used to sign up. You'll be prompted for your username and password.
```

Next, you must re-tag the image to include your Docker Hub username, which tells Docker where to push it.

```bash
# Command to tag the image for Docker Hub
# Replace 'your-dockerhub-username' with your actual username.
docker tag day02-todo your-dockerhub-username/test-repo:latest

# Explanation:
# 'docker tag <source_image> <target_image>' creates an alias for an image.
# The target format is 'username/repository_name:tag'.
```

Now, you can push the image.

```bash
# Command to push the image to Docker Hub
# Replace 'your-dockerhub-username' with your actual username.
docker push your-dockerhub-username/test-repo:latest

# Explanation:
# This command uploads your tagged image to the specified repository on
# Docker Hub. The image will be compressed for a faster upload.
```

### Step 5: Run the Application as a Container

This is the final **"Run"** step. We will pull the image from the registry (simulating a deployment to a new environment) and run it as a container.

```bash
# Command to run the container
docker run -d -p 3000:3000 --name todo-app your-dockerhub-username/test-repo:latest

# Explanation:
# 'docker run' creates and starts a new container from an image.
# '-d' (detach) runs the container in the background.
# '-p 3000:3000' (publish) maps port 3000 on the host to port 3000 in the
# container, making the application accessible from your machine.
# '--name todo-app' gives our container a custom, memorable name.
# 'your-dockerhub-username/test-repo:latest' is the image to run.
```

The command will output a unique container ID. You can check that your container is running.

```bash
# Command to list running containers
docker ps

# Explanation:
# 'docker ps' lists all currently running containers. You should see your
# 'todo-app' container, its status ('Up'), and port mapping.
```

Now, open your web browser and navigate to `http://localhost:3000`. You should see your to-do list application running live!

### A Quick Look at `docker init`

For new projects, Docker now provides an interactive `docker init` command. This utility can automatically generate a `Dockerfile`, `.dockerignore`, and `compose.yaml` file for your project by analyzing your source code.

Information about this command is from outside the provided sources and should be verified independently.

To use it, you would run `docker init` in your project's root directory and follow the prompts. It asks about your application platform (e.g., Node, Python, Go), version, package manager, and run command. It's a fantastic tool for getting started quickly without having to write a `Dockerfile` from scratch.

### Troubleshooting Your Container

If you need to debug a running container, you can get a shell inside it.

```bash
# Command to execute a command inside a running container
docker exec -it todo-app sh

# Explanation:
# 'docker exec' runs a command in a running container.
# '-it' (interactive TTY) allows you to interact with the shell.
# 'todo-app' is the name of our container.
# 'sh' is the shell we want to run (the lightweight Alpine image uses 'sh' instead of 'bash').
```

Once inside, you are in the container's file system at the `/app` directory, where you can inspect files and troubleshoot.

Congratulations! You have successfully built, shipped, and run your first dockerized application. This process ensures your application runs consistently across any environment, solving the "it works on my machine" problem for good.