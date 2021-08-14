# Makefile for building se-ingest-router
AWS_ACCT ?= 519479409477
REGION ?= us-gov-west-1
ORG ?= 519479409477.dkr.ecr.us-gov-west-1.amazonaws.com
REPO ?= pms-docker
APPNAME ?= $(REPO)
ENVIRONMENT ?= development
SHA ?= $(shell git rev-parse --short HEAD)
BRANCH ?= $(shell git rev-parse --symbolic-full-name --abbrev-ref HEAD)
DOCKER_BRANCH ?= $(subst /,-,$(BRANCH))
DOCKER_TAG ?= $(ENVIRONMENT)-$(DOCKER_BRANCH)-$(SHA)
DOCKER_REPO ?= $(AWS_ACCT).dkr.ecr.$(REGION).amazonaws.com/$(APPNAME)
DOCKER_IMG ?= $(DOCKER_REPO):$(DOCKER_TAG)
NAMESPACE ?= default

TIMEZONE ?= America/Chicago
CLAIM_TOKEN ?= claim-eXynVdd7JD9j_oPCLSXs
PLEX_DB_DIR ?= my_plex_db
PLEX_TRANSCODE_DIR ?= my_plex_transcoders
PLEX_MEDIA_DIR ?= /Volumes/bigdisk2/AllPics

all: build push

login:
	aws ecr \
		get-login-password \
		--region $(REGION) | \
		docker login \
		--username AWS \
		--password-stdin $(AWS_ACCT).dkr.ecr.$(REGION).amazonaws.com

build:
	docker build \
		--no-cache=true \
		--force-rm \
		--network=host \
		--build-arg NPM_TOKEN=$(NPM_TOKEN) \
		-t $(DOCKER_REPO):$(APPNAME)-$(ENVIRONMENT)-latest \
		-t $(DOCKER_IMG) .

push:
	docker push $(DOCKER_IMG)
	docker push $(DOCKER_REPO):$(APPNAME)-$(ENVIRONMENT)-latest

run:
	docker run \
		-i \
		--name plex \
		-p 32400:32400/tcp \
		-p 3005:3005/tcp \
		-p 8324:8324/tcp \
		-p 32469:32469/tcp \
		-p 1900:1900/udp \
		-p 32410:32410/udp \
		-p 32412:32412/udp \
		-p 32413:32413/udp \
		-p 32414:32414/udp \
		-e TZ="$(TIMEZONE)" \
		-e PLEX_CLAIM="$(CLAIM_TOKEN)" \
		-e ADVERTISE_IP="http://localhost:32400/" \
		-h localhost \
		-v $(PLEX_DB_DIR):/config \
		-v $(PLEX_TRANSCODE_DIR):/transcode \
		-v $(PLEX_MEDIA_DIR):/data \
		plexinc/pms-docker

test:
	npm install craco && \
		yarn test:ci
