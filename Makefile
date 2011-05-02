%.js : %.coffee
	coffee -cs < $< > $@

JSFILES := $(shell find lib test -name '*.coffee' | sed s/\.coffee$$/.js/)
coffee: $(JSFILES)

all: coffee

test: coffee
	nodeunit test/*.js

clean:
	rm -f $(JSFILES) yanop*.tar.gz

dist:
	perl mkdist.pl

.PHONY : all test coffee dist
