# (WIP) Building Linux Binaries for Docker Containers

## What is it?
This repository is a template that sets up the base for dispatching GitHub Actions jobs to create pre-compiled binaries for R/Bioconductor packages. This is an evolution of [BiocKubeInstall](https://github.com/Bioconductor/BiocKubeInstall), the original GKE-based stack for building binaries.

## Getting started
This repository is a young project that is still very much work in progress, and currently only used internally by the Bioconductor team.
We do, however, encourage interested users to [contact me](mailto:almahmoud@channing.harvard.edu) to help with initial setup.
In order to get started, you should first create a new repository based on this template.

### Configuration files
Next, change coniguration files in your newly created repository, before the initial workflow is dispatched.

- [CONTAINER_BASE_IMAGE.bioc](CONTAINER_BASE_IMAGE.bioc) - Target Docker image
- [PLATFORM.bioc](PLATFORM.bioc) - Target platform (linux/amd64 and linux/arm64 tested only)

### GitHub Secrets
The remainder of the configuration is stored in GitHub Secrets, as it contains credentials. This is currently the trickiest part to edit.

You will at least need an object store (bucket) location capable of handling up to 1 TB of data (for intermediate libraries).
An egress-free bucket is recommended for the intermediate libraries, as the constant traffic can quickly add up when billed on commercial clouds.
A different destination bucket can be specified to become the final binary repository.

We do not currently surface examples of these secrets publicly, both for security purposes, and to avoid eager inexperienced users from inadvertently incurring huge costs.
Knowledgeable users may reverse-engineer the needed credentials from [.github/workflows](.github/workflows) directory.
Otherwise, I recommend you [contact me](mailto:almahmoud@channing.harvard.edu) to thoroughly go over the risks involved in using this experimental stack, better understand your goal, and help with initial setup.
