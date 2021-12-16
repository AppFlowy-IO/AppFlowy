Note:
* This build is based on the Arch linux build
* Any Linux/ Mac machine should work, because you need to 
`xhost local:root` I'm not sure if Windows support this

# Steps:

## Step 1: cd into docker-buildfiles
------------------------------
cd ./doc/docker-buildfiles && xhost local:root

## Step 2: build the docker image
------------------------------
docker-compose build

## Step 3: run the docker container
------------------------------
docker-compose up