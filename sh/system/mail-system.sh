#!/bin/bash

# function _end() {
#     pid=$(ps auxw | grep "/sbin/init" | awk '{print $2}')
#     kill -15 $pid
#     exit 0
# }
# 
# trap '_end' 15


# ユーザーアカウントの作成
if [[ -r /usr/local/etc/users.txt ]]; then
    /usr/local/sh/mail/users_add.sh /usr/local/etc/users.txt
fi

# supervisord
# /usr/sbin/supervisord

exec /sbin/init 


