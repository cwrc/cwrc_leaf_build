variable "TAG" {
    default = "local"
    }
variable "REPOSITORY" {
    default = "ghcr.io/cwrc"
    }
variable "LEAF_TAG" {
    default = "3.0.7"
    }
variable "LEAF_REPOSITORY" {
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

###############################################################################
# Target.
###############################################################################
target "drupal" {
  inherits = ["common"]
  context = "docker/drupal"
  contexts = {
    # The digest (sha256 hash) is not platform specific but the digest for the manifest of all platforms.
    # It will be the digest printed when you do: docker pull alpine:3.17.1
    # Not the one displayed on DockerHub.
    # N.B. This should match the value used in:
    # - <https://github.com/Islandora-Devops/isle-imagemagick>
    # - <https://github.com/Islandora-Devops/isle-leptonica>
    leaf_base_drupal = "docker-image://${LEAF_REPOSITORY}/drupal:${LEAF_TAG}"
  }
  tags = [
    "${REPOSITORY}/drupal:${TAG}"
  ]
}
