Getopt
======

For the impatient
-----------------
If you're in a hurry and you just want to parse your options already:

    getopt = require('getopt');
    options = getopt.simple({
        verbose: {
            type: getopt.flag,
            short: 'v',
        },
        input: {
            type: getopt.list,
            short: 'i',
        },
        output: {
            type: getopt.scalar,
            description: 'output file (- for stdout)',
            default: '-',
            short: 'o',
            required: true,
        },
    });

options.verbose is true or false, input is an array (possibly empty), and
output is a string (or undefined). You also get a --help option for free that
prints out:

    node myscript.pl [OPTIONS]

    The following options are accepted:

              -h
          --help  Prints this message and exits.

              -v
       --verbose


          -i VAL
     --input=VAL

          -o VAL
    --output=VAL  output file (- for stdout). Required. Default: -

getopt.simple() doesn't do what I want!
=======================================
Yeah, sorry about that. getopt.simple() does what I usually want with a
minimum of fuss and ceremony, but have a look at the lower level APIs. Very
probably, you can coerce them into doing what you want, though you might have
to write try/catch blocks (the horror!) and call process.exit() yourself, and
so on. The whole API is designed to allow you to use just the parts of it that
are useful for you. So, read the rest of the documentation :)

Why?
----

As if Node didn't have enough option parsers. As of this writing, most of them
are almost good enough for me. None of them quite measures up to the power of
perl's Getopt::Long though. Getopt::Long's interface sucks, but its parser is
very flexible. This module aims to have an interface that doesn't suck and
still be flexible, but you'll be the judge.

Specification
-------------

The primary way you give information to getopt is through a specification
object. The keys are the names of targets (keys in the result object), and the
values are objects with the following keys:

### type

This tells getopt what kind of thing you're trying to parse. It absolutely
must be one of the following - you cannot pass a string, and there is no
default.

#### getopt.flag (or getopt.bool) 

Just an "on" switch. It'll be true if it was passed, and false if it wasn't.
All the following forms are valid:

    -vax
    -v -a -x
    --verbose --anthropomorphic --xenophobic

#### getopt.scalar (or getopt.string)

Expects one (and only one) value. If present at all, its value will be some
kind of string. Passing more than one argument for options of this type will
make getopt throw an error. The following forms are all valid:

    -a42
    -a 42
    --answer 42
    --answer=42

#### getopt.array (or getopt.list)

Expects zero or more values. You'll get an array in the result object of all
the strings passed for this argument.

    node script.js --foo=one --foo=two --foo=three
***
    { foo: ['one', 'two', 'three'] }

#### getopt.object (or getopt.hash)

This one is a little odd: like list, you can pass it multiple times, but the
result will be an object (or hash) instead of an array, and the value will be
split into key/value on the = sign. An example will probably explain better:

    define: {
        type: getopt.object,
        short: '-D'
    }
***
    node --script.js -Dfoo=bar -Dbar=baz
***
    { define: { foo: "bar", bar: "baz" } }

### short

Either a string or an array of strings. All must be one character long (leave
off the -). This creates short aliases for your argument. The target will be
the same, though, and aliases can be mixed. In addition, for flag type shorts,
they can be chained together.  No short aliases are created by default. 

### long

A list of long names for your option, either a string or an array of strings
(leave off the --).  By default, this is just the name of your target. If you
do specify some longs, you must also include the name of your target if you
wish it to be a long alias.

### required

A boolean. This causes getopt.parse to throw an exception if the argument
wasn't given, and is only valid for scalars and lists. In the list case, at
least one value must be given.

### default

A default value for your option if none is parsed from the command line.
Arrays and objects default to empty arrays and objects unless you say
otherwise.

### description

Purely optional, this should be a string explaining what your option does. The
help generator makes use of this -- see getopt.help() for details.

Positional Arguments
--------------------
Anything that doesn't look like an option will get aggregated into the result
object's .argv property, in the order it was found in the actual argv.  '-' is
treated as positional, and '--' will cause getopt to stop processing and
report the rest of the args as positional.

Unrecognized Arguments
----------------------
Any options given to the program that aren't specified in the options spec
will cause an error to be thrown.

API
===

### getopt.parse(spec, argv)

Processes argv without modifying it and returns a result object, which will
have an argv property and other properties depending on the option spec. Any
errors in parsing will throw an exception. If you don't specify argv,
process.argv (minus the first two elements) will be used.

### getopt.tryParse(spec, argv)

Wraps getopt.parse in a try/catch block. If exceptions are encountered, they
are printed to stderr and the process will exit with a non-zero code.

### getopt.zero()

Returns the program name (e.g. "node myscript.js"). Useful when generating a
usage message.

### getopt.usage()

Uses getopt.zero() to generate a usage message of the form: 
"Usage: node myscript.js [OPTIONS]". This is the default message used by
getopt.simple().

### getopt.help(spec)

Returns a formatted string describing the options specified. Used internally
by getopt.simple(), but you are encouraged to use it outside that context.

The description field of the spec is examined. If you didn't include a period
at the end of the description, one will be added. Other bits of explanatory
text (like "Required", "Default: " or "Can be specified multiple times") will
be added to the end of the description to keep you from having to duplicate
spec information in the description.

### getopt.simple(spec, banner, argv)

Behaves similarly to getopt.tryParse(), except that it adds a "help" option
and then checks for it. If --help is passed, spec will be passed to
getopt.help() to generate some the help. The given banner will be printed,
followed by this help. Banner and argv are both optional: banner defaults to
getopt.usage(), and argv() defaults to process.argv as in getopt.parse().

Errors
======
There is a whole heirarchy of error classes, mostly for testing purposes. If
you don't catch them, node will print a stacktrace for them like the common
errors. If you do, you can use their "message" member to print out something
useful to the user.

Any time you create a Parser or Help object (internal classes used by the api
methods above), an exception will be thrown if there is something inconsistent
about your option specification. This helps you catch errors sooner. These
exceptions are instances of getopt.SpecError, but you probably shouldn't try
to catch them. getopt.tryParse et al will rethrow them.

Calling getopt.parse() an throw exceptions if the user has given bad options
on the command line. These are generally the ones you want to try to catch and
print. They are all instances of getopt.ParseError.

I think getopt should behave differently.
=========================================

I value your opinion, I really do. I also have a job, and it isn't maintaining
getopt. Please, please either include a patch in your correspondance or send
me a pull request on github. Otherwise, your issue may or may not be
addressed, but I'm gonna go out on a limb and say it probably won't be. Thanks
in advance for your contributions :)

If you insist on not fixing my code for me, though, you can report an issue
through github. If it's a bug that effects me, it will very likely get fixed.
If not, perhaps you should reconsider fixing my code for me :)
