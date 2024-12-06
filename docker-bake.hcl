variable "TAG" {
    default = "local"
    }
variable "REPOSITORY" {
    default = "ghcr.io/cwrc"
    }
# The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
# It will be the digest printed when you do: docker pull alpine:3.17.1
# Not the one displayed on DockerHub.
# Variable names with '_TAG' and '_REPOSITORY' fail with docker/bake-action
variable "LEAF_VERSION" {
    default = "3.0.16"
    }
variable "LEAF_REGISTRY" {
    default = "registry.gitlab.com/calincs/cwrc/leaf/leaf-base-i8"
    }
group "default" {
    targets = ["drupal"]
    }


###############################################################################
# Common target properties.
###############################################################################
target "common" {
  args = {
    # Required for reproduciable builds.
    # Requires Buildkit 0.11+
    # See: https://reproducible-builds.org/docs/source-date-epoch/
    # SOURCE_DATE_EPOCH = "${SOURCE_DATE_EPOCH}",
  }
}

# https://github.com/docker/metadata-action?tab=readme-ov-file#bake-definition
# bake definition file that can be used with the Docker Bake action. You just
# have to declare an empty target named docker-metadata-action and inherit from it.
target "docker-metadata-action" {}


###############################################################################
# Helper Targets.
###############################################################################
target "drupal-composer-helper" {
  inherits = ["common"]
  context = "docker/drupal"
  dockerfile = "Dockerfile-composer-helper"
  contexts = {
    leaf_base_drupal = "docker-image://${LEAF_REGISTRY}/drupal:${LEAF_VERSION}"
  }
  tags = [
    "${REPOSITORY}/drupal:${TAG}"
  ]
}

###############################################################################
# Target.
###############################################################################
target "drupal" {
  inherits = ["common", "docker-metadata-action"]
  context = "docker/drupal"
  dockerfile = "Dockerfile"
  contexts = {
    leaf_base_drupal = "docker-image://${LEAF_REGISTRY}/drupal:${LEAF_VERSION}"
    #leaf_base_drupal = "docker-image://registry.gitlab.com/calincs/cwrc/leaf/leaf-base-i8/drupal:3.0.7"
  }
#  platforms = [
#    "linux/amd64",
#    "linux/arm64",
#  ]
}
