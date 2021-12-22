# Steps:

## Step 1: clone the repository

```{bash}
git clone https://github.com/AppFlowy-IO/appflowy.git
```

## Step 2: cd into docker-buildfiles

```{bash}
cd ./appflowy/doc/docker-buildfiles
```

## Step 3: Provide access of appflowy to X session

```{bash}
xhost local:root
```

## Step 4: build the docker image

```{bash}
docker-compose build
```

## Step 5: run the docker container

```{bash}
docker-compose up
```

### Note:-

-   This build is based on the Arch linux build
-   Any Linux/ Mac machine should work, because you need to
    `xhost local:root` I'm not sure if Windows support this
-   There is no need of cloning the whole repo, you can also create a new directory and paste the Dockerfile and docker-compose.yml from `appflowy/doc/docker-buildfiles`.

-   Once the docker image has been built, `docker-compose up` from the directory would be enough to run the appflowy container next time.
