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
