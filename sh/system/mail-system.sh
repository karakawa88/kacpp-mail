#!/bin/bash

# ユーザーアカウントの作成
if [[ -r /usr/local/etc/usres.txt ]]; then
    /usr/local/sh/mail/users_add.sh /usr/local/etc/users.txt
fi

/usr/sbin/supervisord

exit 0

