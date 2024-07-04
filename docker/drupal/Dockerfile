# syntax=docker/dockerfile:1.5.1
FROM leaf_base_drupal

ARG TARGETARCH

# Copy local customizations
COPY --link rootfs /

# install custom modules; custom Drupal Config needs to be synchronized outside the build process
RUN --mount=type=cache,id=custom-drupal-composer-${TARGETARCH},sharing=locked,target=/root/.composer/cache \
    composer install -d /var/www/drupal && \
    chown -R nginx:nginx /var/www/drupal && \
    cleanup.sh
