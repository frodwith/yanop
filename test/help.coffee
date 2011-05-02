yanop = require '../lib/yanop'

expected = '''
                -v
         --verbose  Print debugging messages.
  
    --password=VAL  Secret string to use when connecting to server. This
                    description is going to be ridiculously long so that we can
                    test the line breaking a bit. Required.
  
            -o VAL
      --output=VAL  Filename (- for stdout) to write output to. Default: "-".
  
            -i VAL
       --input=VAL  Filename(s) (- for stdin) to read input from. Can be
                    specified multiple times. Default: ["-"].
  
        -D KEY=VAL
  --define KEY=VAL  Symbols to define during processing. Can be specified
                    multiple times. Default: {}.
  '''

exports.basic = (t) ->
    t.expect 1
    spec =
        verbose:
            type: yanop.flag
            short: 'v'
            description: 'Print debugging messages'
        output:
            type: yanop.scalar
            short: 'o'
            description: 'Filename (- for stdout) to write output to.'
            default: '-'
        input:
            type: yanop.list
            short: 'i'
            description: 'Filename(s) (- for stdin) to read input from'
            default: ['-']
        password:
            type: yanop.scalar
            description: 'Secret string to use when connecting to server. This description is going to be ridiculously long so that we can test the line breaking a bit'
            required: true
        symbols:
            type: yanop.hash
            short: 'D',
            long: 'define'
            description: 'Symbols to define during processing'
    u = new yanop.Help spec
    t.equals u.toString(), expected
    t.done()
