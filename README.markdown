YANOP - Yet Another Node Option Parser
======

For the impatient
-----------------
If you're in a hurry and you just want to parse your options already:

    yanop = require('yanop');
    options = yanop.simple({
        verbose: {
            type: yanop.flag,
            short: 'v',
        },
        input: {
            type: yanop.list,
            short: 'i',
        },
        output: {
            type: yanop.scalar,
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

yanop.simple() doesn't do what I want!
=======================================
Yeah, sorry about that. yanop.simple() does what I usually want with a
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

The primary way you give information to yanop is through a specification
object. The keys are the names of targets (keys in the result object), and the
values are objects with the following keys:

### type

This tells yanop what kind of thing you're trying to parse. It absolutely
must be one of the following - you cannot pass a string, and there is no
default.

#### yanop.flag (or yanop.bool)

Just an "on" switch. It'll be true if it was passed, and false if it wasn't.
All the following forms are valid:

    -vax
    -v -a -x
    --verbose --anthropomorphic --xenophobic

#### yanop.scalar (or yanop.string)

Expects one (and only one) value. If present at all, its value will be some
kind of string. Passing more than one argument for options of this type will
make yanop throw an error. The following forms are all valid:

    -a42
    -a 42
    --answer 42
    --answer=42

#### yanop.array (or yanop.list)

Expects zero or more values. You'll get an array in the result object of all
the strings passed for this argument.

    node script.js --foo=one --foo=two --foo=three
***
    { foo: ['one', 'two', 'three'] }

#### yanop.object (or yanop.hash)

This one is a little odd: like list, you can pass it multiple times, but the
result will be an object (or hash) instead of an array, and the value will be
split into key/value on the = sign. An example will probably explain better:

    define: {
        type: yanop.object,
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

A boolean. This causes yanop.parse to throw an exception if the argument
wasn't given, and is only valid for scalars and lists. In the list case, at
least one value must be given.

### default

A default value for your option if none is parsed from the command line.
Arrays and objects default to empty arrays and objects unless you say
otherwise.

### description

Purely optional, this should be a string explaining what your option does. The
help generator makes use of this -- see yanop.help() for details.

Positional Arguments
--------------------
Anything that doesn't look like an option will get aggregated into the result
object's .argv property, in the order it was found in the actual argv.  '-' is
treated as positional, and '--' will cause yanop to stop processing and
report the rest of the args as positional.

Unrecognized Arguments
----------------------
Any options given to the program that aren't specified in the options spec
will cause an error to be thrown.

The Result Object
=================

The return value of most of the API methods is a result object. Mostly you can
just treat it like a hash of your options, but it has a couple of special
properties:

### result.argv

All the remaining positional arguments after processing.

### result.values

This really is a hash of your options.

### result.given

This is a hash of the options specified on the command line, e.g. before any
defaults were set.

## result[targetName]

This will be the same as result.values[targetName] unless targetName conflicts
with one of the above keys, in which case you must use result.values to get at
it (an edge case that you probably don't have to worry about).

API
===

### yanop.parse(spec, argv)

Processes argv without modifying it and returns a result object, which will
have an argv property and other properties depending on the option spec. Any
errors in parsing will throw an exception. If you don't specify argv,
process.argv (minus the first two elements) will be used.

### yanop.tryParse(spec, argv)

Wraps yanop.parse in a try/catch block. If exceptions are encountered, they
are printed to stderr and the process will exit with a non-zero code.

### yanop.zero()

Returns the program name (e.g. "node myscript.js"). Useful when generating a
usage message.

### yanop.usage()

Uses yanop.zero() to generate a usage message of the form:
"Usage: node myscript.js [OPTIONS]". This is the default message used by
yanop.simple().

### yanop.help(spec)

Returns a formatted string describing the options specified. Used internally
by yanop.simple(), but you are encouraged to use it outside that context.

The description field of the spec is examined. If you didn't include a period
at the end of the description, one will be added. Other bits of explanatory
text (like "Required", "Default: " or "Can be specified multiple times") will
be added to the end of the description to keep you from having to duplicate
spec information in the description.

### yanop.simple(spec, banner, argv)

Behaves similarly to yanop.tryParse(), except that it adds a "help" option and
then checks for it. If --help is passed, spec will be passed to yanop.help()
to generate the help. The given banner will be printed, followed by this help.
Banner and argv are both optional: banner defaults to yanop.usage(), and argv
defaults to process.argv as in yanop.parse().

Errors
======
There is a whole hierarchy of error classes, mostly for testing purposes. If
you don't catch them, node will print a stack trace for them like builtin
Errors.  If you do, you can use their "message" member to print out something
useful to the user.

Any time you create a Parser or Help object (internal classes used by the API
methods above), an exception will be thrown if there is something inconsistent
about your option specification. This helps you catch errors sooner. These
exceptions are instances of yanop.SpecError, but you probably shouldn't try
to catch them. yanop.tryParse et al will rethrow them.

Calling yanop.parse() will throw exceptions if the user has given bad options
on the command line. These are generally the ones you want to try to catch and
print. They are all instances of yanop.ParseError.

I think yanop should behave differently.
=========================================

I value your opinion, I really do. I also have a job, and it isn't maintaining
yanop. Please, please either include a patch in your correspondence or send
me a pull request on github. Otherwise, your issue may or may not be
addressed, but I'm gonna go out on a limb and say it probably won't be. Thanks
in advance for your contributions :)

If you insist on not fixing my code for me, though, you can report an issue
through github. If it's a bug that effects me, it will very likely get fixed.
If not, perhaps you should reconsider fixing my code for me :)
