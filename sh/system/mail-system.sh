#!/bin/bash

# function _end() {
#     pid=$(ps auxw | grep "/sbin/init" | awk '{print $2}')
#     kill -15 $pid
#     exit 0
# }
# 
# trap '_end' 15


# ユーザーアカウントの作成
if [[ -r /usr/local/etc/usres.txt ]]; then
    /usr/local/sh/mail/users_add.sh /usr/local/etc/users.txt
fi

# supervisord
# /usr/sbin/supervisord

exec /sbin/init 
# systemctl daemon-reload
# systemctl start saslauthd
# systemctl start opendkim
# systemctl start opendmarc
# systemctl start postfix


