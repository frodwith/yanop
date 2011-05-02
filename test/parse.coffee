yanop = require '../lib/yanop'

exports.flag = (t) ->
    t.expect 6

    p = new yanop.Parser
        verbose:
            type: yanop.flag
            short: 'v'

    o = p.parse ['-v']
    t.ok o.verbose
    o = p.parse []
    t.ok not o.verbose
    o = p.parse ['--verbose']
    t.ok o.verbose
    o = p.parse ['--verbose', '-v', '--verbose', '-v']
    t.ok o.verbose
    t.throws (() -> p.parse ['-v', '--frobnicate']), yanop.UnknownOption
    t.throws (() -> p.parse ['--v']), yanop.UnknownOption
    t.done()

exports.vax = (t) ->
    t.expect 5
    p = new yanop.Parser
        verbose:
            type: yanop.flag
            long: []
            short: ['v']
        arcane:
            type: yanop.flag
            long: []
            short: ['a']
        xenophobic:
            type: yanop.flag
            long: []
            short: ['x']
        notset:
            type: yanop.flag
            long: ['en']

    o = p.parse ['-vax']
    t.ok o.verbose
    t.ok o.arcane
    t.ok o.xenophobic
    t.ok not o.notset

    t.throws (() -> p.parse ['--verbose']), yanop.UnknownOption
    t.done()

exports.scalar = (t) ->
    t.expect 8
    p = new yanop.Parser
        foo:
            type: yanop.scalar
            required: true

    o = p.parse ['--foo=bar']
    t.equal o.foo, 'bar'

    o = p.parse ['--foo', 'bar']
    t.equal o.foo, 'bar'
    t.deepEqual o.argv, []

    # this would parse as -f -o -o bar
    t.throws (() -> p.parse ['-foo', 'bar']), yanop.UnknownOption

    # this would parse as -f oo=bar
    t.throws (() -> p.parse ['-foo=bar']), yanop.UnknownOption

    t.throws (() -> p.parse ['--foo=bar', '--foo=baz']),
        yanop.ScalarWithValues

    t.throws (() -> p.parse []), yanop.RequiredMissing

    t.throws (() -> p.parse ['--foo']), yanop.NoValue

    t.done()

exports.array = (t) ->
    t.expect 3
    p = new yanop.Parser
        thing:
            short: ['t']
            type: yanop.array

    o = p.parse []
    t.deepEqual o.thing, []

    o = p.parse ['--thing=one']
    t.deepEqual o.thing, ['one']

    o = p.parse ['--thing', 'one', '--thing=two', '-t', 'three', '-tfour']
    t.deepEqual o.thing, ['one', 'two', 'three', 'four']

    t.done()

exports.object = (t) ->
    t.expect 5

    p = new yanop.Parser
        define:
            short: ['D']
            type: yanop.object

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
    p = new yanop.Parser
        define:
            type: yanop.scalar
            required: true

    t.throws (() -> p.parse []), yanop.RequiredMissing
    t.done()

exports.short = (t) ->
    t.expect 3

    p = new yanop.Parser
        input:
            type: yanop.scalar
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
    p = new yanop.Parser
        foo:
            type: yanop.bool
            long: ['not', 'even', 'close']
    o = p.parse ['--not']
    t.ok o.foo

    o = p.parse ['--even']
    t.ok o.foo

    o = p.parse ['--close']
    t.ok o.foo

    t.throws (() -> p.parse ['--foo']), yanop.UnknownOption

    p = new yanop.Parser
        foo:
            type: yanop.bool
            long: 'bar'

    o = p.parse ['--bar']
    t.ok o.foo

    t.throws (() -> p.parse ['--foo']), yanop.UnknownOption
    t.done()


exports['aliased types'] = (t) ->
    t.expect 4
    t.equal(yanop.list, yanop.array)
    t.equal(yanop.hash, yanop.object)
    t.equal(yanop.bool, yanop.flag)
    t.equal(yanop.string, yanop.scalar)
    t.done()

exports.complicated = (t) ->
    t.expect 7

    p = new yanop.Parser
        verbose:
            type: yanop.bool
            short: 'v'
        arcane:
            type: yanop.flag
            long: []
            short: 'a'
        xenophobic:
            type: yanop.flag
            short: 'x'
        name:
            type: yanop.list
            long: ['call', 'sign']
        define:
            type: yanop.hash
            short: ['D', 'd']
        proxy:
            type: yanop.scalar
            default: 'http://www.proxy.com'
        input:
            type: yanop.scalar
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
