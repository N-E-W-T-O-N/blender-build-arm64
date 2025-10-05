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
  progress = "plain"
  tags = [
    "blender-builder",
    "${REGISTRY}/blender-builder",
    "${REGISTRY}/blender-builder:arm64"
  ]
  cache-to = ["type=local,dest=build,mode=max"]    # ✅ Saves cache TO ./build
  cache-from = ["type=local,src=build"]            # ✅ Loads cache FROM ./build
  
  output = ["type=docker"] # this signifies --load
}


group "default" {
  targets = ["blender-builder"]
}
