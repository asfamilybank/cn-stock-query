.PHONY: test test-unit test-integration test-e2e test-all

test: test-unit test-integration

test-unit:
	@bash tests/run.sh unit

test-integration:
	@bash tests/run.sh integration

test-e2e:
	@bash tests/run.sh e2e

test-all:
	@bash tests/run.sh all
