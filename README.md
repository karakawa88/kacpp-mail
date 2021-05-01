# kagalpandh/kacpp-smtp SMTPメールサーバー環境Dockerイメージ

## 概要
SMTPメールサーバーDockerイメージファイル。
SMTPサーバーにpostfixをビルドしてインストールしている。
SMTPサーバーに必要な各種サービスもインストールした。
DKIMサーバーのopendkimやDMARCサーバーのopendmarcやメールウイルスチェックのclamav-milterや
メールクライアントmsmtpやmailのログを取るためrsyslogなどがインストールされている。
これらを全て起動して使用するには少し手順が必要である。
これから順番に説明していこうと思う。

## 設定ファイルとそれを配置するディレクトリ
まずpostfixやopendkimなどの設定ディレクトリとファイルを用意する。
postfixとopendkimとopendmarcとclamav-milterとpython-policyd-spfはこの名前のディレクトリで/usr/local/etcに配置する。
/usr/local/etcはマウントするようになっている。
各種設定ファイルの配置方法。
postfix
    /usr/local/etc/postfix
        main.cf
        master.cf
        smtpd.conf
            これはcyrus-saslが使用する設定ファイル。
            通常は/usr/lib/sasl2/smtpd.confだがこれにリンクを張りここのファイルを使用するようにしてある。
        aliases
            通常は/etc/aliasesにあるファイルだがこれにもリンクをここに張ってある。
opendkim
    /usr/local/etc/opendkim
        各種opendkimの設定ファイル。
        ディレクトリファイルの所有者とグループをopendkimにしておく必要がある。
opendmarc
    /usr/local/etc/opendmarc
    各種OpenDMARCの設定ファイル。
clamav
    /usr/local/etc/clamav
        clamav-milter.conf
            clamav-milterの設定ファイル。

# 各種サービスのユーザーグループ
またサービスが使用するユーザー・グループはホストとUIDとGIDを合わせる必要がある。
UIDとGIDの対応 ユーザー.グループの書式
postfix
ユーザー    postfix     1003
グループ    postfix     996
グループ    postdrop    997
opendkim
ユーザー    opendkim    113
グループ    opendkim    120
opendmarc
ユーザー    opendmarc   1004
グループ    opendmarc   994
clamav-milter
ユーザー    clamav      1005
グループ    clamav      993

## マウント
設定ファイルの格納場所/usr/local/etcとメールユーザーのホームディレクトリの場所/home/mail_usersはマウントする必要がある。

## ポート番号
ポート番号は25と465と587を使用するためポートフォワーディングの設定が必要。

## メールユーザーの追加
メールユーザーは/usr/local/sh/mailのusers_add.shシェルスクリプトで簡単に追加できる。
このシェルスクリプトは引数か/usr/local/etc/usrs.txtからユーザー情報を読み込みユーザー追加を行う。
このファイルをコンテナー起動前など上のディレクトリにusers.txtとして配置すれば自動で追加できる。
既存のシステムにメールユーザーを追加する場合はこのファイルにユーザー情報を追記しておけばよい。
users.txtの書式
ユーザー名:パスワード:ユーザーID
このシェルスクリプトが作成するユーザーのshellは/bin/shでグループはmailで固定される。
このシェルスクリプトのユーザーのホームディレクトリは/home/mail_users/ユーザー名であり
このシェルスクリプトではコンテナ側にホームディレクトリを作成しない。
そのためあらかじめユーザーをホスト側で用意し/home/mail_usersをマウントすることが推奨される。
ちなみに手動でコンテナ側にユーザーのホームディレクトリを用意することもできる。

## clamav-milterのメール発見時のメール送信
clamav-milterはメールからウイルスを発見するとメールで送信する機能がある。
これのメール送信は/usr/local/sh/mail/infected_message_handler.shが行う。
これでclamav-milter.confに適切な設定をすればメール送信ができるが
メール送信にはSMTP-AUTHの設定やSMTPメールサーバーなどの情報が必要である。
メール送信には上のシェルスクリプトの中でmsmtpを使用しておりその設定ファイルを
/usr/local/etc/mailに.clamavmsmtprcで用意する必要がある。
このファイルの所有者と権限はclamav 600でなければmsmtpは送信に失敗する。

## rsyslogとlogrotateとcron
システムログのmailを使用するためrsyslogを使用している。
もしmailファシリティのログをホストに転送したいなら
/etc/rsyslog.d/default.confに以下のように設定する。
mail.*info          @@ホストのIPアドレスとホスト名:ポート番号(514)
でホストのrsyslogサーバーに転送できる。
rsyslogを導入したためlogrotateもインストールしている。
cronにはaptをアップデートさせている。

## 使い方
```shell
docker image pull kagalpandh/kacpp-smtp
docker run -dit --name kacpp-smtp -p 25:25 -p 465:465 -p 587:587 \
    --privileged --cap-add=SYS_ADMIN -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -v  /home/local_etc:/usr/local/etc -v /home:/home/mail_users kagalpandh/kacpp-smtp
#各種サービス起動
docker exec -i kacpp-smtp "/usr/local/sh/system/mail-system-init.sh"
```
systemdを起動するため--privileged --cap-add=SYS_ADMINのオプション指定は必要である。
systemctlがDockerfileで使用できないため各種サービスを起動する/usr/local/sh/system/mail-system-init.sh
がある。もしも必要なサービスのみ起動したいなら手動で設定する。

##構成

##ベースイメージ
kagalpandh/kacpp-pydev

# その他
DockerHub: [kagalpandh/kacpp-postgres](https://hub.docker.com/repository/docker/kagalpandh/kacpp-smtp)<br />
GitHub: [karakawa88/kacpp-postgres](https://github.com/karakawa88/kacpp-smtp)

