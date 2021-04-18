#!/bin/bash

# ユーザーアカウントの作成
if [[ -r /usr/local/etc/usres.txt ]]; then
    /usr/local/sh/mail/users_add.sh /usr/local/etc/users.txt
fi

# supervisord
# /usr/sbin/supervisord

exec /sbin/init
systemctl daemon-reload
systemctl start opendkim
systemctl start opendmarc
systemctl start postfix


