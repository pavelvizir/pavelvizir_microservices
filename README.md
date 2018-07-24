# pavelvizir_microservices  
pavelvizir microservices repository  

## Table of contents:  
- [Homework-12 aka 'docker-1'](#homework-12-aka-docker-1)  

## Homework-12 aka 'docker-1'  
#### Task \#1:  
##### Practice with docker. Print `docker images`.  

```sh
docker images | head -2
REPOSITORY                   TAG                 IMAGE ID            CREATED             SIZE
pavelvizir/ubuntu-tmp-file   latest              9224eef5176c        58 seconds ago      115MB
```

#### Task \#2\*:  
##### Docker inspect image and container. Tell the difference between them.  

> Recursive definition :-)  

Container = instance of image.  
Image = snapshot of container.  
