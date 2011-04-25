ex   = require './exceptions'
type = require './types'

exports.index = (spec) ->
    index = {}
    for own target, sub of spec
        # upgrade scalars to arrays
        longs = sub.long or [target]
        longs = [longs] unless Array.isArray longs
        sub.long = longs

        shorts = sub.short or []
        shorts = [shorts] unless Array.isArray shorts
        sub.short = shorts

        alias = ('--' + l for l in longs)

        for s in shorts
            if s.length isnt 1
                throw new ex.InvalidShort(s)
            alias.push '-' + s

        for a in alias
            existing = index[a]
            throw new ex.Conflict(target, a, existing) if existing
            index[a] = target

        t = sub.type
        throw new ex.NoType(target) unless t

        if t is type.array
            sub.default or= []
        else if t is type.object
            sub.default or= {}
        else if t isnt type.scalar and t isnt type.flag
            throw new ex.UnknownType name: target, type: t

    index
