PYTHON=python3

.PHONY: build upload test

build:
	./build.sh

upload:
	# usage: make upload S3_BUCKET=my-bucket
	./upload.sh $(S3_BUCKET) $(S3_KEY)

test:
	$(PYTHON) -m pytest -q lambda/test_remediate.py

tools-install:
	# install runtime tools into the active environment (use virtualenv)
	python3 -m pip install --user -r tools/requirements.txt

tools-dev-install:
	# install development tools (linters, test deps) into the active environment
	python3 -m pip install --user -r tools/dev-requirements.txt
