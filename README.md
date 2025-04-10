# docker-radiation-store
A docker file to use the MCAPL tools with the EEE radiation store gazebo simulation

## Build docker image

If on a mac:

```docker buildx build --platform linux/arm64 -t docker-radiation-store .
```

if on a linux machine

```
docker buildx build --platform linux/amd64 -t docker-radiation-store .
```


## Run docker image

```bash
docker run -p 6080:80 --security-opt seccomp=unconfined --shm-size=512m docker-radiation-store
```
