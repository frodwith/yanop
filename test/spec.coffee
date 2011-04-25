spec = require '../lib/specification'
ex   = require '../lib/exceptions'
type = require '../lib/types'

exports.type = (t) ->
    t.expect 2
    t.throws (() -> spec.index { foo: { short: 'f' }}), ex.NoType
    t.throws (() -> spec.index { foo: { type: 'none'}}), ex.UnknownType
    t.done()

exports.short = (t) ->
    t.expect 4
    short = (err, val) ->
        cons = () ->
            spec.index
                foo:
                    type:  type.flag
                    short: val
        tfn  = if err then t.throws else t.doesNotThrow
        tfn.call t, cons, ex.InvalidShort

    short true, 'foo'
    short true, 'ab'
    short false, 'a'
    short false, 'b'
    t.done()

exports.conflicts = (t) ->
    t.expect 6

    conflict = (err, fn) ->
        s =
            foo: { type: type.flag }
            bar: { type: type.flag }
        fn s
        tfn  = if err then t.throws else t.doesNotThrow
        cons = () -> spec.index s
        tfn.call t, cons, ex.Conflict

    conflict true, (s) -> s.bar.long = 'foo'
    conflict true, (s) -> s.foo.long = ['foo', 'bar', 'baz']

    conflict true, (s) ->
        s.foo.long = 'different'
        s.bar.long = 'different'

    conflict true, (s) ->
        s.foo.short = 's'
        s.bar.short = ['q', 'r', 's']

    conflict false, (s) ->
        s.foo.long  = 's'
        s.bar.short = 's'

    conflict false, (s) ->
        s.foo.short = 'a'
        s.bar.long  = ['a', 'abstruse']

    t.done()
