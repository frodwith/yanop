getopt = require '../lib/getopt'

exports.flag = (t) ->
    t.expect 6

    p = new getopt.Parser
        verbose:
            type: getopt.flag
            short: 'v'

    o = p.parse ['-v']
    t.ok o.verbose
    o = p.parse []
    t.ok not o.verbose
    o = p.parse ['--verbose']
    t.ok o.verbose
    o = p.parse ['--verbose', '-v', '--verbose', '-v']
    t.ok o.verbose
    t.throws (() -> p.parse ['-v', '--frobnicate']), getopt.UnknownOption
    t.throws (() -> p.parse ['--v']), getopt.UnknownOption
    t.done()

exports.vax = (t) ->
    t.expect 5
    p = new getopt.Parser
        verbose:
            type: getopt.flag
            long: []
            short: ['v']
        arcane:
            type: getopt.flag
            long: []
            short: ['a']
        xenophobic:
            type: getopt.flag
            long: []
            short: ['x']
        notset:
            type: getopt.flag
            long: ['en']

    o = p.parse ['-vax']
    t.ok o.verbose
    t.ok o.arcane
    t.ok o.xenophobic
    t.ok not o.notset

    t.throws (() -> p.parse ['--verbose']), getopt.UnknownOption
    t.done()

exports.scalar = (t) ->
    t.expect 8
    p = new getopt.Parser
        foo:
            type: getopt.scalar
            required: true

    o = p.parse ['--foo=bar']
    t.equal o.foo, 'bar'

    o = p.parse ['--foo', 'bar']
    t.equal o.foo, 'bar'
    t.deepEqual o.argv, []

    # this would parse as -f -o -o bar
    t.throws (() -> p.parse ['-foo', 'bar']), getopt.UnknownOption

    # this would parse as -f oo=bar
    t.throws (() -> p.parse ['-foo=bar']), getopt.UnknownOption

    t.throws (() -> p.parse ['--foo=bar', '--foo=baz']),
        getopt.ScalarWithValues

    t.throws (() -> p.parse []), getopt.RequiredMissing

    t.throws (() -> p.parse ['--foo']), getopt.NoValue

    t.done()

exports.array = (t) ->
    t.expect 3
    p = new getopt.Parser
        thing:
            short: ['t']
            type: getopt.array

    o = p.parse []
    t.deepEqual o.thing, []

    o = p.parse ['--thing=one']
    t.deepEqual o.thing, ['one']

    o = p.parse ['--thing', 'one', '--thing=two', '-t', 'three', '-tfour']
    t.deepEqual o.thing, ['one', 'two', 'three', 'four']

    t.done()

exports.object = (t) ->
    t.expect 5

    p = new getopt.Parser
        define:
            short: ['D']
            type: getopt.object

    o = p.parse []
    t.deepEqual o.define, {}

    o = p.parse ['-D', 'foo=bar']
    t.deepEqual o.define, { foo: 'bar' }

    o = p.parse ['--define', 'foo=bar', '-D', 'bar=baz', '--define=baz=qux']
    t.deepEqual o.define, { foo: 'bar', bar: 'baz', baz: 'qux' }

    o = p.parse ['--define=foo']
    t.ok 'foo' of o.define
    t.equal o.define.foo, undefined

    t.done()

exports.required = (t) ->
    t.expect 1
    p = new getopt.Parser
        define:
            type: getopt.scalar
            required: true

    t.throws (() -> p.parse []), getopt.RequiredMissing
    t.done()

exports.short = (t) ->
    t.expect 3

    p = new getopt.Parser
        input:
            type: getopt.scalar
            long: []
            short: 'i'

    o = p.parse ['-i', 'foo.txt']
    t.equal o.input, 'foo.txt'

    o = p.parse ['-ifoo.txt']
    t.equal o.input, 'foo.txt'

    o = p.parse ['-i=foo.txt']
    t.equal o.input, '=foo.txt'

    t.done()

exports.long = (t) ->
    t.expect 6
    p = new getopt.Parser
        foo:
            type: getopt.bool
            long: ['not', 'even', 'close']
    o = p.parse ['--not']
    t.ok o.foo

    o = p.parse ['--even']
    t.ok o.foo

    o = p.parse ['--close']
    t.ok o.foo

    t.throws (() -> p.parse ['--foo']), getopt.UnknownOption

    p = new getopt.Parser
        foo:
            type: getopt.bool
            long: 'bar'

    o = p.parse ['--bar']
    t.ok o.foo

    t.throws (() -> p.parse ['--foo']), getopt.UnknownOption
    t.done()


exports['aliased types'] = (t) ->
    t.expect 4
    t.equal(getopt.list, getopt.array)
    t.equal(getopt.hash, getopt.object)
    t.equal(getopt.bool, getopt.flag)
    t.equal(getopt.string, getopt.scalar)
    t.done()

exports.complicated = (t) ->
    t.expect 7

    p = new getopt.Parser
        verbose:
            type: getopt.bool
            short: 'v'
        arcane:
            type: getopt.flag
            long: []
            short: 'a'
        xenophobic:
            type: getopt.flag
            short: 'x'
        name:
            type: getopt.list
            long: ['call', 'sign']
        define:
            type: getopt.hash
            short: ['D', 'd']
        proxy:
            type: getopt.scalar
            default: 'http://www.proxy.com'
        input:
            type: getopt.scalar
            short: 'i'
            required: true

    o = p.parse [
        'split'
        '-vax'
        '--input'
        '-'
        '--call=bar'
        '--sign=baz'
        '-d', 'foo=bar'
        '-D', 'bar=baz'
        '-DHAVE_CRYPT'
        '--define=baz=qux'
        '-'
        '--'
        '--foo'
        '--bar'
        '--baz'
    ]
    t.deepEqual o.argv, ['split', '-', '--foo', '--bar', '--baz']
    t.ok o.verbose
    t.ok o.arcane
    t.ok o.xenophobic
    t.equal o.input, '-'
    t.deepEqual o.name, ['bar', 'baz']
    t.deepEqual o.define,
        foo: 'bar'
        bar: 'baz'
        baz: 'qux'
        'HAVE_CRYPT': undefined

    t.done()
