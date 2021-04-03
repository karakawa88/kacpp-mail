# PstgreSQL環境を持つdebianイメージ
# 日本語化も設定済み
FROM        kagalpandh/kacpp-gccdev AS builder
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
ENV         DEBIAN_FORONTEND=noninteractive
ENV         POSTGRES_VERSION=13.2
ENV         POSTGRES_SRC=postgresql-${POSTGRES_VERSION}
ENV         POSTGRES_SRC_FILE=${POSTGRES_SRC}.tar.bz2
ENV         POSTGRES_URL="https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/${POSTGRES_SRC_FILE}"
ENV         POSTGRES_DEST=${POSTGRES_SRC}
ENV         PGHOME=/usr/local/${PYTHON_DEST}
ENV         PATH=${PYTHON_HOME}/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
ENV         LD_LIBRARY_PATH=${PYTHON_HOME}/lib
# 開発環境インストール
RUN         apt update \
            && /usr/local/sh/system/apt-install.sh install gccdev.txt \
            && wget ${POSTGRES_URL} && tar -jxvf ${POSTGRES_SRC_FILE} && cd ${POSTGRES_SRC} \
                &&  ./configure --prefix=/usr/local/${POSTGRES_DEST} --enable-shared --with-openssl \
                && make && make install  \
                && cd contrib/pgcrypto && make && make install \
            && /usr/local/sh/system/apt-install.sh uninstall gccdev.txt \
                && apt autoremove -y && apt clean && rm -rf /var/lib/apt/lists/* \
                && cd ../ && rm -rf ${POSTGRES_DEST}*
FROM        kagalpandh/kacpp-pydev
SHELL       [ "/bin/bash", "-c" ]
WORKDIR     /root
USER        root
EXPOSE      5432
VOLUME      ["/home/data"]
ENV         POSTGRES_VERSION=13.2
ENV         POSTGRES_DEST=postgresql-${POSTGRES_VERSION}
#PostgreSQL用環境変数
ENV         PGHOME=/usr/local/${POSTGRES_DEST}
ENV         PGDATA=/home/data/pgdata
ENV         PATH=${PGHOME}/bin:/usr/local/python/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
#postgresユーザー・グループ
ENV         PG_GROUP=postgres
ENV         PG_USER=postgres
ENV         PG_GID=990
ENV         PG_UID=1008
RUN         mkdir /usr/local/${POSTGRES_DEST}
COPY        --from=builder /usr/local/${POSTGRES_DEST}/ /usr/local/${POSTGRES_DEST}
COPY        rcprofile /etc/rc.d
RUN         apt update && \
#   porgでPythonをパッケージ管理
#             chown -R root.root /usr/local && \
#             find ${PYTHON_HOME} -type f -print | xargs porg -l -p ${PYTHON_DEST} && \
            mkdir /home/data && chown root.root /home/data && chmod 755 /home/data && \
            ln -s ${PGHOME} /usr/local/postgres && \
            echo "${PGHOME}/lib" >>/etc/ld.so.conf && ldconfig && \
            groupadd -g ${PG_GID} ${PG_GROUP} && \
                useradd -u ${PG_UID} -m -d /home/${PG_USER} -s /bin/bash -g ${PG_GROUP} \ 
                -G ${PG_GROUP} ${PG_USER} && \
            chown -R ${PG_USER}.${PG_GROUP} /usr/local/${PGDEST} && \
                mkdir /var/log/postgres && chown -R ${PG_USER}.${PG_GROUP} /var/log/postgres && \ 
                chmod 750 /var/log/postgres && \
            cd ~/ && apt clean && rm -rf /var/lib/apt/lists/*
RUN         mkdir -p /usr/local/sh/postgres
COPY        postgres-entrypoint.sh /usr/local/sh/postgres/postgres-entrypoint.sh
RUN         chown -R ${PG_USER}.${PG_GROUP} /usr/local/sh/postgres && \ 
                chmod 3775 /usr/local/sh/postgres && \
                chmod 775 /usr/local/sh/postgres/postgres-entrypoint.sh
ENTRYPOINT  /usr/local/sh/postgres/postgres-entrypoint.sh
