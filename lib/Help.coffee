specification = require './specification'
type          = require './types'

leftCol = (spec, alias, long) ->
    prefix = if long then '--' else '-'
    str = prefix + alias

    if spec.type isnt type.flag
        if spec.type is type.object
            str += ' KEY=VAL'
        else if long
            str += '=VAL'
        else
            str += ' VAL'

    str

rank = {}
rank[type[t]] = i for t, i in ['flag', 'scalar', 'array', 'object']

exports.Help = class Help
    tw: 78

    constructor: (@spec) ->
        specification.index(@spec)

    toString: () ->
        lines = []
        for own target, sub of @spec
            line = { rank: rank[sub.type] }
            left = (leftCol(sub, s, false) for s in sub.short.slice(0).sort())
            left.push leftCol(sub, s, true) for s in sub.long.slice(0).sort()

            line.left  = left
            line.first = left[0]
            line.last  = left[left.length-1]

            right = []
            if desc = sub.description.trim().replace(/\.$/, '')
                right.push desc

            right.push 'Required' if sub.required
            if sub.type is type.array or sub.type is type.object
                right.push 'Can be specified multiple times'

            if sub.default
                right.push 'Default: ' + JSON.stringify(sub.default)

            line.right = right.join('. ')
            line.right += '.' if right.length

            lines.push line

        # Right-justify the left sides
        lengths = (l.last.length for l in lines)
        max     = Math.max.apply(Math, lengths)
        for line in lines
            for l, i in line.left
                pad = max - l.length
                l = ' ' + l for [1..pad] if pad
                line.left[i] = l
            line.left[line.left.length-1] += '  '

        # Left-justify the right sides two spaces away, wrapped to tw
        remaining = @tw - max - 2
        sep = "\n"
        sep += ' ' for [1..max+2]

        for l, i in lines
            words = (w.trim() for w in l.right.split /\s/)
            words = (w for w in words if w.length > 0)
            all   = ''
            cur   = words.shift()
            while words.length > 0
                w = words.shift()
                if w.length + cur.length < remaining
                    cur += ' ' + w
                else
                    all += cur + sep
                    cur = w
            lines[i].right = all + cur

        # Flags first, then scalars, etc -- sorted by beginning of line in
        # lex order. This is as much so that we can have a canonical order to
        # test as anything.
        lines.sort (a, b) ->
            (a.rank - b.rank) or a.first.localeCompare(b.first)

        (l.left.join("\n") + l.right for l in lines).join "\n\n"
