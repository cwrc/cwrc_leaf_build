#!/usr/bin/bash

#
function update_leaf_version_test() {
  echo $1
}

#
function update_leaf_version() {

  # Check if Docker is not running
  if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running."
    exit 5
  fi

  # Check Docker Buildx Bake 
  # If TAG and bake var different then update
  # Leverage ability to use multiple file precedence (last take precedence) - https://docs.docker.com/build/bake/reference/
  export FROM=ghcr.io/cwrc/leaf-version-update-helper:local
  LEAF_VERSION=${LEAF_VERSION} docker buildx bake -f docker-bake.hcl -f docker-bake-leaf-version-override.json leaf-version-update-helper --set "drupal.tags=${FROM}"
  id=$(docker create "${FROM}")
  docker cp $id:/tmp/docker-bake-leaf-version-override.json . 
  docker rm -v $id

  # update Drupal core.extension.yml
  wget --output-document docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8/-/raw/${LEAF_VERSION}/docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml

  export FROM=ghcr.io/cwrc/drupal-core-extension-helper:local
  docker buildx bake drupal-core-extension-helper --set "drupal.tags=${FROM}"
  id=$(docker create "${FROM}")
  docker cp $id:/tmp/core.extension.yml docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml
  docker rm -v $id

  # Update Drupal composer.json and composer.lock
  wget --output-document docker/drupal/rootfs/var/www/drupal/composer.json https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8/-/raw/${LEAF_VERSION}/docker/drupal/rootfs/var/www/drupal/composer.json
  wget --output-document docker/drupal/rootfs/var/www/drupal/composer.lock https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8/-/raw/${LEAF_VERSION}/docker/drupal/rootfs/var/www/drupal/composer.lock

  docker buildx bake -f docker-bake.hcl -f docker-bake-leaf-version-override.json drupal-composer-helper --set "drupal.tags=ghcr.io/cwrc/drupal:local"
  id=$(docker create "ghcr.io/cwrc/drupal:local")
  docker cp $id:/var/www/drupal/composer.json docker/drupal/rootfs/var/www/drupal/
  docker cp $id:/var/www/drupal/composer.lock docker/drupal/rootfs/var/www/drupal/
  docker rm -v $id
}



BRANCH=$(git branch --show-current)
if [ "${BRANCH}" != 'main' ]; then
  echo "Not on the main branch: ${BRANCH}"
  # git switch main && git pull
  exit 1
fi

# Get local LEAF version
LEAF_VERSION_LOCAL=$(jq -r '.variable.LEAF_VERSION.default' docker-bake-leaf-version-override.json)
echo "LOCAL LEAF: ${LEAF_VERSION_LOCAL}"

# Get remote LEAF tag
LEAF_VERSION=$(
  git ls-remote --tags https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8.git | \
    awk -F/ '{print $NF}' | \
    grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | \
    sort -V | \
    tail -n1
)
echo "Remote LEAF: ${LEAF_VERSION}"

# Test if LEAF version update needed
if [ "${LEAF_VERSION_LOCAL}" = "${LEAF_VERSION}" ]; then
  echo "Version up-to-date ${LEAF_VERSION_LOCAL}"
  exit 2
elif [ -z "${LEAF_VERSION_LOCAL}" ]; then
  echo "LEAF_VERSION_LOCAL missing; check if jq is installed or in the wrong (non-root directory)"
  exit 2
else
  echo "Starting LEAF version update from ${LEAF_VERSION_LOCAL} to ${LEAF_VERSION}"
  GIT_BRANCH="leaf_update_${LEAF_VERSION}"
  git checkout -b "leaf_update_${GIT_BRANCH}"
  update_leaf_version_test ${LEAF_VERSION}
  update_leaf_version ${LEAF_VERSION}
  git commit -a -m "Bump LEAF version from ${LEAF_VERSION_LOCAL} to ${LEAF_VERSION}" && git push origin ${GIT_BRANCH}
fi

