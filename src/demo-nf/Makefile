.PHONY: build test vet docker

GO ?= go
IMAGE ?= acrtelcodemo.azurecr.io/nf/demo-nf:dev

build:
	$(GO) build -o bin/demo-nf ./

test:
	$(GO) test ./...

vet:
	$(GO) vet ./...

docker:
	docker build -t $(IMAGE) .
