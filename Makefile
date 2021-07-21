.PHONY: all init fmt fmt-check validate test apply cli test-cli inspect verify loc clean

all: fmt-check validate test apply cli test-cli

init:
	tofu init

fmt:
	tofu fmt -recursive

fmt-check:
	tofu fmt -check -recursive

validate:
	tofu validate

test:
	tofu test

apply:
	tofu apply -auto-approve

cli:
	mkdir -p bin
	cd tools/cli && go build -o ../../bin/pontifex .

test-cli:
	cd tools/cli && go test -v ./...

inspect: cli
	bin/pontifex inspect

verify:
	./tools/scripts/verify.sh

loc:
	./tools/scripts/loc.sh

clean:
	rm -rf bin/ .generated/ tools/cli/pontifex
