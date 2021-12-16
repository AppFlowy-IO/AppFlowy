Note:
* This build is based on the Arch linux build
* Any Linux/ Mac machine should work, because you need to 
`xhost local:root` I'm not sure if Windows support this

# Steps:

## Step 1: cd into docker-buildfiles
------------------------------
cd ./doc/docker-buildfiles 

## Step 2: Provide access of appflowy to X session
------------------------------
xhost local:root

## Step 3: build the docker image
------------------------------
docker-compose build

## Step 4: run the docker container
------------------------------
docker-compose up