%.js : %.coffee
	coffee -cs < $< > $@

JSFILES := $(shell find . -name '*.coffee' | sed s/\.coffee$$/.js/)
coffee: $(JSFILES)

all: coffee

test: coffee
	nodeunit test/*.js

clean:
	rm -f $(JSFILES)

dist:
	perl mkdist.pl

.PHONY : all test coffee dist
