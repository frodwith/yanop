special flags
=============
A single dash '-' is treated as positional.
Double dash '--' is removed from the array and stops processing, so that
everything that comes after it is treated as positional.

the specification object
========================

keys are target names (what you check for in the result object)
values are the specification for that target. Keys for the specification are:

short:
    array, each element is a one-character string. If you specify nothing,
    there will be no short alias.

long:
    array, each element is a string.  If you specify nothing, the name of the
    target will be used.

type:
    needs to be one of getopt.boolean, getopt.string, getopt.array, or
    getopt.object.  See the "types" section.

types
=====

flag:
    No value is allowed.  Short flags can appear in groups such that
        -vax
    is equivalent to
        -v -a -x

    Long flags look like:
        --verbose --add --xerox

    If the user tries to give a value for a flag with an equals, e.g.
        -v=42
        --verbose=42
    then an error will be thrown. If they try to give one with a space,
    though, , e.g.
        -v 42
        --verbose 42

    then -v will be set and 42 will be treated as a positional argument.

    A flag can be specified multiple times without error.

scalar:
    A single value is allowed. Not giving a value throws an error. Short
    scalars look like:
        -v 42
        -v=42

    Long scalars look like:
        --verbosity 42
        --verbosity=42

    Scalars take an additional option, "required" (defaults to false). If this
    is set, an error will be thrown if no value is supplied or the supplied
    value is the empty string. Specifying this will cause "(required)" to be
    appended to your description.

    Scalars can also have a "default". This will be the value if none is
    specified, although an empty value can still be specified like
        --verbosity=

    Specifying this will cause "(default: value)" to be appended to the
    description.

array:
    The option can be specified zero, one, or many times, and the value will
    be aggregated.  This looks like:

        --foo one --foo two --foo three
        -f=one -f=two -f=three
        etc.

    Arrays can use "required" and "default" just like scalars, except that
    default should be an array. If any values are supplied, the default is not
    used.

object:
    The values supplied must be in the form "name=value".  This looks like:
        -D foo=bar --define bar=baz -D=baz=qux --define=qux=quux

    Supplying the same key twice will cause an error to be thrown.

    Objects can use "default" just like scalars, except
    that default should be an object. If any key/value pairs are supplied, the
    default is ignored.

    Objects cannot be "required".

positional arguments
====================

Anything that doesn't look like an option will be aggregated into the
"positional" array, and can appear anywhere in the argument list.

unrecognized arguments
======================

Any options given to the program that aren't specified in the options spec
will cause an error to be thrown.

errors
======
Errors are thrown when you call "parse", and are string exceptions.
Typical usage would be something like:

parser = new GetOpt(spec)

try {
    parser.parse(process.argv)
}
catch (e) {
    console.log(e)
    console.log(parser.usage())
}

But you can of course do something different.
