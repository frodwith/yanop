getopt = require '../lib/getopt'

exports.basic = (t) ->
    t.expect 1
    spec =
        verbose:
            type: getopt.flag
            short: 'v'
            description: 'Print debugging messages'
        output:
            type: getopt.scalar
            short: 'o'
            description: 'Filename (- for stdout) to write output to.'
            default: '-'
        input:
            type: getopt.list
            short: 'i'
            description: 'Filename(s) (- for stdin) to read input from'
            default: ['-']
        password:
            type: getopt.scalar
            short: 'p'
            description: 'Secret string to use when connecting to server. This description is going to be ridiculously long so that we can test the line breaking a bit'
            required: true
        symbols:
            type: getopt.hash
            short: 'D',
            long: 'define'
            description: 'Symbols to define during processing'
    u = new getopt.Help spec
    t.equals u.toString(), '''
-v
--verbose         Print debugging messages.

-o VAL
--output=VAL      Filename (- for stdout) to write output to. default: -

--password=VAL    Secret string to use when connecting to server. This
                  description is going to be ridiculously long so that we can
                  test the line breaking a bit. Required.
 
-i VAL
--input=VAL       Filename(s) (- for stdin) to read input from. Can be 
                  specified multiple times.

-D KEY=VAL
--define KEY=VAL  Symbols to define during processing. Can be specified 
                  multiple times.
'''
    t.done()
