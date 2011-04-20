getopt = require('getopt')

exports.oneFlag = (t) ->
    t.expect 5

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
    t.done()
