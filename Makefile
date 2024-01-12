REMOTE_REGISTRY := registry.kmrd.dev/iptecharch/data-server
TAG := $(shell git describe --tags)
IMAGE := $(REMOTE_REGISTRY):$(TAG)
TEST_IMAGE := $(IMAGE)-test

# go versions
TARGET_GO_VERSION := go1.21.4
GO_FALLBACK := go
# We prefer $TARGET_GO_VERSION if it is not available we go with whatever go we find ($GO_FALLBACK)
GO_BIN := $(shell if [ "$$(which $(TARGET_GO_VERSION))" != "" ]; then echo $$(which $(TARGET_GO_VERSION)); else echo $$(which $(GO_FALLBACK)); fi)

build:
	mkdir -p bin
	CGO_ENABLED=0 ${GO_BIN} build -o bin/datactl client/main.go 
	CGO_ENABLED=0 ${GO_BIN} build -o bin/data-server main.go
	CGO_ENABLED=0 ${GO_BIN} build -o bin/bulk tests/bulk/main.go

test:
	robot tests/robot
	go test ./...

docker-build:
	docker build . -t $(IMAGE)

docker-push: docker-build
	docker push $(IMAGE)

release: docker-build
	docker tag $(IMAGE) $(REMOTE_REGISTRY):latest
	docker push $(REMOTE_REGISTRY):latest

docker-test:
	docker build . -t $(TEST_IMAGE) -f tests/container/Dockerfile
	docker run -v ./tests/results:/results:rw $(TEST_IMAGE) robot --outputdir /results /app/tests/robot

run-distributed:
	./lab/distributed/run.sh build

run-combined:
	./lab/combined/run.sh build

stop:
	./lab/combined/stop.sh
	./lab/distributed/stop.sh
