yanop = require '../lib/yanop'

exports.default = (t) ->
    t.expect 6
    p = new yanop.Parser
        foo:
            type: yanop.string
            default: 'bar'

    o = p.parse []
    t.equal o.foo, 'bar'
    t.ok not('foo' of o.given)

    o = p.parse ['--foo=baz']
    t.equal o.foo, 'baz'
    t.equal o.given.foo, 'baz'

    o = p.parse ['--foo=bar']
    t.equal o.foo, 'bar'
    t.equal o.given.foo, 'bar'

    t.done()

exports.values = (t) ->
    t.expect 10
    p = new yanop.Parser
        foo:
            type: yanop.string
            default: 'bar'
        bar:
            type: yanop.flag
        given:
            short: 'g',
            long: [],
            type: yanop.string
        '_finalize':
            short: 'f',
            long: [],
            type: yanop.string
            default: 'drastically'
        baz:
            type: yanop.string

    o = p.parse ['-gqux']
    t.equal o.values.foo, 'bar'
    t.ok not('foo' of o.given)
    t.equal o.values.bar, false
    t.ok not('bar' of o.given)

    t.equal o.values.given, 'qux'
    t.equal o.given.given, 'qux'
    t.notEqual o.given, 'qux'

    t.equal o.values._finalize, 'drastically'
    t.ok not('_finalize' of o.given)
    t.equal o._finalize, 'drastically'

    t.done()
