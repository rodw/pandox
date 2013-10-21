################################################################################
# CONFIGURATION

# COFFEE #######################################################################
COFFEE_EXE ?= ./node_modules/.bin/coffee
NODE_EXE ?= node
COFFEE_COMPILE ?= $(COFFEE_EXE) -c
COFFEE_COMPILE_ARGS ?=
COFFEE_SRCS ?= $(wildcard *.coffee) $(wildcard lib/*.coffee) $(wildcard sql/*.coffee) $(wildcard lib/*/*.coffee)
COFFEE_TEST_SRCS ?= $(wildcard test/*.coffee) $(wildcard test/*/*.coffee)
COFFEE_JS ?= ${COFFEE_SRCS:.coffee=.js}

# NPM ##########################################################################
NPM_EXE ?= npm
PACKAGE_JSON ?= package.json
NODE_MODULES ?= node_modules
MODULE_DIR ?= module

# MOCHA ########################################################################
MOCHA_EXE ?= mocha
MOCHA_TESTS ?= $(wildcard test/test-*.coffee) $(wildcard test/*/test-*.coffee)
MOCHA_TEST_PATTERN ?=
MOCHA_TIMEOUT ?=-t 4000
MOCHA_TEST_ARGS  ?= -R list --compilers coffee:coffee-script $(MOCHA_TIMEOUT) $(MOCHA_TEST_PATTERN)

# JSCOVERAGE ###################################################################
JSCOVERAGE_EXE ?= node-jscoverage
JSCOVERAGE_REPORT ?= docs/coverage.html
JSCOVERAGE_TMP_DIR ?=  ./jscov-tmp
LIB_COV ?= lib-cov
LIB ?= lib
MOCHA_COV_ARGS  ?= -R html-cov --compilers coffee:coffee-script --globals "_\$$jscoverage"

# MARKDOWN #####################################################################
MARKDOWN_SRCS ?= $(shell find . -type f -name '*.md' | grep -v node_modules | grep -v module)
MARKDOWN_HTML ?= ${MARKDOWN_SRCS:.md=.html}
MARKDOWN_PROCESSOR ?= pandoc
MARKDOWN_STYLESHEET ?= docs/styles/markdown.css
MARKDOWN_PROCESSOR_ARGS ?= -f markdown -t html -s -H $(MARKDOWN_STYLESHEET) --toc --highlight-style pygments

# # UGLIFY #######################################################################
# UGLIFY_EXE ?= uglifyjs
# UGLIFY_ARGS ?=
# CLIENT_JS_SRCS ?= $(shell find client-lib -type f -name '*.js' | grep -v '.min.js')
# MIN_JS ?= ${CLIENT_JS_SRCS:.js=.min.js}

# OTHER ########################################################################
RM_DASH_I ?= -f

################################################################################
# META-TARGETS AND SIMILAR

# `.SUFFIXES` - reset suffixes in case any were previously defined
.SUFFIXES:

# `.PHONY` - make targets that aren't actually files
.PHONY: all build clean clean-coverage clean-docco clean-docs clean-js clean-markdown clean-module clean-node-modules clean-test-module-install coverage docco docs help install js markdown module npm really-clean really-clean-node-modules targets test test-module-install todo

# `all` - the default target
all: coverage docco

# `help` - list targets.
help: targets

# `targets` - list targets that are not likely to be .PHONY targets
targets:
	@grep -E "^[^ #.$$]+:( |$$)" Makefile | sort | cut -d ":" -f 1

# `todo` - list todo comments in found files
todo:
	@grep -C 0 --exclude-dir=node_modules --exclude-dir=.git --exclude=#*# --exclude=.#* --exclude=*.html  --exclude=Makefile  -IrHE "(TODO)|(FIXME)|(XXX)" *

################################################################################
# CLEAN UP TARGETS

clean: clean-coverage clean-docco clean-docs clean-js clean-markdown clean-module clean-node-modules clean-test-module-install

clean-coverage:
	rm -r $(RM_DASH_I) $(JSCOVERAGE_TMP_DIR)
	rm -r $(RM_DASH_I) $(LIB_COV)
	rm $(RM_DASH_I) $(JSCOVERAGE_REPORT)

clean-docco:
	rm -r $(RM_DASH_I) docs/docco

clean-docs: clean-markdown clean-docco

clean-js:
	rm $(RM_DASH_I) $(COFFEE_JS)

clean-markdown:
	rm $(RM_DASH_I) $(MARKDOWN_HTML)

clean-module:
	rm -r $(RM_DASH_I) $(MODULE_DIR)

clean-node-modules:
	$(NPM_EXE) prune

clean-test-module-install:
	rm -r $(RM_DASH_I) ../testing-module-install

clean-minified-client-js:
	rm -r $(RM_DASH_I) $(MIN_JS)

really-clean: clean really-clean-node-modules

really-clean-node-modules: # deletes rather that simply pruning node_modules
	rm -r $(RM_DASH_I) $(NODE_MODULES)

################################################################################
# NPM TARGETS
module: build test docs coverage
	mkdir -p $(MODULE_DIR)
	cp README.* $(MODULE_DIR)
	cp license.* $(MODULE_DIR)
	cp -r docs $(MODULE_DIR)
	cp -r lib $(MODULE_DIR)
	cp -r test $(MODULE_DIR)
	cp $(PACKAGE_JSON) $(MODULE_DIR)
	cp Makefile $(MODULE_DIR)

test-module-install: clean-test-module-install js test docs coverage module
	mkdir ../testing-module-install; cd ../testing-module-install; npm install "$(CURDIR)/module"; node -e "require('assert').ok(require('pandox').PandocFilter !== null); console.log('It worked!');" && cd $(CURDIR) # && rm -r $(RM_DASH_I) ../testing-module-install

$(NODE_MODULES): $(PACKAGE_JSON)
	$(NPM_EXE) prune
	$(NPM_EXE) --silent install
	touch $(NODE_MODULES) # touch the module dir so it looks younger than `package.json`

npm: $(NODE_MODULES) # an alias

install: $(NODE_MODULES) # an alias

################################################################################
# COFFEE TARGETS

js: $(COFFEE_JS) $(NODE_MODULES) $(MIN_JS)

.SUFFIXES: .js .coffee
.coffee.js:
	$(COFFEE_COMPILE) $(COFFEE_COMPILE_ARGS) $<
$(COFFEE_JS_OBJ): $(NODE_MODULES) $(COFFEE_SRCS)

build: js

################################################################################
# TEST TARGETS

test: $(COFFEE_SRCS) $(COFFEE_TEST_SRCS) $(MOCHA_TESTS) $(NODE_MODULES)
	$(MOCHA_EXE) $(MOCHA_TEST_ARGS) $(MOCHA_TESTS)

coverage: js
	rm -r $(RM_DASH_I) $(JSCOVERAGE_TMP_DIR)
	rm -r $(RM_DASH_I) $(LIB_COV)
	mkdir -p $(JSCOVERAGE_TMP_DIR)
	cp -r $(LIB)/* $(JSCOVERAGE_TMP_DIR)/.
	$(JSCOVERAGE_EXE) -v $(JSCOVERAGE_TMP_DIR) $(LIB_COV)
	mkdir -p `dirname $(JSCOVERAGE_REPORT)`
	$(MOCHA_EXE) $(MOCHA_COV_ARGS) $(MOCHA_TESTS) > $(JSCOVERAGE_REPORT)
	rm -r $(RM_DASH_I) $(JSCOVERAGE_TMP_DIR)
	rm -r $(RM_DASH_I) $(LIB_COV)

################################################################################
# MARKDOWN & OTHER DOC TARGETS

docs: markdown docco

.SUFFIXES: .html .md
.md.html:
	$(MARKDOWN_PROCESSOR) $(MARKDOWN_PROCESSOR_ARGS) -o $@ $<

$(MARKDOWN_HTML_OBJ): $(MARKDOWN_SRCS)

markdown: $(MARKDOWN_HTML)

docco: $(COFFEE_SRCS) $(NODE_MODULES)
	rm -r $(RM_DASH_I) docs/docco
	mkdir -p docs
	mv docs docs-temporarily-renamed-so-docco-doesnt-clobber-it
	docco $(COFFEE_SRCS)
	mv docs docs-temporarily-renamed-so-docco-doesnt-clobber-it/docco
	mv docs-temporarily-renamed-so-docco-doesnt-clobber-it docs
