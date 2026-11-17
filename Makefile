IMAGE ?= fluent-bit
REPO ?= rancher
TAG ?= dev
TARGET_PLATFORMS ?= linux/amd64,linux/arm64
VERSION ?= $(patsubst v%,%,$(TAG))

.PHONY: push-image
push-image:
	docker buildx build \
		$(IID_FILE_FLAG) \
		--platform $(TARGET_PLATFORMS) \
		--target production \
		--build-arg RELEASE_VERSION=$(VERSION) \
		-t $(REPO)/$(IMAGE):$(TAG) \
		--push .
