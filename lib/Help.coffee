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
            line.fl    = left[0]
            line.ll    = left[left.length-1]
            line.right = sub.description.trim()
            line.right += '.' unless line.right.match(/\.$/)
            line.right += ' Required.' if sub.required

            if sub.default
                line.right += ' Default: ' + JSON.stringify(sub.default)

            lines.push line

        # Right-justify the left sides
        lengths = (l.ll.length for l in lines)
        max     = Math.max.apply(Math, lengths)
        for line in lines
            for l, i in line.left
                pad = max - l.length
                l = ' ' + l for [1..pad] if pad
                line.left[i] = l + '  '

        # Left-justify the right sides two spaces away

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

        lines.sort (a, b) -> (a.rank - b.rank) or a.fl.localeCompare(b.fl)
        out = (l.left.join("\n") + l.right for l in lines).join "\n\n"
        console.log out
        out
