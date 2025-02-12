SHELL=/bin/bash

RELEASE_VERSION:=$(shell cat VERSION_RELEASE)
OVAI_VERSION:=$(shell cat VERSION_OVAI)
CHART_VERSION:=$(shell cat VERSION_CHART)

OWNER:=asaintsever
REPO:=open-vault-agent-injector
TARGET_WEBHOOK:=target/vaultinjector-webhook
TARGET_ENV:=target/vaultinjector-env
IMAGE_FQIN:=asaintsever/open-vault-agent-injector

# Inject OVAI version into code at build time
LDFLAGS=-ldflags "-X=main.VERSION=$(OVAI_VERSION)"

.SILENT: ;  	# No need for @
.ONESHELL: ; 	# Single shell for a target (required to properly use local variables)
.PHONY: all clean test build-ovai-webhook build-ovai-env build package image image-from-build release
.DEFAULT_GOAL := build

all: release

clean:
	rm -f target/*

test: # for detailed outputs, run 'make test VERBOSE=true'
	if [ -z ${OFFLINE} ] || [ ${OFFLINE} != true ];then \
		echo "Running tests ..."; \
		echo ">> for detailed outputs, run 'make test VERBOSE=true' <<"; \
		go test -mod=mod -v ./...; \
	else \
		echo "Running tests using local vendor folder (ie offline build) ..."; \
		echo ">> for detailed outputs, run 'make test VERBOSE=true' <<"; \
		go test -mod=vendor -v ./...; \
	fi

build-ovai-webhook: clean test # run 'make build-ovai-webhook OFFLINE=true' to build from vendor folder
	if [ -z ${OFFLINE} ] || [ ${OFFLINE} != true ];then \
		echo "Building ovai-webhook ..."; \
		GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -mod=mod -a -o $(TARGET_WEBHOOK) ./cmd/vaultinjector-webhook; \
	else \
		echo "Building ovai-webhook using local vendor folder (ie offline build) ..."; \
		GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -mod=vendor -a -o $(TARGET_WEBHOOK) ./cmd/vaultinjector-webhook; \
	fi
	cd target && sha512sum vaultinjector-webhook > vaultinjector-webhook.sha512

build-ovai-env: # run 'make build-ovai-env OFFLINE=true' to build from vendor folder
	if [ -z ${OFFLINE} ] || [ ${OFFLINE} != true ];then \
		echo "Building ovai-env ..."; \
		GOOS=linux GOARCH=amd64 go build -mod=mod -a -o $(TARGET_ENV) ./cmd/vaultinjector-env; \
	else \
		echo "Building ovai-env using local vendor folder (ie offline build) ..."; \
		GOOS=linux GOARCH=amd64 go build -mod=vendor -a -o $(TARGET_ENV) ./cmd/vaultinjector-env; \
	fi
	cd target && sha512sum vaultinjector-env > vaultinjector-env.sha512

build: build-ovai-webhook build-ovai-env

package:
	set -e
	mkdir -p target && cd target
	echo "Archive Helm chart ..."
	mkdir -p open-vault-agent-injector && cp -R ../README.md ../deploy/helm/* ./open-vault-agent-injector
	sed -i "s/version: 0.0.0/version: ${CHART_VERSION}/;s/appVersion: 0.0.0/appVersion: ${OVAI_VERSION}/" ./open-vault-agent-injector/Chart.yaml
	sed -i "s/tag: \"latest\"  # OVAI image tag/tag: \"${OVAI_VERSION}\"  # OVAI image tag/" ./open-vault-agent-injector/values.yaml
	helm package open-vault-agent-injector
	rm -R open-vault-agent-injector
	helm lint ./open-vault-agent-injector-*.tgz --debug

image:
	echo "Build image using Go container and multi-stage build ..."
	docker build -t ${IMAGE_FQIN}:${OVAI_VERSION} .
	docker tag ${IMAGE_FQIN}:${OVAI_VERSION} ${IMAGE_FQIN}

image-from-build: build
	echo "Build image from local build ..."
	docker build -f Dockerfile.local -t ${IMAGE_FQIN}:${OVAI_VERSION} .
	docker tag ${IMAGE_FQIN}:${OVAI_VERSION} ${IMAGE_FQIN}

release: image-from-build package
	read -p "Publish image (y/n)? " answer
	case $$answer in \
	y|Y ) \
		docker login; \
		docker push ${IMAGE_FQIN}:${OVAI_VERSION}; \
		if [ "$$?" -ne 0 ]; then \
			echo "Unable to publish image"; \
			exit 1; \
		fi; \
	;; \
	* ) \
		echo "Image not published"; \
	;; \
	esac
	cd target
	echo "Releasing artifacts ..."
	read -p "- Github user name to use for release: " username
	echo "- Creating release"
	id=$$(curl -u $$username -s -X POST "https://api.github.com/repos/${OWNER}/${REPO}/releases" -d '{"tag_name": "v'${RELEASE_VERSION}'", "name": "v'${RELEASE_VERSION}'", "draft": true, "body": ""}' | jq '.id')
	if [ "$$?" -ne 0 ]; then \
		echo "Unable to create release"; \
		echo $$id; \
		exit 1; \
	fi
	echo "- Release id=$$id"
	echo
	echo "- Publishing release binary"
	for asset_file in $(shell ls ./target); do \
		asset_absolute_path=$$(realpath $$asset_file); \
		echo "Adding file $$asset_absolute_path"; \
		echo; \
		asset_filename=$$(basename $$asset_absolute_path); \
		curl -u $$username -s --data-binary @"$$asset_absolute_path" -H "Content-Type: application/octet-stream" "https://uploads.github.com/repos/${OWNER}/${REPO}/releases/$$id/assets?name=$$asset_filename"; \
		if [ "$$?" -ne 0 ]; then \
			echo "Unable to publish binary $$asset_absolute_path"; \
			exit 1; \
		fi; \
		echo; \
	done
	echo
	echo
	read -p "- Confirm release ok at https://api.github.com/repos/${OWNER}/${REPO}/releases/$$id (y/[n])? " answer
	case $$answer in \
	y|Y ) \
		curl -u $$username -s -X PATCH "https://api.github.com/repos/${OWNER}/${REPO}/releases/$$id" -d '{"draft": false}'; \
		if [ "$$?" -ne 0 ]; then \
			echo "Unable to finish release"; \
			exit 1; \
		fi; \
	;; \
	* ) \
		curl -u $$username -s -X DELETE "https://api.github.com/repos/${OWNER}/${REPO}/releases/$$id"; \
		echo "Aborted"; \
	;; \
	esac
