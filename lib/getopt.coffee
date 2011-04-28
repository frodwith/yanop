file = require 'file'
path = require 'path'

reexport = (module) ->
    m = require module
    exports[key] = val for own key, val of m

reexport m for m in [
    './types'
    './exceptions'
    './Parser'
    './Help'
]

getargs = (argv) -> argv or process.argv.slice 2

exports.parse = (spec, argv) ->
    new exports.Parser(spec).parse getargs argv

exports.zero = () ->
    abs    = path.normalize process.argv[1]
    rel    = file.path.relativePath process.cwd(), abs
    script = if rel.length < abs.length then rel else abs
    "#{ process.argv[0] } #{ script }"

exports.usage = () -> "\nUsage: #{ exports.zero() } [OPTIONS]\n"
exports.help  = (spec) -> new exports.Help(spec).toString()

exports.tryParse = (spec, argv) ->
    p = new exports.Parser(spec)
    try
        o = p.parse getargs argv
    catch e
        throw e unless e instanceof exports.ParseError
        process.stderr.write e.message + "\n"
        process.exit 1

    return o

exports.simple = exports.tryParseWithHelp = (spec, banner, argv) ->
    spec.help or=
        type: exports.flag
        short: 'h'
        description: 'Print this message and exit'

    p = new exports.Parser spec
    try
        argv = getargs argv
        o = p.parse getargs argv
        if o.help
            h = exports.help spec
            banner or= exports.usage()
            process.stdout.write [
                banner
                "The following options are recognized:\n"
                h,
            ].join("\n") + "\n\n"
            process.exit 0
    catch e
        throw e unless e instanceof exports.ParseError
        h = spec.help
        flag = if h.long then "--#{ h.long }" else "-#{ h.short }"
        process.stderr.write e.message +
            ". Pass #{ flag } for usage information.\n"
        process.exit 1

    return o
