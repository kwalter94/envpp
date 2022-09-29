release:
	docker run --rm -v `pwd`:/workspace -w /workspace crystallang/crystal:latest-alpine \
		shards install \
		&& crystal build --static --release src/envpp.cr

install: release
	mv envpp ~/bin
