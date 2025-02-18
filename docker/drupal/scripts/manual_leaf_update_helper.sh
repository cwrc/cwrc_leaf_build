#!/usr/bin/bash

# Get remote LEAF tag
function get_remote_leaf_version() {
 
    LEAF_VERSION_REMOTE=$(
        git ls-remote --tags https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8.git | \
        awk -F/ '{print $NF}' | \
        grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | \
        sort -V | \
        tail -n1
    )
    echo "${LEAF_VERSION_REMOTE}"

}

# Get local LEAF version
function get_local_leaf_version() {
 
    LEAF_VERSION_LOCAL=$(jq -r '.variable.LEAF_VERSION.default' docker-bake-leaf-version-override.json)
    echo "${LEAF_VERSION_LOCAL}"
}


# Check Docker Buildx Bake 
#   If TAG and bake var different then update
#   Leverage ability to use multiple file precedence (last take precedence) - https://docs.docker.com/build/bake/reference/
function update_leaf_version() {
    local LEAF_VERSION=$1
    python ./docker/drupal/scripts/leaf_version_bake.py \
      --src ./docker-bake-leaf-version-override.json \
      --value "${LEAF_VERSION}"
}

# update Drupal core.extension.yml
function update_core_extension() {
    local LEAF_VERSION=$1
    wget --output-document docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml \
        https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8/-/raw/${LEAF_VERSION}/docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml

    python ./docker/drupal/scripts/merge_cwrc_customizations_drupal_core_extensions_yaml.py \
        --input ./docker/drupal/scripts/core.extension_cwrc_customizations_template.yml \
        --input ./docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml  \
        --output /tmp/core.extension.yml
  
  mv /tmp/core.extension.yml ./docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml
}


# Update Drupal composer.json and composer.lock
function update_composer_json_lock() {
    local LEAF_VERSION=$1
    wget --output-document ./docker/drupal/rootfs/var/www/drupal/composer.json \
        https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8/-/raw/${LEAF_VERSION}/docker/drupal/rootfs/var/www/drupal/composer.json
    wget --output-document ./docker/drupal/rootfs/var/www/drupal/composer.lock \
        https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8/-/raw/${LEAF_VERSION}/docker/drupal/rootfs/var/www/drupal/composer.lock

    bash ./docker/drupal/scripts/merge_cwrc_customizations.sh && \
    echo "Updating composer.json with drupal/getjwtonlogin and mjordan/islandora_bagger_integration" && \
    composer require -d ./docker/drupal/rootfs/var/www/drupal 'drupal/getjwtonlogin:^2.0' 'mjordan/islandora_bagger_integration' && \
    composer install -d ./docker/drupal/rootfs/var/www/drupal
}

#################################################################
# Main
#################################################################

BRANCH=$(git branch --show-current)
if [ "${BRANCH}" != 'main' ]; then
    echo "Not on the main branch: ${BRANCH}"
    # git switch main && git pull
    exit 1
fi

# Get local LEAF version
LEAF_VERSION_LOCAL=$(get_local_leaf_version)
echo "LOCAL LEAF: ${LEAF_VERSION_LOCAL}"

# Get remote LEAF tag
LEAF_VERSION_REMOTE=$(get_remote_leaf_version)
echo "Remote LEAF: ${LEAF_VERSION_REMOTE}"

# Test if LEAF version update needed
if [ "${LEAF_VERSION_LOCAL}" = "${LEAF_VERSION_REMOTE}" ]; then
    echo "Version up-to-date ${LEAF_VERSION_LOCAL}: Stopping"
    exit 2
elif [ -z "${LEAF_VERSION_LOCAL}" ]; then
    echo "LEAF_VERSION_LOCAL missing; check if jq is installed or in the wrong (non-root directory)"
    exit 2
else
    echo "Starting LEAF version update from ${LEAF_VERSION_LOCAL} to ${LEAF_VERSION_REMOTE}"
    GIT_BRANCH="leaf_update_${LEAF_VERSION_REMOTE}"
    
    echo "Create branch ${GIT_BRANCH}"
    #git checkout -b "${GIT_BRANCH}"
    
    echo "Update LEAF version"
    update_leaf_version ${LEAF_VERSION_REMOTE}
    
    echo "Update core.extension.yml"
    update_core_extension ${LEAF_VERSION_REMOTE}
    
    echo "Update composer.json and composer.lock"
    COMPOSER_JSON_PATH=./docker/drupal/rootfs/var/www/drupal/composer.json \
        update_composer_json_lock ${LEAF_VERSION_REMOTE}

    git diff 

    echo "Commit and push changes to ${GIT_BRANCH}"
    #git commit -a -m "Bump LEAF version from ${LEAF_VERSION_LOCAL} to ${LEAF_VERSION_REMOTE}" && git push origin ${GIT_BRANCH}
fi
