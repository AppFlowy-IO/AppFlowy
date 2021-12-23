### Note:-

-   Make sure you already have docker and docker-compose fully working before this. For Arch you can read here [Docker Arch linux docs](https://wiki.archlinux.org/title/Docker)
-   Don't forget to add your username to docker group to run docker without sudo. To do that, on Arch,
    `sudo usermod -aG docker yoursername` and reboot is a must.
-   This build is also based on the Arch linux build
-   Any Linux/ Mac machine should work, because you need to
    `xhost local:root` I'm not sure if Windows support this
-   There is no need of cloning the whole repo, you can also create a new directory and paste the Dockerfile and docker-compose.yml from `appflowy/doc/docker-buildfiles`.

-   Once the docker image has been built, `docker-compose up` from the directory would be enough to run the appflowy container next time.

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
