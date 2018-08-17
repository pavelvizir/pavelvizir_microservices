# pavelvizir_microservices  
pavelvizir microservices repository  

# Table of contents:  
- [Homework-12 aka 'docker-1'](#homework-12-aka-docker-1)  
- [Homework-13 aka 'docker-2'](#homework-13-aka-docker-2)  

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
