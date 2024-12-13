
# Get remote LEAF tag
LEAF_VERSION=$(
  git ls-remote --tags https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8.git | \
    awk -F/ '{print $NF}' | \
    grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | \
    sort -V | \
    tail -n1
)
echo $LEAF_VERSION

# Check Docker Buildx Bake 
# If TAG and bake var different then update
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
