# PstgreSQL環境を持つdebianイメージ
# 日本語化も設定済み
FROM        kagalpandh/kacpp-gccdev AS builder
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
ENV         DEBIAN_FORONTEND=noninteractive
ENV         MSMTP_VERSION=1.8.15
ENV         MSMTP_SRC=msmtp-${MSMTP_VERSION}
ENV         MSMTP_SRC_FILE=${MSMTP_SRC}.tar.xz
ENV         MSMTP_URL="https://marlam.de/msmtp/releases/${MSMTP_SRC_FILE}"
ENV         MSMTP_DEST=${MSMTP_SRC}
ENV         CYRUS_VERSION=2.1.27
ENV         CYRUS_SRC=cyrus-sasl-${CYRUS_VERSION}
ENV         CYRUS_SRC_FILE=${CYRUS_SRC}.tar.gz
ENV         CYRUS_URL="https://github.com/cyrusimap/cyrus-sasl/archive/refs/tags/${CYRUS_SRC_FILE}"
ENV         CYRUS_DEST=${CYRUS_SRC}
COPY        sh/apt-install/mail-system-dev.txt /usr/local/sh/apt-install
# https://github.com/cyrusimap/cyrus-sasl/archive/refs/tags/cyrus-sasl-2.1.27.zip
# 開発環境インストール
RUN         apt update && \
            /usr/local/sh/system/apt-install.sh install gccdev.txt && \
            # msmtpビルド
            # ./configure --prefix=... && make && make install
            wget ${MSMTP_URL} && tar -Jxvf ${MSMTP_SRC_FILE} && cd ${MSMTP_SRC} && \
                ./configure --prefix=/usr/local/${MSMTP_DEST} && \
                make && make install
            # cyrus-saslビルド
            # ./configure
            # make && make install
RUN         /usr/local/sh/system/apt-install.sh install mail-system-dev.txt
# ftp://ftp.porcupine.org/mirrors/project-history/postfix/official/postfix-3.5.2.tar.gz
# Postfixビルドとインストール
ENV         POSTFIX_VERSION=3.5.2
ENV         POSTFIX_SRC=postfix-${POSTFIX_VERSION}
ENV         POSTFIX_SRC_FILE=${POSTFIX_SRC}.tar.gz
ENV         POSTFIX_URL="ftp://ftp.porcupine.org/mirrors/project-history/postfix/official/${POSTFIX_SRC_FILE}"
ENV         POSTFIX_DEST=${POSTFIX_SRC}
RUN         wget ${POSTFIX_URL} && tar -zxvf ${POSTFIX_SRC_FILE} && cd ${POSTFIX_SRC} && \
                make makefiles CCARGS="-DUSE_TLS -DUSE_SASL_AUTH -DUSE_CYRUS_SASL -I/usr/include/sasl" \
                AUXLIBS="-L/usr/local/lib -lsasl2 -lssl -lcrypto" && \
                make && \
                mkdir /usr/local/${POSTFIX_DEST} && \
                make non-interactive-package install_root="/usr/local/${POSTFIX_DEST}" && \
            # クリーンアップ
            /usr/local/sh/system/apt-install.sh uninstall gccdev.txt && \
                apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/* && \
                cd ../ && rm -rf ${MSMTP_SRC}*
FROM        kagalpandh/kacpp-pydev
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
USER        root
EXPOSE      25 587 465 2525
VOLUME      ["/home/mail_users", "/usr/local/etc"]
# メールクライアントMSMTP用環境変数
ENV         MSMTP_VERSION=1.8.15
ENV         MSMTP_DEST=msmtp-${MSMTP_VERSION}
# rsyslog用環境変数
ENV         SYSLOG_GID=110
ENV         SYSLOG_UID=104
# Postfix用環境変数
ENV         POSTFIX_VERSION=3.5.2
ENV         POSTFIX_SRC=postfix-${POSTFIX_VERSION}
ENV         POSTFIX_DEST=${POSTFIX_SRC}
# Postfix用ユーザー・グループ
ENV         POSTFIX_GROUP=postfix
ENV         POSTDROP=postdrop
ENV         POSTFIX_USER=postfix
ENV         PF_GID=996
ENV         PD_GID=997
ENV         PF_UID=1003
ENV         IDENT_TRUST_CERT=lets-encrypt-r3-cross-signed.pem
RUN         mkdir /var/spool/postfix && mkdir /var/lib/postfix
COPY        --from=builder /usr/local/${MSMTP_DEST}/ /usr/local
COPY        --from=builder /usr/local/${POSTFIX_DEST}/usr/ /usr/local
COPY        --from=builder /usr/local/${POSTFIX_DEST}/etc/ /usr/local/etc
# COPY        --from=builder /usr/local/var/spool/postfix/ /var/spool/postfix
COPY        sh/  /usr/local/sh
COPY        supervisord.conf /root
COPY        .msmtprc /root
# https://letsencrypt.org/certs/lets-encrypt-r3-cross-signed.pem
RUN         apt update && \
            /usr/local/sh/system/apt-install.sh install mail-system.txt && \
            # rsyslog
            groupadd -g ${SYSLOG_GID} syslog && \
                useradd -u ${SYSLOG_UID} -s /bin/false -d /dev/null -g syslog -G syslog syslog && \
                chown -R root.syslog /var/log && chmod 3775 /var/log && \
            mkdir /var/log/mail && chown root.mail /var/log/mail && chmod 3775 /var/log/mail && ldconfig && \
#             mkdir /home/mail_users && \
            chown root.mail /home/mail_users && \
                chmod 3775 /home/mail_users
            # Postfixユーザー・グループ作成
RUN         groupadd -g ${PF_GID} ${POSTFIX_GROUP} && groupadd -g ${PD_GID} ${POSTDROP} && \
                useradd -u ${PF_UID} -s /bin/false -d /dev/null -g ${POSTFIX_GROUP} \
                    -G "${POSTFIX_GROUP},${POSTDROP}" ${POSTFIX_USER} && \
                chown -R ${POSTFIX_USER}.${POSTFIX_GROUP} /var/spool/postfix && \
            # Postfix ディレクトリ配置
            test -d '/usr/libexec' || mkdir -p /usr/libexec && \
                chown postfix.postfix /var/lib/postfix && chmod 3775 /var/lib/postfix && \
                ln -s /usr/local/libexec/postfix /usr/libexec/postfix && \
                ln -s /usr/local/etc/postfix /etc/postfix && \
                chown root.postdrop /usr/local/sbin/post* && \
                chmod 2755 /usr/local/sbin/postqueue && \
                chmod 2755 /usr/local/sbin/postdrop && \
            # エイリアス
            test -r /etc/aliases && rm -rf /etc/aliases && \
            ln -s /usr/local/etc/aliases /etc/aliases && \
                ln -s /usr/local/etc/aliases.db /etc/aliases.db && \
            # SMTP-AUTH
            # 通常SASLの設定ファイルsmtpd.confは/usr/lib/sasl2にあるが
            # これを/usr/local/etc/postfix内にあると仮定してリンクを張る
            ln -s  /usr/local/etc/postfix/smtpd.conf  /usr/lib/sasl2/smtpd.conf && \
            # SSL
            # SSLで大抵LetsEncryptを使用するためISRGが署名した証明書を配置しなくてはならない。
            # しかしISRGの証明書は大抵の暗いアアントにはないのでIdentTrustの署名した証明書を使用する。
            wget https://letsencrypt.org/certs/${IDENT_TRUST_CERT} && \
                cp ${IDENT_TRUST_CERT} /etc/ssl/certs && chmod 644 /etc/ssl/certs/${IDENT_TRUST_CERT}
            # Supervisor 複数のプロセスを管理する
            # 複数のサービスを管理するためsupervisorを使用する
#             dpkg --configure -a -y && \
RUN         apt install -y supervisor && \
                cp supervisord.conf /etc && \
            # ENTRYPOINT
            chmod 775 /usr/local/sh/system/mail-system.sh && \
            cd ~/ && apt clean && rm -rf /var/lib/apt/lists/* && rm *
COPY        rsyslog.conf /etc
COPY        default.conf /etc/rsyslog.d
# ENTRYPOINT  ["/usr/local/sh/system/mail-system.sh"]
