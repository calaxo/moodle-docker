#!/bin/bash
set -e

CONFIG_FILE=/var/www/html/config.php
DIST_FILE=/var/www/html/config-dist.php

# Variables d'environnement avec defaults
MOODLE_DATA_DIR=${MOODLE_DATA_DIR:-/var/www/moodledata}
CLUSTER_DIR=${MOODLE_CLUSTER_DIR:-/var/www/toreplicate}
START_MOODLE_SERVER=${START_MOODLE_SERVER:-true}

if [ ! -f "$CONFIG_FILE" ]; then
    echo ">> Génération de config.php depuis config-dist.php"
    cp "$DIST_FILE" "$CONFIG_FILE"

    # Config DB
    sed -i "s|^\$CFG->dbtype.*|\$CFG->dbtype    = '${DB_TYPE}';|" $CONFIG_FILE
    sed -i "s|^\$CFG->dblibrary.*|\$CFG->dblibrary = 'native';|" $CONFIG_FILE
    sed -i "s|^\$CFG->dbhost.*|\$CFG->dbhost    = '${DB_HOST}';|" $CONFIG_FILE
    sed -i "s|^\$CFG->dbname.*|\$CFG->dbname    = '${DB_NAME}';|" $CONFIG_FILE
    sed -i "s|^\$CFG->dbuser.*|\$CFG->dbuser    = '${DB_USER}';|" $CONFIG_FILE
    sed -i "s|^\$CFG->dbpass.*|\$CFG->dbpass    = '${DB_PASS}';|" $CONFIG_FILE
    sed -i "s|^\$CFG->prefix.*|\$CFG->prefix    = 'mdl_';|" $CONFIG_FILE

    # Config Moodle URL et dataroot
    sed -i "s|^\$CFG->wwwroot.*|\$CFG->wwwroot  = '${MOODLE_URL}';|" $CONFIG_FILE
    sed -i "s|^\$CFG->dataroot.*|\$CFG->dataroot = '${MOODLE_DATA_DIR}';|" $CONFIG_FILE

    # Créer les dossiers pour cluster / temp / cache / backuptemp
    mkdir -p "$CLUSTER_DIR"/{temp,cache,backuptemp}
    chown -R www-data:www-data "$CLUSTER_DIR" "$MOODLE_DATA_DIR"

    # Ajouter les chemins pour clustering à la fin du fichier avec sed
    sed -i "$ a\$CFG->tempdir        = '${CLUSTER_DIR}/temp';" $CONFIG_FILE
    sed -i "$ a\$CFG->cachedir       = '${CLUSTER_DIR}/cache';" $CONFIG_FILE
    sed -i "$ a\$CFG->backuptempdir  = '${CLUSTER_DIR}/backuptemp';" $CONFIG_FILE

    # Ajout de la configuration pour le reverse proxy
    sed -i "$ a\$CFG->reverseproxy = ${MOODLE_REVERSE_PROXY};" $CONFIG_FILE
    echo ">> Reverse proxy : $MOODLE_REVERSE_PROXY dans config.php"

    echo ">> config.php généré avec succès"
fi

# Démarrage conditionnel du serveur
if [ "$START_MOODLE_SERVER" = "true" ]; then
    echo ">> Démarrage du serveur Moodle"
    exec apache2-foreground
else
    echo ">> START_MOODLE_SERVER=false : le serveur Moodle ne démarre pas"
    exec sleep infinity
fi