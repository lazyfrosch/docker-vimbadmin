#!/bin/bash -eu

#sed -i "s/PRIMARY_HOSTNAME/${HOSTNAME}/g"  /var/www/html/public/mail/config-v1.1.xml
#sed -i "s/PRIMARY_HOSTNAME/${HOSTNAME}/g"  /var/www/html/public/mail.mobileconfig.php
#sed -i "s/UUID2/$(cat /proc/sys/kernel/random/uuid)/g"  /var/www/html/public/mail.mobileconfig.php
#sed -i "s/UUID4/$(cat /proc/sys/kernel/random/uuid)/g"  /var/www/html/public/mail.mobileconfig.php

if [ "$1" = "apache2-foreground" ]; then
    echo "Setting up configuration..."
    sed -i "s/PASSWORD/${DB_ENV_MYSQL_PASSWORD}/g" ${INSTALL_PATH}/application/configs/application.ini
    sed -i "s/HOSTNAME/${HOSTNAME}/g" ${INSTALL_PATH}/application/configs/application.ini
    sed -i "s/ADMIN_EMAIL/${ADMIN_EMAIL}/g" ${INSTALL_PATH}/application/configs/application.ini

    (
        echo "resources.auth.oss.rememberme.salt = \"${SALT_REMEMBER}\""
        echo "defaults.mailbox.password_salt     = \"${SALT_PASSWORD}\""
    ) >> ${INSTALL_PATH}/application/configs/application.ini

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
