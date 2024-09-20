PWD=$(shell pwd)
UID=$(shell id -u):$(shell id -g)

REGISTRY_BASE=registry.digitalocean.com/four-pm-docker
IMAGE_NAME=4pm-gocd-agent-dind
IMAGE_TAG=1.0.1

all: login build push logout

print:
	echo "UID ${UID}"

build:
	docker build  \
		--progress plain \
		--no-cache \
		--tag ${REGISTRY_BASE}/${IMAGE_NAME}:${IMAGE_TAG} .

login:
	docker login -u ${DOCKER_TOKEN} -p ${DOCKER_TOKEN} ${REGISTRY_BASE}

logout:
	docker logout ${REGISTRY_BASE}

push:
	docker push ${REGISTRY_BASE}/${IMAGE_NAME}:${IMAGE_TAG}

images:
	curl -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${DOCKER_TOKEN}" \
    "https://api.digitalocean.com/v2/registry/four-pm-docker/repositories/${IMAGE_NAME}/tags" | jq

run-bash:
	docker run --entrypoint /bin/sh  -it --rm ${REGISTRY_BASE}/${IMAGE_NAME}:${IMAGE_TAG} 