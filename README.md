# kacpp-postgres DBのPostgreSQL環境Dockerイメージ

## 概要
PostgreSQLをソースからインストールして設定したDockerイメージ。
現在のPostgreSQLのソースは13.2である。
debian:buster-slimイメージを基に作成されている。

## 使い方
```shell
docker image pull kagalpandh/kacpp-postgres
docker run -dit --name kacpp-postgres -v /home/data:/home/data kagalpandh/kacpp-postgres
docker run -dit --name kacpp-postgres -v /home/data:/home/data -e PGDATA=/home/data/pgdata kagalpandh/kacpp-postgres
```

## 説明
PostgreSQLサーバーをソースからインストールしてある。
現在のPostgreSQLサーバーのバージョンは13.2である。
EXPOSE(開いているポート)の5432を使用している。
VOLUME(永続化ストレージ)に/home/dataにマウントすること。
そしてデフォルトでは/home/data/pgdataにデーターベースクラスタがあると期待している。
データーベースクラスタの場所はPGDATA環境変数で指定できる。
データーベースの管理者ユーザーpostgresが既に入っておりこのユーザーでDBにログインできる。
他のユーザーは作成していない。

##構成
環境変数
PGHOME  PostgreSQLが入っているディレクトリ。
PGDATA  データーベースクラスタ領域
管理者ユーザー postgres

##ベースイメージ
kagalpandh/kacpp-pydev

# その他
DockerHub: [kagalpandh/kacpp-postgres](https://hub.docker.com/repository/docker/kagalpandh/kacpp-postgres)<br />
GitHub: [karakawa88/kacpp-postgres](https://github.com/karakawa88/kacpp-postgres)

