%.js : %.coffee
	coffee -cs < $< > $@

JSFILES := $(shell find . -name '*.coffee' | sed s/\.coffee$$/.js/)

coffee: $(JSFILES)

all: coffee

test: coffee
	nodeunit test

clean:
	rm $(JSFILES)

.PHONY : all test coffee
