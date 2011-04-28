%.js : %.coffee
	coffee -cs < $< > $@

JSFILES := $(shell find . -name '*.coffee' | sed s/\.coffee$$/.js/)

coffee: $(JSFILES)

all: coffee

test: coffee
	nodeunit test/*.js

clean:
	rm -f $(JSFILES)

.PHONY : all test coffee
