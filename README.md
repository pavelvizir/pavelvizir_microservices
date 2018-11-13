# pavelvizir_microservices  
pavelvizir microservices repository  

[![Build Status](https://travis-ci.com/Otus-DevOps-2018-05/pavelvizir_microservices.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2018-05/pavelvizir_microservices)

[Link to docker hub](https://hub.docker.com/r/pavelvizir)

# Table of contents:  
- [Homework-12 aka 'docker-1'](#homework-12-aka-docker-1)  
- [Homework-13 aka 'docker-2'](#homework-13-aka-docker-2)  
- [Homework-14 aka 'docker-3'](#homework-14-aka-docker-3)  
- [Homework-15 aka 'docker-4'](#homework-15-aka-docker-4)  
- [Homework-16 aka 'gitlab-ci-1'](#homework-16-aka-gitlab-ci-1)  
- [Homework-17 aka 'gitlab-ci-2'](#homework-17-aka-gitlab-ci-2)  
- [Homework-18 aka 'monitoring-1'](#homework-18-aka-monitoring-1)  
- [Homework-19 aka 'monitoring-2'](#homework-19-aka-monitoring-2)  
- [Homework-20 aka 'logging-1'](#homework-20-aka-logging-1)  
- [Homework-21 aka 'kubernetes-1'](#homework-21-aka-kubernetes-1)  
- [Homework-22 aka 'kubernetes-2'](#homework-22-aka-kubernetes-2)  
- [Homework-23 aka 'kubernetes-3'](#homework-23-aka-kubernetes-3)  
- [Homework-24 aka 'kubernetes-4'](#homework-24-aka-kubernetes-4)  
- [Homework-25 aka 'kubernetes-5'](#homework-25-aka-kubernetes-5)  

## Homework-12 aka 'docker-1'  
### Task \#1:  
#### Practice with EFK, zipkin.

```sh
export GOOGLE_PROJECT=docker-xxxxxx
docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-open-port 5601/tcp \
    --google-open-port 9292/tcp \
    --google-open-port 9411/tcp \
    logging
eval $(docker-machine env logging)
for i in ui post-py comment; do cd src/$i; bash docker_build.sh && docker push pavelvizir/$i; cd -; done
export USER_NAME=pavelvizir
docker-compose -f docker-compose-logging.yml up -d
docker-compose up -d

firefox http://$(docker-machine ip logging):5601
firefox http://$(docker-machine ip logging):9411

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

## Homework-17 aka 'gitlab-ci-2'  
### Task \#1\*:  
#### New server should be created with new branch push.  

> Haven't completed this task. Almost done, but it requires DNS-control to work flawlessly.  
> Would require adding curl commands to .gitlab-ci.yml...  

Created simple python [Flask](http://flask.pocoo.org/) application with simple API. Passing POST parameter 'name' creates server with that name and deploys needed `docker` container.

How it works:
 1. `terraform` creates 'gitlab-ci-server-spawn-host' with [server_spawn_host.tf](https://github.com/Otus-DevOps-2018-05/pavelvizir_microservices/blob/gitlab-ci-2/gitlab-ci/deploy/server_spawn_host.tf)  
 2. `ansible` prepares 'gitlab-ci-server-spawn-host' with [start_server_spawn_host.yml](https://github.com/Otus-DevOps-2018-05/pavelvizir_microservices/blob/gitlab-ci-2/gitlab-ci/deploy/start_server_spawn_host.yml):  
   - install `terraform` and `ansible`  
   - copy all the ssh keys and project.json  
   - start systemd user [service](https://github.com/Otus-DevOps-2018-05/pavelvizir_microservices/blob/gitlab-ci-2/gitlab-ci/deploy/service.py) with python Flask [application](https://github.com/Otus-DevOps-2018-05/pavelvizir_microservices/blob/gitlab-ci-2/gitlab-ci/deploy/server-spawn-service.service)  
 3. `curl` from .gitlab-ci.yml [creates](http://35.241.213.116:9999/create) or [destroys](http://35.241.213.116:9999/destroy) server for each branch.  
   - Complete `terraform` and `ansible` output returns with reply from Flask application.  
 4. Server for branch is created and docker container started:
   - For now it's [nginxdemos/hello](https://github.com/Otus-DevOps-2018-05/pavelvizir_microservices/blob/gitlab-ci-2/gitlab-ci/deploy/files/run_docker_container.yml) on port 80.
   - In future it should be container with application `reddit` from branch. 

```sh
terraform apply -var project=docker-xxxxxx
ansible-playbook base.yml --limit=gitlab-ci-server-spawn-host
ansible-playbook start_server_spawn_host.yml
curl -d 'name=branch_12345' -X POST http://35.241.213.116:9999/create
curl -d 'name=branch_12345' -X POST http://35.241.213.116:9999/destroy
```

## Homework-18 aka 'monitoring-1'  
### Task \#1\*:  
#### Add blackbox_exporter monitoring  

 1. Add blackbox.yml config:  
```yaml
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      method: GET
      fail_if_not_matches_regexp:
        - "All posts"
  tcp_connect:
    prober: tcp
    timeout: 5s
```
 2. Add blackbox config to prometheus.yml:  
```yaml
  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - http://ui:9292
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox_exporter:9115
  - job_name: 'blackbox-tcp'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets:
        - post:5000
        - comment:9292
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox_exporter:9115
```
 3. Add Dockerfile to build blackbox_exporter with config  
 4. Add blackbox_exporter to docker-compose.yml

### Task \#2\*:  
#### Create makefile to build and push images

makefile.config:
```
USERNAME=username
PROJECTS=ui comment post-py prometheus blackbox_exporter
```

makefile:
```make
.DEFAULT_GOAL := help
.PHONY: build push all help
cnf ?= makefile.config
include $(cnf)
BUILD_LIST = $(addprefix build_,$(PROJECTS))
PUSH_LIST = $(addprefix push_,$(PROJECTS))
build:  $(BUILD_LIST)			## Build all PROJECTS 
push:   $(PUSH_LIST)			## Push all PROJECTS 
all:	$(BUILD_LIST) $(PUSH_LIST)	## Build and push PROJECTS
help:					## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+\%?:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo -e '\nVariables used:'
	@cat $(cnf)
build_%:				## Build images from % directory
	@project=$$(find . -maxdepth 2 -type d -name $*); \
	if [ ! -z "$$project" ]; then \
	 if [ -f "$$project/Dockerfile" ]; then \
	  if [ -f "$$project/docker_build.sh" ]; then \
	   echo `git show --format="%h" HEAD | head -1` > "$$project/build_info.txt"; \
	   echo `git rev-parse --abbrev-ref HEAD` >> "$$project/build_info.txt"; \
	  fi; \
	   docker build -t $(USERNAME)/$* -f "$$project/Dockerfile" "$$project"; \
	 else \
	  echo "no dockerfile"; false; \
	 fi;  \
	else \
	  echo "no project"; false; \
	fi
push_%:					## Push USERNAME/% image if it exists
	@docker images "$(USERNAME)\/$*" --format "{{.Repository}}" | grep -i "$(USERNAME)\/$*" >/dev/null
	@docker push $(USERNAME)/$*
```

## Homework-19 aka 'monitoring-2'  
### Task \#1:  
#### Practice with cAdvisor, Grafana, Alertmanager.  

```sh
gcloud compute firewall-rules create prometheus-default --allow tcp:9090
gcloud compute firewall-rules create puma-default --allow tcp:9292
gcloud compute firewall-rules create cadvisor-default --allow tcp:8080
gcloud compute firewall-rules create grafana-default --allow tcp:3000
gcloud compute firewall-rules create alertmanager-default --allow tcp:9093
export GOOGLE_PROJECT=docker-xxxxxx
docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-zone europe-west1-b \
    docker-host
eval $(docker-machine env docker-host)
make build
cd docker & docker-compose up -d
docker-compose -f docker-compose-monitoring.yml up -d

firefox http://$(docker-maching ip docker-host):3000
```

## Homework-20 aka 'logging-1'  
### Task \#1:  
#### Practice EFK, zipkin.

```sh
export GOOGLE_PROJECT=docker-xxxxxx
docker-machine create --driver google \
    --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
    --google-machine-type n1-standard-1 \
    --google-open-port 5601/tcp \
    --google-open-port 9292/tcp \
    --google-open-port 9411/tcp \
    logging
eval $(docker-machine env logging)
export USER_NAME=pavelvizir
for i in ui post-py comment; do cd src/$i; bash docker_build.sh && docker push pavelvizir/$i; cd -; done
docker-compose -f docker-compose-logging.yml up -d
docker-compose up -d
firefox http://$(docker-machine ip logging):5601
firefox http://$(docker-machine ip logging):9411
```

## Homework-21 aka 'kubernetes-1'  
### Task \#1:  
#### Kubernetes the Hard Way.  
Create deployment configs for `ui`, `comment`, `post-py`, `mongo`.  

Complete https://github.com/kelseyhightower/kubernetes-the-hard-way  

Just before the last step "Cleaning up" test reddit deployment creation:  
```sh
kubectl apply -f mongo-deployment.yml
kubectl apply -f post-deployment.yml
kubectl apply -f ui-deployment.yml
kubectl apply -f comment-deployment.yml
kubectl get pods 
### NAME                                  READY   STATUS    RESTARTS   AGE
### busybox-bd8fb7cbd-g9hrt               1/1     Running   1          69m
### comment-deployment-6dcbf5cbf5-7q4rj   1/1     Running   0          2m
### mongo-deployment-78fd9f6c74-vzrpl     1/1     Running   0          17m
### nginx-dbddb74b8-p548d                 1/1     Running   0          42m
### post-deployment-8ff86549-j7b7p        1/1     Running   0          16m
### ui-deployment-75dd97656f-v79cb        1/1     Running   0          16m
### untrusted                             1/1     Running   0          33m
```

Then remove the cluster.  

## Homework-22 aka 'kubernetes-2'  
### Task \#1:  
#### Create minikube cluster and start reddit there.  

```sh
minikube start
cd kubernetes/reddit
kubectl apply -f dev-namespace.yml
kubectl apply -n dev -f ./
# minikube delete
```

> Valuable command: `kubectl --validate=true --dry-run=true -f \<filename\>`

### Task \#2:  
#### Create GKE cluster and start reddit there.  

Same as minikube :-)

### Task \#3:
#### Connect to GKE dashboard.

```sh
kubectl create clusterrolebinding kubernetes-dashboard  --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
kubectl proxy
```

## Homework-23 aka 'kubernetes-3'  
### Task \#1:  
#### Practice with kubernetes.  

 * Kube-dns
 * Services (nodePort, LoadBalancer)
 * TLS, secret
 * NetworkPolicy
 * Volume, PersistentVolume, PersistentVolumeClaim
 * StorageClass

```sh
kubectl get secret ui-ingress -o yaml -n dev > secret.yml
vim secret.yml
```

```sh
cd kubernetes/reddit
kubectl apply -f dev-namespace.yml
kubectl apply -n dev -f ./
```

## Homework-24 aka 'kubernetes-4'  
### Task \#1:  
#### Practice with helm.

```sh
kubectl apply -f tiller.yml
helm init --service-account tiller
helm install reddit --name reddit-test
helm ls
helm delete --purge reddit-test
```

### Task \#2:
#### Practice with CI/CD in Kubernetes with Gitlab-CI.

```sh
helm repo add gitlab https://charts.gitlab.io
helm fetch gitlab/gitlab-omnibus --version 0.1.37 --untar
# make changes to configs
cd gitlab-omnibus && helm install --name gitlab . -f values.yaml
# prepare pipeline, add lines to /etc/hosts
firefox http://<your_branches_names>
```

## Homework-25 aka 'kubernetes-5'  
### Task \#1:  
#### Install Prometheus, configure node-exporter  

```sh
helm install stable/nginx-ingress --name nginx
kubectl get svc
echo '1.2.3.4 reddit reddit-prometheus reddit-grafana reddit-non-prod production reddit-kibana staging prod' | sudo tee -a /etc/hosts
cd kubernetes/charts && helm fetch --untar stable/prometheus
cd prometheus
helm upgrade prom . -f custom_values.yml --install
firefox http://reddit-prometheus
vim custom_values.yaml
# nodeExporter:
#   enabled: true
helm upgrade prom ./prometheus -f prometheus/custom_values.yml --install
```

### Task \#2:  
#### Separate 'reddit-endpoints' config into 3 jobs  

> Example with ui:  
```yaml
      - job_name: 'ui-endpoints'
        kubernetes_sd_configs:
          - role: endpoints
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_service_label_app, __meta_kubernetes_service_label_component]
            action: keep
            regex: reddit;ui
          - source_labels: [__meta_kubernetes_namespace]
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            target_label: kubernetes_name
```

### Task \#3:  
#### Change grafana's previous dashboards to use templating  

> Example with UI_Service_Monitoring "UI HTTP Requests"  

ui_request_count ->
ui_request_count{kubernetes_namespace=~"$namespace"}

### Task \#4:  
#### Start EFK  

```sh
kubectl label node gke-unbroken-default-pool-7220c9cd-j5fp elastichost=true
mkdir efk && cd efk
# wget multiple *.yaml
kubectl apply -f ./efk
helm upgrade --install kibana stable/kibana \
--set "ingress.enabled=true" \
--set "ingress.hosts={reddit-kibana}" \
--set "env.ELASTICSEARCH_URL=http://elasticsearch-logging:9200" \
--version 0.1.1
# wait for kibana to start, create index
firefox http://reddit-kibana
```
