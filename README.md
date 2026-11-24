# MediCart – CI/CD Pipeline and Cloud Deployment Documentation

## 1. Project Overview

MediCart is a web application developed using React and Node.js, with Supabase used as its backend database and service provider.

The project was extended with DevOps practices to automate application testing, building, containerisation, image publishing, and cloud deployment.

The main objective was to establish an automated CI/CD pipeline using GitHub Actions, Docker, GitHub Container Registry (GHCR), Terraform, and Amazon EC2.

The completed workflow allows changes merged into the `main` branch to trigger an automated process that builds the application, creates a Docker image, publishes the image to GHCR, and deploys the latest version to an EC2 instance.

## 2. Technologies and Tools Used

| Technology / Tool | Purpose |
|---|---|
| Git | Version control |
| GitHub | Source code repository and collaboration |
| GitHub Actions | CI/CD automation |
| GitHub Actions Secrets | Secure storage of deployment credentials and application configuration |
| Docker | Application containerisation |
| Dockerfile | Defines how the application image is built |
| GitHub Container Registry (GHCR) | Stores and distributes Docker images |
| Terraform | Infrastructure provisioning using Infrastructure as Code |
| AWS EC2 | Cloud server hosting the application |
| AWS VPC | Provides the virtual network for the EC2 instance |
| AWS Security Groups | Controls inbound and outbound network traffic |
| Ubuntu | Operating system running on EC2 |
| OpenSSH | Secure connection between GitHub Actions and EC2 |
| Supabase | Application backend and database services |
| Node.js | Backend runtime environment |
| React | Frontend framework |

## 3. Application Architecture

The application uses a single-container deployment architecture.

The React frontend and Node.js backend are built separately during the Docker build process but are packaged into one Docker image.

The backend serves the compiled frontend static files, allowing both parts of the application to run through a single container.

The container exposes port `3001` internally. On the EC2 instance, port `80` is mapped to container port `3001`, making the application accessible through the EC2 public IP address.

### Deployment architecture

```text
Developer
    |
    | Git push / Pull Request
    v
GitHub Repository
    |
    v
GitHub Actions
    |
    +-----------------------------+
    |                             |
    v                             v
CI Workflow                 Publish and Deploy Workflow
    |                             |
    v                             v
Linting and Tests             Build Docker Image
    |                             |
    v                             v
Build Verification           Push Image to GHCR
                                  |
                                  v
                             SSH Connection
                                  |
                                  v
                              AWS EC2
                                  |
                                  v
                           Pull Latest Image
                                  |
                                  v
                         Run Docker Container
                                  |
                                  v
                         MediCart Application
```

## 4. Source Code Management

The project source code is maintained in a public GitHub repository.

Feature development follows a branch-based Git workflow.

The main workflow is:

1. Create a feature branch from `main`.
2. Implement the required changes.
3. Commit and push the changes to the feature branch.
4. Open a Pull Request targeting `main`.
5. Review and merge the Pull Request.
6. The merge into `main` triggers the relevant GitHub Actions workflows.

Feature branches used during development include:

- `feature/docker`
- `feature/cicd`
- `feature/terraform`


## 5. Docker Containerisation

### 5.1 Dockerfile

A multi-stage Docker build was implemented to create a production-ready image.

The first stage is responsible for installing dependencies and building the frontend and backend.

The second stage creates the runtime image with production dependencies and the compiled application files.

The Dockerfile uses `node:22-alpine` as its base image.

The build stage performs the following operations:

1. Sets the working directory.
2. Copies package configuration files.
3. Installs dependencies using `npm ci`.
4. Copies the application source code.
5. Builds the React frontend.
6. Compiles the Node.js backend.

The runtime stage:

1. Sets production environment variables.
2. Installs production dependencies using `npm ci --omit=dev`.
3. Copies the compiled frontend and backend from the build stage.
4. Exposes port `3001`.
5. Starts the backend application.

The final image does not include the full development dependency tree or uncompiled source files from the build stage.

### 5.2 Docker image

The Docker image is published to GitHub Container Registry.

Image name:

`ghcr.io/syedamushfia/medicart-webapp:latest`

The `latest` tag identifies the most recently published image.

### 5.3 Container configuration

The application runs as a single Docker container named:

`medicart`

The container is started using the following configuration:

- Container name: `medicart`
- Host port: `80`
- Container port: `3001`
- Restart policy: `unless-stopped`
- Environment configuration: `/opt/medicart/.env`

The port mapping is:

`80:3001`

This means incoming HTTP traffic to port 80 on the EC2 instance is forwarded to port 3001 inside the Docker container.

## 6. Continuous Integration (CI)

GitHub Actions is used to automate the continuous integration process.

The CI workflow is configured to run when code is pushed to `main` or feature branches matching `feature/**`, and when Pull Requests target `main`.

The workflow verifies that changes can be successfully integrated into the application.

The main stages include:

### 6.1 Checkout

The workflow checks out the repository source code using the GitHub Actions checkout action.

### 6.2 Dependency installation

Project dependencies are installed using the Node.js package configuration.

### 6.3 Code quality checks

Linting is executed to identify code-quality issues.

### 6.4 Testing

The configured tests are executed to verify application functionality.

### 6.5 Application build

The frontend and backend build processes are executed to ensure that the application can be compiled successfully.

### 6.6 Docker build verification

The workflow verifies that the Docker image can be built successfully.

This ensures that changes do not introduce problems that prevent the application from being containerised.

The CI workflow must complete successfully before changes are considered ready for integration.

## 7. Continuous Delivery and Deployment (CD)

A separate GitHub Actions workflow named `Publish and Deploy MediCart` handles image publishing and deployment.

The workflow is triggered by pushes to the `main` branch.

It uses the following GitHub Actions:

- `actions/checkout@v4`
- `docker/login-action@v3`
- `docker/build-push-action@v6`
- `appleboy/ssh-action@v1.2.2`

The workflow contains the following stages.

### 7.1 Repository checkout

The repository is checked out to access the latest application source code.

### 7.2 Authentication with GHCR

The workflow authenticates with GitHub Container Registry using:

- Registry: `ghcr.io`
- Username: `${{ github.actor }}`
- Password: `${{ secrets.GITHUB_TOKEN }}`

The workflow has the required `packages: write` permission to publish container images.

### 7.3 Docker image build and publishing

The Docker Build and Push action builds the application image using the root Dockerfile.

The image is pushed to:

`ghcr.io/syedamushfia/medicart-webapp:latest`

This makes the newly built image available to the deployment server.

### 7.4 Secure SSH connection to EC2

After publishing the image, GitHub Actions connects to the EC2 instance using the SSH action.

The connection uses:

- EC2 public IP address
- EC2 username (`ubuntu`)
- A dedicated SSH private key stored in GitHub Actions Secrets

A separate Ed25519 SSH key pair was created specifically for automated deployment.

The corresponding public key is added to the EC2 user's `authorized_keys` file.

The private key is never committed to the GitHub repository.

### 7.5 Environment configuration

The deployment workflow transfers the Supabase configuration from GitHub Actions Secrets to the EC2 instance.

It creates the following file:

`/opt/medicart/.env`

The file contains the required application environment variables:

- `SUPABASE_URL`
- `SUPABASE_SECRET_KEY`

The file permissions are restricted using:

`chmod 600 /opt/medicart/.env`

This keeps the application configuration separate from the Docker image and source code.

### 7.6 Pull the latest Docker image

The EC2 instance authenticates to the public GHCR package as required and pulls the latest image:

`sudo docker pull ghcr.io/syedamushfia/medicart-webapp:latest`

### 7.7 Replace the existing container

The deployment script removes the previous container if it exists:

`sudo docker rm -f medicart || true`

It then starts a new container using the latest image.

The container is configured with:

- Name: `medicart`
- Restart policy: `unless-stopped`
- Port mapping: `80:3001`
- Environment file: `/opt/medicart/.env`

### 7.8 Verify deployment

The workflow executes:

`sudo docker ps`

This displays the running containers and helps confirm that the MediCart container has started.

The application can then be accessed using the EC2 public IP address.

## 8. Infrastructure as Code with Terraform

Terraform was used to provision the AWS infrastructure.

Instead of manually creating the required infrastructure through the AWS Management Console, the configuration is maintained in Terraform files.

### 8.1 Terraform configuration

The Terraform project is organised into the following files:

| File | Purpose |
|---|---|
| `main.tf` | Defines the AWS provider, security group and EC2 instance |
| `variables.tf` | Defines configurable infrastructure variables |
| `outputs.tf` | Exposes useful deployment information |
| `terraform.tfvars` | Stores local variable values |
| `terraform.tfvars.example` | Provides an example of the required variable configuration |

The actual `terraform.tfvars` file is excluded from Git using `.gitignore`.

### 8.2 AWS provider

The AWS provider is configured to deploy resources in:

`ap-southeast-2` (Asia Pacific – Sydney)

The configuration uses the HashiCorp AWS provider.

### 8.3 Security group

A security group named `medicart-sg` is created.

It contains the following inbound rules:

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 80 | TCP | `0.0.0.0/0` | Allows public HTTP access |
| 22 | TCP | Configured SSH CIDR | Allows SSH connections |

Outbound traffic is permitted to all destinations.

### 8.4 EC2 instance

Terraform provisions an EC2 instance with the following configuration:

| Property | Configuration |
|---|---|
| Cloud provider | Amazon Web Services |
| Service | EC2 |
| Region | `ap-southeast-2` |
| Operating system | Ubuntu |
| Instance type | `t3.micro` |
| Application port | 80 |
| Container port | 3001 |

The instance uses an existing AWS key pair for administrative SSH access.

A Terraform user-data script performs initial server configuration.

The script:

1. Updates the Ubuntu package index.
2. Installs Docker.
3. Enables and starts the Docker service.
4. Adds the Ubuntu user to the Docker group.
5. Creates the SSH configuration directory.
6. Adds the dedicated deployment public key to `authorized_keys`.
7. Applies the appropriate SSH directory and file permissions.

This automates the initial setup of a newly provisioned server.

### 8.5 Terraform validation

The following commands are used to check the Terraform configuration:

```bash
terraform fmt
terraform validate
terraform plan
```

- `terraform fmt` formats Terraform configuration files.
- `terraform validate` checks the configuration for syntax and structural errors.
- `terraform plan` previews the infrastructure changes Terraform intends to make.

The infrastructure is created using:

```bash
terraform apply
```

The deployment outputs include the EC2 instance ID, public IP address and public URL.

## 9. Secrets and Security Management

Sensitive application configuration and SSH credentials are stored in GitHub Actions Secrets.

The following repository secrets are configured:

| Secret | Purpose |
|---|---|
| `EC2_HOST` | Public IP address of the EC2 instance |
| `EC2_USER` | EC2 SSH username |
| `EC2_SSH_KEY` | Dedicated SSH private key for automated deployment |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SECRET_KEY` | Supabase secret key |

The deployment workflow accesses these values using GitHub's `${{ secrets.SECRET_NAME }}` syntax.

The Supabase configuration is passed to the deployment server at runtime rather than being embedded in the Docker image.

The following files and credentials must not be committed to the public repository:

- `terraform.tfvars`
- Terraform state files
- `.env` files
- SSH private keys
- Application secret keys

The public SSH key is used on the EC2 instance to authorise the deployment connection.

## 10. Infrastructure Lifecycle and Cost Management

The project uses Terraform to manage the EC2 instance lifecycle.

Since the application is primarily intended for development, testing and demonstration, keeping the EC2 instance running continuously is unnecessary.

The infrastructure can therefore be destroyed when it is not required.

### 10.1 Destroying the infrastructure

Run:

```bash
terraform destroy
```

Terraform identifies and removes the resources it manages, including the MediCart EC2 instance and security group.

The following resources remain available:

- GitHub repository
- Application source code
- GitHub Actions workflows
- GHCR Docker image
- GitHub Actions Secrets
- Terraform configuration files
- Local Terraform variable values

The EC2 instance's automatically assigned public IP address is released when the instance is terminated.

### 10.2 Recreating the infrastructure

When the application needs to be deployed again:

1. Navigate to the Terraform directory.
2. Run `terraform apply`.
3. Confirm the infrastructure creation.
4. Retrieve the new EC2 public IP address:

```bash
terraform output -raw public_ip
```

5. Update the GitHub repository's `EC2_HOST` secret with the new public IP address.
6. Trigger the image publishing and deployment workflow.
7. Verify that the application is accessible.

The newly created EC2 instance is configured through Terraform user data, including Docker installation and the deployment SSH public key.

**Important:** The current publishing workflow is triggered by pushes to `main`. If there are no new code changes, a manual deployment trigger can be added using the `workflow_dispatch` event to allow redeployment without creating an unnecessary commit.

## 11. Testing and Verification

The following checks were performed during implementation.

| Area | Verification |
|---|---|
| Source code management | Repository and feature branches created |
| CI pipeline | GitHub Actions workflow completed successfully |
| Application build | Frontend and backend builds completed |
| Docker | Application image built successfully |
| GHCR | Docker image published and package made public |
| Terraform | Formatting, validation and planning completed |
| EC2 | Instance provisioned successfully |
| Docker on EC2 | Application container running |
| Automated deployment | GitHub Actions successfully connected to EC2 |
| Environment configuration | Supabase configuration passed through GitHub Secrets |
| Application access | Deployed application accessible through the EC2 public IP |

## 12. Conclusion

The MediCart project demonstrates the implementation of an automated CI/CD pipeline and cloud deployment workflow using commonly used DevOps tools.

GitHub Actions automates code verification, Docker image creation, image publishing and deployment. Docker provides a consistent containerised application environment, while GHCR stores the application image for distribution.

Terraform automates the provisioning and configuration of the AWS infrastructure, reducing the need for manual server setup.

The integration of these tools demonstrates practical experience with version control, CI/CD automation, containerisation, Infrastructure as Code, cloud infrastructure, SSH-based deployment and secrets management.

The infrastructure can also be destroyed and recreated when needed, providing a practical approach to managing cloud resource usage during development and demonstration.