# culbenchmark
cuda linear solvers benchmark

## Install from Dockerfile
The dockerfile is based on Ubuntu 22.04
1. pull the image of cuda 13
```
    docker pull nvidia/cuda:13.0.1-devel-ubuntu22.04
```
2. build the template from Dockerfile
```
    docker build -t ${image_tag_name} .
```
3. run the interactive container
```
   docker run -dit \
  --ipc=host \
  --gpus all \
  --name ${container_name} \
  --privileged \
  -v /home/${user_name}:/home \
  -v /data/${user_name}:/data \
  ${image_name_from_template/tag}
```

Replace the placeholder with required value.

It will take about 460s on build.