# CWRC LEAF Build

The next generation of the CWRC (Canadian Writing Research Collaboratory) building upon and extending [LEAF](https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8).

The OCI image built by the workflow includes the CWRC customizations in this repository layered on top of LEAF via CI/CD build workflow.

## CWRC customizations of LEAF

The CWRC Repository customizations include Drupal modules and configurations that are not relevant to other LEAF partner sites. This includes the `core.extension.yml` config plus the Composer files. The second commit to the repository is the LEAF base at tab 3.0.4 with subsequent commits indicating how the CWRC customizations alter the base.

### Preservation

* Drupal views to indicate new/changed items since a given date (paginated) - used by <https://github.com/cwrc/leaf-isle-bagger> to determine which items to add to the preservation workflow
  * views.view.preservation_show_media_timestamps.yml
    * <https://${SITE_URL}/view/views/preservation_show_node_timestamps?page=${page}&_format=json>
  * views.view.preservation_show_node_timestamps.yml
    * <https://${SITE_URL}/views/preservation_show_media_timestamps?page=${page}&_format=json>

* Adds the Drupal module `drupal/getjwtonlogin` used by <https://github.com/cwrc/leaf-isle-bagger> and <https://github.com/cwrc/islandora_bagger> (forked from mjordan) to acquire a JWT token within the login response with the JWT token used to pull media/content from the Drupal site for preservation

* Adds the Drupal module [Islandora Bagger Integration](https://github.com/cwrc/islandora_bagger_integration) (forked from mjordan) allowing multiple features but currently using
  * REST endpoint to allow registering archival information package (AIP) creation events with Drupal
  * Adds a Drupal view of the resulting information (views.view.preservation_show_registered_events.yml):
    * <https://${SITE_URL}/views/preservation/show_registered_events?page=${page}&_format=json>

* To enable, the following is added to the CWRC `.env` file along with the `docker-compose.bagger.yml` from `https://github.com/cwrc/leaf-isle-bagger/`

``` env
# ------------
# Preservation
# ------------

# For details: see https://github.com/cwrc/leaf-isle-bagger/

# Chain docker-compose.yml files
#COMPOSE_PATH_SEPARATOR=:
#COMPOSE_FILE=docker-compose.yml:docker-compose.bagger.yml

# Environment for the Islandora Bagger container
#BAGGER_REPOSITORY=ghcr.io/cwrc
#BAGGER_TAG=v0.0.3
#BAGGER_DEFAULT_PER_BAG_REGISTER_BAGS_WITH_ISLANDORA=false
```

## Update

Note: 2024-12-13 - [./docker/drupal/scripts/auto.sh](./docker/drupal/scripts/auto.sh) is a first attempt at automating the update process described below.

* update repository versions
  * Update `docker-bake.hcl` variable `LEAF_VERSION` with the container tag from <https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8>
* Check if local files have changed in <https://gitlab.com/calincs/cwrc/leaf/leaf-base-i8> since that last local update
  * check `docker/drupal/rootfs` (the known files as of August 2024 are included in the following bullet points)
* `core.extension.yml` merge changes
  * example using `sdiff` in interactive mode with `l` and `r` signifying how to manually merge the local CWRC customizations with the leaf-base changes
    * ToDo: investigate using `yq` to automatically update the yaml like the json later in this process
  * If not done then expect Drupal errors regarding missing modules

  ``` bash
  $ sdiff -s -o /tmp/z ../leaf-base-i8/docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml
    config_translation: 0                                       <
  %l
                                                                >   getjwtonlogin: 0
  %r
                                                                >   islandora_bagger_integration: 0
  %r
    locale: 0                                                   <
  %l
    message: 0                                                  <
    message_notify: 0                                           <
  %l
    page_manager: 0                                             <
    page_manager_ui: 0                                          <
  %l
    private_message: 0                                          <
    private_message_notify: 0                                   <
  %l
    user_csv_import: 0                                          <
  %l

  $ diff /tmp/z docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml
  $ mv /tmp/z docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml
  ```

* `core.extensions`

  * copy from leaf-base
    ``` bash
    cp ../leaf-base-i8/docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml docker/drupal/rootfs/var/www/drupal/config/sync/
    ```

  * add back CWRC customizations
    * core.extension.yml: `getjwtonlogin: 0` & `islandora_bagger_integration: 0`


      ``` bash
      export FROM=ghcr.io/cwrc/drupal-core-extension-helper:local
      docker buildx bake drupal-core-extension-helper --set "drupal.tags=${FROM}"
      id=$(docker create "${FROM}")
      docker cp $id:/tmp/core.extension.yml docker/drupal/rootfs/var/www/drupal/config/sync/core.extension.yml
      docker rm -v $id
      ```


* `composer.json` & `composer.lock`

  * copy from leaf-base

    ``` bash
    cp ../leaf-base-i8/docker/drupal/rootfs/var/www/drupal/composer.json docker/drupal/rootfs/var/www/drupal/
    cp ../leaf-base-i8/docker/drupal/rootfs/var/www/drupal/composer.lock docker/drupal/rootfs/var/www/drupal/
    ```

  * add back CWRC customizations
    * The next step automatically adds the following via `jq` command
      * updates composer.json
      * updates composer.lock
      * execute the helper to build the updated `composer.json` and `composer.lock` files

      ``` bash
      docker buildx bake drupal-composer-helper  --set "drupal.tags=ghcr.io/cwrc/drupal:local"
      id=$(docker create "ghcr.io/cwrc/drupal:local")
      docker cp $id:/var/www/drupal/composer.json docker/drupal/rootfs/var/www/drupal/
      docker cp $id:/var/www/drupal/composer.lock docker/drupal/rootfs/var/www/drupal/
      docker rm -v $id
      ```

    * review changes

### Notes

* tried using sdiff on the composer.json/lock file but
  * `composer.lock` doesn't like manual editing - `content-hash` is outdated
  * if only change the `composer.json` then `composer install` flags the differences between the composer.json and composer.lock hence the `composer require` commands in `docker/drupal/Dockerfile-composer-helper`

    ``` bash
    $ sdiff -s -o /tmp/z ../leaf-base-i8/docker/drupal/rootfs/var/www/drupal/composer.json docker/drupal/rootfs/var/www/drupal/composer.json
    $ mv  /tmp/z docker/drupal/rootfs/var/www/drupal/composer.json
    ```

* tried using the composer tools to update `composer.json` and add CWRC custom Git repository in the `repositories` section of composer.json
  * the `composer` CLI function has drawbacks: <https://jmichaelward.com/managing-composer-repositories-via-the-command-line/>
    * `composer config -d docker/drupal/rootfs/var/www/drupal/ repositories.0 '{"type": "git","url": "https://github.com/cwrc/islandora_bagger_integration.git","no-api": true}'`
  * the following needs to be added to the `composer.json`

    ``` json
        {
          "type": "git",
          "url": "https://github.com/cwrc/islandora_bagger_integration.git",
          "no-api": true
        },
    ```



## Building a local image

* `docker buildx bake --set "drupal.tags=ghcr.io/cwrc/drupal:local"`
