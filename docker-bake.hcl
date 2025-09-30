variable "REGISTRY" {
  default = "newton2022"
}


variable "TAG" {
  default = "latest"
}


target "blender-builder" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = ["linux/arm64"]
  pull = true
  tags = [
    "blender-builder",
    "${REGISTRY}/blender-builder",
    "${REGISTRY}/blender-builder:arm64"
  ]
}

group "default" {
  targets = ["blender-builder"]
}

