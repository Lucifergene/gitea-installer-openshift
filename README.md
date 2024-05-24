# Gitea Installer for Openshift

This project provides scripts and manifests to install Gitea on Openshift along with sample repositories for end-to-end testing.

## Prerequisites

- Openshift cluster
- `helm`: A tool for managing Kubernetes packages
- `kubectl`: The Kubernetes command-line tool
- `oc`: The OpenShift CLI
- `tea`: A CLI for Gitea
- `docker` for building the Docker image

## Installation with Bash Script

1. Clone this repository.
2. Login to your Openshift cluster.
3. Run the `gitea-install.sh` script.

## Installation with Container Image

1. Login to your Openshift cluster.
2. Pull the `gitea-installer-openshift` image from GitHub Container Registry.
3. Run the container with volume mount for `~/.kube/config` and set the `KUBECONFIG` environment variable.

```bash
docker pull ghcr.io/lucifergene/gitea-installer-openshift:main
docker run -it -v ~/.kube/config:/kube/config -e KUBECONFIG=/kube/config ghcr.io/lucifergene/gitea-installer-openshift:main
```

## Installation with Kubernetes Manifests

Apply the `release-openshift.yaml` manifest to your Openshift cluster.

```bash
kubectl apply -f https://github.com/Lucifergene/gitea-installer-openshift/releases/download/latest/release-openshift.yaml
```

## Usage

After successful installation, you can access Gitea on your Openshift cluster.

## Building the Docker Image

This repository includes a GitHub Actions workflow (`publish.yaml`) that builds a Docker image and pushes it to GitHub Container Registry.

## Contributing

Please see the [LICENSE](LICENSE) for details on how you can use and contribute to this project.

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.
