# CWRC LEAF Build

The next generation of the CWRC (Canadian Writing Research Collaboratory) extends the LEAF base. The CI/CD builds a container image based on LEAF. The customizations included within this repository extend the LEAF base.

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
