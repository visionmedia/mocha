
REPORTER ?= dot
TM_BUNDLE = JavaScript\ mocha.tmbundle
SRC = $(shell find lib -name "*.js" -type f | sort)
SUPPORT = $(wildcard support/*.js)
REPORTERS := $(shell bin/mocha --reporters | sed -e 's/ - .*//')

all: mocha.js

lib/browser/diff.js: node_modules/diff/diff.js
	cp node_modules/diff/diff.js lib/browser/diff.js

mocha.js: $(SRC) $(SUPPORT) lib/browser/diff.js
	@node support/compile $(SRC)
	@cat \
	  support/head.js \
	  _mocha.js \
	  support/tail.js \
	  support/foot.js \
	  > mocha.js

clean:
	rm -f mocha.js
	rm -fr lib-cov
	rm -f coverage.html

test-cov: lib-cov
	@COV=1 $(MAKE) test REPORTER=html-cov > coverage.html

lib-cov:
	@rm -fr ./$@
	@jscoverage lib $@

test: test-unit

test-all: test-bdd test-tdd test-qunit test-exports test-unit test-grep test-jsapi test-compilers test-glob test-reporter-output

test-jsapi:
	@node test/jsapi

test-unit:
	@./bin/mocha \
		--reporter $(REPORTER) \
		test/acceptance/*.js \
		--growl \
		test/*.js

test-compilers:
	@./bin/mocha \
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script,foo:./test/compiler/foo \
		test/acceptance/test.coffee \
		test/acceptance/test.foo

test-bdd:
	@./bin/mocha \
		--reporter $(REPORTER) \
		--ui bdd \
		test/acceptance/interfaces/bdd

test-tdd:
	@./bin/mocha \
		--reporter $(REPORTER) \
		--ui tdd \
		test/acceptance/interfaces/tdd

test-qunit:
	@./bin/mocha \
		--reporter $(REPORTER) \
		--ui qunit \
		test/acceptance/interfaces/qunit

test-exports:
	@./bin/mocha \
		--reporter $(REPORTER) \
		--ui exports \
		test/acceptance/interfaces/exports

test-grep:
	@./bin/mocha \
	  --reporter $(REPORTER) \
	  --grep fast \
	  test/acceptance/misc/grep

test-invert:
	@./bin/mocha \
	  --reporter $(REPORTER) \
	  --grep slow \
	  --invert \
	  test/acceptance/misc/grep

test-bail:
	@./bin/mocha \
		--reporter $(REPORTER) \
		--bail \
		test/acceptance/misc/bail

test-async-only:
	@./bin/mocha \
	  --reporter $(REPORTER) \
	  --async-only \
	  test/acceptance/misc/asyncOnly

test-glob:
	@./test/acceptance/glob/glob.sh


# The html reporter isn't supported at the command line
TEST_REPORTERS := $(patsubst %,test-reporter-output-%,$(REPORTERS))
TEST_REPORTERS := $(filter-out test-reporter-output-html,$(TEST_REPORTERS))

.PHONY: $(REPORTERS)
test-reporter-output: $(TEST_REPORTERS)
test-reporter-output-%: %
	@echo "Testing file output for reporter $<"
	@./bin/mocha --no-color --reporter $< test/acceptance/interfaces/bdd 2>&1 > /tmp/$<.stdout
	@./bin/mocha --no-color --reporter $< test/acceptance/interfaces/bdd -O /tmp/$<.file 2>&1 > /tmp/dot.file.stdout
	@test -s /tmp/$<.file || \
		(echo "ERROR: reporter $< does not support file output" && exit 1)
	@test ! -s /tmp/$<.file.stdout || \
		(echo "ERROR: reporter $< file output wrote to stdout" && exit 1)

non-tty:
	@./bin/mocha \
		--reporter dot \
		test/acceptance/interfaces/bdd 2>&1 > /tmp/dot.out

	@echo dot:
	@cat /tmp/dot.out

	@./bin/mocha \
		--reporter list \
		test/acceptance/interfaces/bdd 2>&1 > /tmp/list.out

	@echo list:
	@cat /tmp/list.out

	@./bin/mocha \
		--reporter spec \
		test/acceptance/interfaces/bdd 2>&1 > /tmp/spec.out

	@echo spec:
	@cat /tmp/spec.out

tm:
	@open editors/$(TM_BUNDLE)

.PHONY: test-cov test-jsapi test-compilers watch test test-all test-bdd test-tdd test-qunit test-exports test-unit non-tty test-grep tm clean
