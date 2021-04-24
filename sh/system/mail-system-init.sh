#!/bin/bash


# ユーザーアカウントの作成
if [[ -r /usr/local/etc/users.txt ]]; then
    /usr/local/sh/mail/users_add.sh /usr/local/etc/users.txt
fi

systemctl daemon-reload
systemctl enable saslauthd
systemctl enable opendkim
systemctl enable opendmarc
systemctl enable postfix

systemctl start saslauthd
systemctl start opendkim
systemctl start opendmarc
systemctl start postfix

exit 0

