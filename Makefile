VERSION = 0.3

## Use cache by default.  You can override the user via the commandline:  make target CACHE="--no-cache"
CACHE =

.PHONY: build-all build test tag_latest_all release ssh

clean-images:
	docker rmi `docker images -q "dangling=true"`
help:
	@echo "General Commands"
	@echo "    help:  Show help"
	@echo "    clean-images:  Delete dangling images"
	@echo ""
	@echo "Build Docker Image:"
	@echo "    build"
	@echo ""
	@echo "Tag Image and Push to Repo:"
	@echo "    release"

build:
	docker build --force-rm $(CACHE) -t eliurkis/nginx-php:$(VERSION) .
	docker tag eliurkis/nginx-php:$(VERSION) eliurkis/nginx-php:latest

tag-latest:
	docker tag eliurkis/nginx-php:$(VERSION) eliurkis/nginx-php:latest

release: tag-latest
	@if ! docker images eliurkis/nginx-php | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "eliurkis/nginx-php version $(VERSION) need to be built. Please run 'make build'"; false; fi
	docker push eliurkis/nginx-php:$(VERSION)
	docker push eliurkis/nginx-php:latest
