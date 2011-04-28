getopt = require 'getopt'
sys    = require 'sys'

o = getopt.simple
    munge:
        type: getopt.flag
        description: 'Whether or not to munge'
    ickiness:
        type: getopt.scalar
        default: 1
        description: 'How icky to make the munging'

if o.munge
    sys.puts "Munge..." for [1..o.ickiness]
