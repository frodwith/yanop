%.js : %.coffee
	coffee -cs < $< > $@

JSFILES := $(shell find lib test -name '*.coffee' | sed s/\.coffee$$/.js/)

coffee: $(JSFILES)

all: coffee

test: coffee
	npm test

clean:
	rm -rf $(JSFILES) yanop*.tar.gz node_modules

deps:
	npm install

dist:
	perl mkdist.pl

.PHONY : all test coffee dist deps
