#!/bin/bash

##
# 概要: ユーザーのメールのバックアップを行うスクリプト。
# 説明: ユーザーのメーディレクトリ Maildirを全てtarで固めてバックアップする。
# ステータスコード:
#   0       正常
#   1       ユーザーのホームディレクトリが格納されたディレクトリがない
#   2       バックアップ先ディレクトリがない
#   3       ユーザーのMaildirがひとつも見つからない
#   4       tarでエラー
#

USERS_HOME_DIR="/home/mail_users"
DEST="/dest"
BACKUP_FILE="mail_users-backup.tar.xz"
# tar コマンドのオプション
# COMPRESS_COMMAND=${COMPRESS_COMMAND:-"xz -T 0"}
TAR_WARN_ERR_OPTIONS=" --warning=no-file-changed --warning=no-file-removed --warning=no-file-shrank "
# TAR_OPTIONS=" -cJvf $BACKUP_FILE --use-compress-prog='$COMPRESS_COMMAND' $TAR_WARN_ERR_OPTIONS "
TAR_OPTIONS=" -cJf $BACKUP_FILE  $TAR_WARN_ERR_OPTIONS "

# ユーザーたちのHOMEディレクトリ
if [[ ! -d "$USERS_HOME_DIR" ]]
then
    echo "ユーザーのHomeディレクトリが見つかりません。[$USERS_HOME_DIR]" 1>&2
    exit 1
fi
# バックアップ出力先
if [[ ! -d "$DEST" ]]
then
    echo "バックアップ先ディレクトリが見つかりません。[$DEST]" 1>&2
    exit 2
fi

SRC=""
shopt -s lastpipe
find "$USERS_HOME_DIR" -maxdepth 1 -type d -print |\
while read dir
do
    if [[ -d "$dir/Maildir" ]]
    then
        SRC="$SRC ${dir}/Maildir "
    else
        continue
    fi
done
[[ -z "$SRC" ]] && echo "ユーザーのMaildirがひとつも見つかりません。" 1>&2 && exit 3

cd $DEST
tar ${TAR_OPTIONS} $SRC
ret=$?
if (( $ret > 2 )) 
then
    echo "Error: tarバックアップエラー" 1>&2
    exit 4
fi

exit 0
