# Blender arm64 Linux Docker Example

This project provides a Docker setup for running Blender on arm64 Linux systems.

## Features

- Supports Blender on arm64 architecture
- Easy setup using Docker
- Isolated environment for 3D rendering and modeling

## Prerequisites

- Docker installed on your arm64 Linux machine
- Sufficient system resources for Blender

## Usage

1. **Clone the repository:**

    ```bash
    git clone https://github.com/yourusername/blender-arm64-docker.git
    cd blender-arm64-docker
    ```

2. **Build the Docker image:**

    ```bash
    make build-image
    ```

3. **Run Blender in a container:**

    ```bash
    make build
    ```

## Customization

- Edit the `Dockerfile` to change Blender versions or add plugins.
- Mount local directories for project files:

  ```bash
  docker run -it --rm -v $(pwd)/projects:/home/blender/projects blender-arm64
  ```

## Resources

- [Blender Official Site](https://www.blender.org/)
- [Blender Source Code](https://projects.blender.org/blender/blender.git)
- [Docker Documentation](https://docs.docker.com/)

## License

This project is licensed under the MIT License.
