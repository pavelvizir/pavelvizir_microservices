# pavelvizir_microservices  
pavelvizir microservices repository  

[![Build Status](https://travis-ci.com/Otus-DevOps-2018-05/pavelvizir_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-05/pavelvizir_microservices)

# Table of contents:  
- [Homework-12 aka 'docker-1'](#homework-12-aka-docker-1)  
- [Homework-13 aka 'docker-2'](#homework-13-aka-docker-2)  
- [Homework-14 aka 'docker-3'](#homework-14-aka-docker-3)  
- [Homework-15 aka 'docker-4'](#homework-15-aka-docker-4)  
- [Homework-16 aka 'gitlab-ci-1'](#homework-16-aka-gitlab-ci-1)  

## Homework-12 aka 'docker-1'  
### Task \#1:  
#### Practice with docker. Print `docker images`.  

```sh
docker images | head -2
REPOSITORY                   TAG                 IMAGE ID            CREATED             SIZE
pavelvizir/ubuntu-tmp-file   latest              9224eef5176c        58 seconds ago      115MB
```

### Task \#2\*:  
#### Docker inspect image and container. Tell the difference between them.  

> Recursive definition :-)  

Container = instance of image.  
Image = snapshot of container.  

## Homework-13 aka 'docker-2'  
### Task \#1:  
#### Start docker-host in GCE. Play with `'--pid host'`.  

```sh
export GOOGLE_PROJECT=<project>
docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host
eval $(docker-machine env docker-host)
docker run --rm -ti tehbilly/htop
docker run --rm --pid host -ti tehbilly/htop
```
`--pid host` allows to see host's environment from inside container.

### Task \#2:  
#### Create image with Dockerfile and upload to docker-hub. Play with container.  

1. Create `Dockerfile`  
2. `docker build -t reddit:latest .`  
3. `docker login`  
4. `docker tag reddit:latest pavelvizir/otus-reddit:1.0`  
5. `docker push pavelvizir/otus-reddit:1.0`  
6. `docker run --name reddit -d -p 9292:9292 pavelvizir/otus-reddit:1.0`  
7. `docker stop reddit && docker rm reddit`  

### Task \#3\*:  
#### Automate creation of docker-daemon hosts in GCE.  

> `mkdir infra && cd infra`  

1. Terraform:  
  - Create terraform configs  
  - `terraform validate`  
  - `tflint`  
2. Ansible:  
  - Create ansible playbooks  
  - Create ansible config  
  - Configure dynamic inventory  
  - `ansible-lint -v \*.yml`  
3. Packer:  
  - Create packer ansible playbook  
  - Create packer configs  
  - `packer validate --var-file=variables.json docker.json`  

> Now there are 2 scenarios of preparing docker container in VMs in GCE:  

1. *Without* `packer`:
```sh
terraform apply -auto-approve -var project="docker-XXXXXX"
ansible-playbook docker.yml
```
2. *With* `packer`:
```sh
packer build -var 'project_id=docker-XXXXXX' --var-file=variables.json docker.json
terraform apply -auto-approve -var project="docker-XXXXXX" -var image="docker-host" 
ansible-playbook run_docker_container.yml
```

> And don't forget to edit .gitignore  

```sh
echo '*.tfstate
*.tfstate.*.backup
*.tfstate.backup
.terraform/
*.retry
__pycache__
secrets.py'\
>> ../../.gitignore
```

## Homework-14 aka 'docker-3'  
### Task \#1:  
#### Practice with docker, docker build, hadolint, bridge-network for containers.  
> Add ignores to hadolint.
```sh
echo 'ignore:
  - DL3008' \
> .hadolint.yaml
```

### Task \#2\*:  
#### Rerun containers with different nework aliases.  
 
```sh
docker run -d --network=reddit --network-alias=post_db_2 --network-alias=comment_db_2 mongo:latest
docker run -d --network=reddit --network-alias=post_2 --env POST_DATABASE_HOST=post_db_2 pavelvizir/post:1.0
docker run -d --network=reddit --network-alias=comment_2 --env COMMENT_DATABASE_HOST=comment_db_2 pavelvizir/comment:1.0
docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=post_2 --env COMMENT_SERVICE_HOST=comment_2 pavelvizir/ui:1.0
```

### Task \#3\*:  
#### Make images smaller.  
> Use alpine etc.  

Well, pretty obvious:  
 * use smaller base image
 * clean caches
 * remove build tools afterwards
 * play with order of steps if build speed not important

Made following images smaller:
 - comment
 - ui
 - mongo

Example *(ui)*:
```yaml
FROM alpine:3.7
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/
RUN apk --update add --no-cache \
    ruby \
    ruby-dev \
    ruby-bundler \
    build-base \
    && bundle install \
    && apk del \
    ruby-bundler \
    build-base \
    ruby-dev \
    && rm -rf /var/cache/apk

COPY . $APP_HOME

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
```

Final docker images creation, containers run and test looks like that:
```sh
export GOOGLE_PROJECT=<project name>
docker-machine create --driver google \
 --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
 --google-machine-type n1-standard-1 \
 --google-zone europe-west1-b \
 docker-host
eval $(docker-machine env docker-host)
docker network create reddit
docker volume create reddit_db
docker build -t pavelvizir/post:1.0 ./post-py
docker build -t pavelvizir/comment:3.0 -f comment/Dockerfile.3 ./comment
docker build -t pavelvizir/ui:4.0 -f ui/Dockerfile.3 ./ui
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db -v reddit_db:/data/db mvertes/alpine-mongo:latest
docker run -d --network=reddit --network-alias=post pavelvizir/post:1.0
docker run -d --network=reddit --network-alias=comment pavelvizir/comment:3.0
docker run -d --network=reddit -p 9292:9292 pavelvizir/ui:4.0
```

## Homework-15 aka 'docker-4'  
### Task \#1:  
#### Why multiple nginx containers with host network doesn't work?  

Answer is: they try to bind to the same port.  

```sh
for i in $(seq 1 4); do docker run --network host -d nginx; done
docker ps | wc -l
> 2
docker logs $(docker ps -aq| tail -2 | head -1)
> nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
> 2018/08/03 11:30:41 [emerg] 1#1: bind() to 0.0.0.0:80 failed (98: Address already in use)
```

### Task \#2:  
#### Docker-compose: add multiple *networks*, parametrize *ui port* and *service versions*, create *.env* file.

```yaml
version: '3.3'
services:
  post_db:
    image: mvertes/alpine-mongo:${post_db_version}
    volumes:
      - post_db:/data/db
    networks:
      - back_net
  ui:
    build:
      context: ./ui
      dockerfile: Dockerfile.3
    image: ${USERNAME}/ui:${ui_version}
    ports:
      - ${ui_port}:${ui_port}/tcp
    networks:
      - front_net
  post:
    build: ./post-py
    image: ${USERNAME}/post:${post_version}
    networks:
      - front_net
      - back_net
  comment:
    build:
      context: ./comment
      dockerfile: Dockerfile.3
    image: ${USERNAME}/comment:${comment_version}
    networks:
      - front_net
      - back_net

volumes:
  post_db:

networks:
  front_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.1.0/24
  back_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 10.0.2.0/24
```
 
```sh
echo '.env' >> ../.gitignore
```
### Task \#3:  
#### Docker-compose: how to determine project name, how to set it.  

>  -p, --project-name NAME     Specify an alternate project name  
>                              (default: directory name)   

### Task \#4\*:  
#### Docker-compose: override app's scripts, override puma start with flags "--debug" and "-w 2".  

> Using 2 ways to do it. Second IMO is better in most cases:  
>  1. mount over existing file  
>  2. mount to another dir and copy **if source exists**   

```yaml
version: '3.3'
services:
  ui:
    # docker-machine scp ui/ui_app.rb docker-host:/home/docker-user/
    volumes:
      - /home/docker-user/ui_app.rb:/app/ui_app.rb 
    command: ["puma", "--debug", "-w", "2"] 
  post:
    # this way is better, as you don't have to place file in place
    volumes:
      - /home/docker-user/post:/post
    entrypoint: sh -c "[ -f /post/post_app.py ] && cp /post/post_app.py /app/; exec python3 post_app.py"
  comment:
    # docker-machine scp comment/comment_app.rb docker-host:/home/docker-user/      
    volumes:
      - /home/docker-user/comment_app.rb:/app/comment_app.rb 
    command: ["puma", "--debug", "-w", "2"] 
```

## Homework-16 aka 'gitlab-ci-1'  
### Task \#1:  
#### Create gitlab-ci host with omnibus.  

Standard way with `terraform` and `ansible`:  
[repo/gitlab-ci/deploy](https://github.com/Otus-DevOps-2018-05/pavelvizir_microservices/tree/gitlab-ci-1/gitlab-ci/deploy)  

```sh
cd gitlab-ci/deploy
terraform apply -var project="docker-xxxxxx"
ansible-playbook gitlab-ci.yml
```

If you stop and start again VM:  
```sh
terraform refresh -var project="docker-xxxxxx"
ansible-playbook start_gitlab-ci.yml
```

### Task \#2\*:  
#### Create runner install automation.

```yaml
---
- name: register gitlab-ci address
  hosts: localhost
  tasks:
    - shell: terraform output gitlab-ci-host_external_ip
      register: shell_output

    - debug:
        msg: "{{ shell_output.stdout }}"

- name: Start gitlab-ci runner(s)
  hosts: all
  become: true
  vars:
    runner_name: "gitlab-runner{{ runner_suffix | default('') }}"
    runner_token: "{{ runner_token }}"

  tasks:
    - debug:
        msg: "runner_token is required"
      failed_when: runner_token is not defined

    - name: make sure docker is started
      service:
        name: docker
        state: started

    - name: create config dir just in case
      file:
        state: directory
        path: '/srv/{{ runner_name }}'

    - name: start runner
      docker_container:
        name: "{{ runner_name }}"
        image: "gitlab/gitlab-runner:latest"
        volumes:
          - "/srv/{{ runner_name }}/config:/etc/gitlab-runner"
          - "/var/run/docker.sock:/var/run/docker.sock"
        state: started
        restart: yes
        restart_policy: always
      tags: run

    - name: register runner
      raw: >
        docker exec -it {{ runner_name }} gitlab-runner register \
        --non-interactive \
        --executor "docker" \
        --docker-image alpine:latest \
        --url "http://{{ hostvars['localhost']['shell_output']['stdout'] }}/" \
        --registration-token "{{ runner_token }}" \
        --description "{{ runner_name }}" \
        --tag-list "linux,xenial,ubuntu,docker" \
        --run-untagged \
        --locked="false"
```

### Task \#3\*:  
#### Create gitlab-ci slack integration.  

*Gitlab-ci* project settings -> integrations -> slack notifications -> active, add webhook url, process to slack webhook link, test results  
*Slack* Enable webhook, enjoy integration  

