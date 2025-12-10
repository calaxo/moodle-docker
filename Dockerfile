FROM php:8.2-apache

# Installer dépendances système nécessaires
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    mariadb-client \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    g++ \
    cron \
    && rm -rf /var/lib/apt/lists/*


# Configurer et compiler les extensions PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd mysqli zip intl opcache soap

# Télécharger Moodle
WORKDIR /var/www/html
RUN rm -rf ./* \
    && curl -sL https://download.moodle.org/download.php/direct/stable500/moodle-latest-500.tgz \
    | tar xfz - --strip-components=1

# Config PHP optimisé pour Moodle
RUN echo "max_input_vars = 5000" > /usr/local/etc/php/conf.d/moodle.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/moodle.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/moodle.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/moodle.ini

# Configurer le cron job
RUN mkdir -p /etc/cron.d/ \
    && echo "* * * * * www-data php /var/www/html/admin/cli/cron.php >/dev/null 2>&1" \
    > /etc/cron.d/moodle-cron \
    && chmod 0644 /etc/cron.d/moodle-cron \
    && crontab -u www-data /etc/cron.d/moodle-cron

# Copier le script d'entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Créer dossier data
RUN mkdir -p /var/www/moodledata \
    && chown -R www-data:www-data /var/www/moodledata /var/www/html

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
