


### Docker

1. follow the [instructions](https://docs.docker.com/desktop/mac/install/) to install docker.
2. open terminal and run: `docker pull postgres`
   
3. run `make init_docker` if you have not run before. You can find out the running container by run `docker ps`
```
CONTAINER ID   IMAGE      COMMAND                  CREATED          STATUS          PORTS                                       NAMES
bfcdd6369e89   postgres   "docker-entrypoint.s…"   19 minutes ago   Up 19 minutes   0.0.0.0:5433->5432/tcp, :::5433->5432/tcp   brave_bassi
```

4. run `make init_database`. It will create the database on the remote specified by DATABASE_URL. You can connect you database using 
pgAdmin.

![img_2.png](img_2.png)

The information you enter must be the same as the `make init_docker`. e.g.
```
export DB_USER=postgres
export DB_PASSWORD=password
export DB_NAME=flowy
export DB_PORT=5433
```

![img_1.png](img_1.png)

[Docker command](https://docs.docker.com/engine/reference/commandline/builder_prune/)

### Run
By default, Docker images do not expose their ports to the underlying host machine. We need to do it explicitly using the -p flag.
`docker run -p 8000:8000 backend`


### Sqlx

**Sqlx and Diesel commands** 
* create migration
    * sqlx: sqlx migrate add $(table)
    * diesel: diesel migration generation $(table)
    
* run migration
    * sqlx: sqlx migrate run
    * diesel: diesel migration run
    
* reset database
    * sqlx: sqlx database reset
    * diesel: diesel database reset

**offline mode**

`cargo sqlx prepare -- --bin backend`

**Type mapping**
* [postgres type map](https://docs.rs/sqlx/0.5.7/sqlx/postgres/types/index.html)
* [postgres and diesel type map](https://kotiri.com/2018/01/31/postgresql-diesel-rust-types.html)