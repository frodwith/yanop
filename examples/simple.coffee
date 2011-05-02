yanop = require 'yanop'
sys    = require 'sys'

o = yanop.simple
    munge:
        type: yanop.flag
        description: 'Whether or not to munge'
    ickiness:
        type: yanop.scalar
        default: 1
        description: 'How icky to make the munging'

if o.munge
    sys.puts "Munge..." for [1..o.ickiness]
