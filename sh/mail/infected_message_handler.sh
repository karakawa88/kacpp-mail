#!/bin/sh
# REF: http://d.hatena.ne.jp/tak_yah/touch/20120229/1330481208
#

DATE=`date "+%Y-%m-%d %H:%M:%S"`
cat << EOF | /usr/local/bin/msmtp -C /usr/local/etc/mail/.clamavmsmtprc -a karakawa postmaster@kacpp.xyz
Subject: clamav-milter


clamav-milter ウイルス検出メール
$DATE
clamav-milterが送信されたメールにウイルスを検出しました。
送信されたメールはメールキューに格納されています。
速やかに対処をお願いします。
またなにもできない場合は次のところに連絡してください。
管理者メールアドレス: postmaster@kacpp.xyz

-------------------------------------------------------
Virus Mail Information
-------------------------------------------------------
Queue-id: $2
Message-id: $6
Date:  $7
Subject: $5
Sender:  $3
Destination:  $4
Virus Name: $1
-------------------------------------------------------

EOF

exit 0

