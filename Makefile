all: watch ;

watch:
	./scripts/watch

copy-makam-posts:
	find content/blog/ -name \*.md -exec grep -l "^\`\`\`makam" {} \; | xargs -n 1 -r -i bash -c 'mkdir -p $$(dirname $$(echo {} | sed -e 's/content/static/' -)); cp {} $$(echo {} | sed -e 's/content/static/' -)'

build: copy-makam-posts
	hugo

test:
	./scripts/test

.PHONY: watch build copy-makam-posts
