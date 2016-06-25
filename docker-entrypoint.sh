#!/bin/bash -eu

#sed -i "s/PRIMARY_HOSTNAME/${HOSTNAME}/g"  /var/www/html/public/mail/config-v1.1.xml
#sed -i "s/PRIMARY_HOSTNAME/${HOSTNAME}/g"  /var/www/html/public/mail.mobileconfig.php
#sed -i "s/UUID2/$(cat /proc/sys/kernel/random/uuid)/g"  /var/www/html/public/mail.mobileconfig.php
#sed -i "s/UUID4/$(cat /proc/sys/kernel/random/uuid)/g"  /var/www/html/public/mail.mobileconfig.php

DBHOST=db
DBNAME=${DB_ENV_MYSQL_DATABASE:-vimbadmin}
DBUSERNAME=${DB_ENV_MYSQL_USERNAME:-vimbadmin}
DBPASSWORD=${DB_ENV_MYSQL_PASSWORD:-vimbadmin}

SMTP_HOST=${SMTP_HOST:-$HOSTNAME}
IMAP_HOST=${IMAP_HOST:-$HOSTNAME}

set_config() {
    local var="${1}"
    if [ $# -gt 1 ]; then
        val="${2}"
    else
        val="${!var}"
    fi
    sed -i "s/${var}/${val}/g" ${INSTALL_PATH}/application/configs/application.ini
}

if [ "$1" = "apache2-foreground" ]; then
    echo "Setting up configuration..."
    set_config DBHOST
    set_config DBNAME
    set_config DBUSERNAME
    set_config DBPASSWORD

    set_config SMTP_HOST
    set_config IMAP_HOST

    set_config ADMIN_EMAIL

    set_config SALT_REMEMBER
    set_config SALT_PASSWORD

    export MYSQL="mysql -uvimbadmin"
    export MYSQL_HOST="db"
    export MYSQL_PWD="${DB_ENV_MYSQL_PASSWORD}"

    connected=0
    for ((i=0;i<10;i++))
    do
        echo "Trying to connect to database..."
        if $MYSQL -e 'status' >/dev/null; then
          if [ $($MYSQL -N -s -hdb -e \
            "select count(*) from information_schema.tables where \
              table_schema='vimbadmin' and table_name='domain';") -eq 1 ]; then
            echo "Database seems to be set up."
            connected=1
            break
          else
            echo "Creating DB and Superuser"
            HASH_PASS=`php -r "echo password_hash('${ADMIN_PASSWORD}', PASSWORD_DEFAULT);"`
            ./bin/doctrine2-cli.php orm:schema-tool:create
            $MYSQL vimbadmin -e \
              "INSERT INTO admin (username, password, super, active, created, modified) VALUES ('${ADMIN_EMAIL}', '$HASH_PASS', 1, 1, NOW(), NOW())" && \

            echo "Vimbadmin setup completed successfully"
            connected=1
            break
          fi
        fi
        sleep 5
    done
    if [ $connected -ne 1 ]; then
        echo "Database connection timed out!"
        exit 1
    fi

fi

exec "$@"
