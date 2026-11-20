IMAGE ?= fluent-bit
REPO ?= rancher
TAG ?= dev
TARGET_PLATFORMS ?= linux/amd64,linux/arm64
VERSION ?= $(shell echo "$(TAG)" | sed -E 's/^v//; s/[_-]debug.*//')

.PHONY: push-image
push-image:
	docker buildx build \
		$(IID_FILE_FLAG) \
		--platform $(TARGET_PLATFORMS) \
		--target production \
		--build-arg RELEASE_VERSION=$(VERSION) \
		-t $(REPO)/$(IMAGE):$(TAG) \
		--push .

.PHONY: push-debug-image
push-debug-image:
	docker buildx build \
		$(IID_FILE_FLAG) \
		--platform $(TARGET_PLATFORMS) \
		--target debug \
		--build-arg RELEASE_VERSION=$(VERSION) \
		-t $(REPO)/$(IMAGE):$(TAG) \
		--push .
