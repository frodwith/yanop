ex            = require './exceptions'
type          = require './types'
specification = require './specification'

class Result
    constructor: (@parser) ->
        @argv = []

    # Add a positional argument to the result
    arg: (blob) -> @argv.push blob

    # Mark a flag by given option name
    flag: (name) ->
        throw new ex.NoValue name unless @parser.isFlag name
        target = @parser.index[name]
        this[target] = true

    # Mark a param (scalar, array, or object) by name with value.
    param: (name, value) ->
        throw new ex.NoValue name unless value

        p      = @parser
        target = p.index[name]
        throw new ex.UnknownOption name unless target
        spec   = p.spec[target]

        switch spec.type
            when type.flag
                throw new ex.FlagWithValue name: name, value: value
            when type.scalar
                if this[target]
                    throw new ex.ScalarWithValues name
                this[target] = value
            when type.array
                o = this[target] or= []
                o.push value
            when type.object
                match = /^([^=]*)(?:=(.+))?$/.exec(value)
                o = this[target] or= {}
                o[match[1]] = match[2]
            else
                throw new ex.UnvalidatedType(name)

    # Set defaults, throw errors if required parameters weren't seen.
    finalize: () ->
        p = @parser
        for own target, spec of p.spec
            if (spec.type isnt type.flag) and not this[target]
                this[target] = spec.default

            value = this[target]
            if spec.required and (
                (spec.type is type.scalar and not value) or
                (spec.type is type.array  and value.length < 1)
            )
                throw new ex.RequiredMissing(target)

        return this

exports.Parser = class Parser
    constructor: (@spec) ->
        @index = specification.index(@spec)

    isFlag: (name) ->
        target = @index[name]
        throw new ex.UnknownOption(name) unless target
        @spec[target].type is type.flag

    parse: (argv) ->
        result = new Result(this)
        i = 0
        while i < argv.length
            blob = argv[i]

            # special case for single - (usually means stdin)
            if blob is '-'
                result.arg blob

            # -- stop processing and treat the rest of argv
            else if blob is '--'
                result.arg(a) for a in argv.slice(i+1)
                break

            # -vax is equivalent to -v -a -x if -v is a flag
            # -Dfoo is equivalent to -D=foo if -D isn't a flag
            else if match = /^-(\w.+)$/.exec(blob)
                name   = match[1]
                first  = '-' + name.charAt(0)

                if @isFlag first
                    result.flag('-' + f) for f in name.split('')
                else
                    result.param first, name.slice(1)

            # --answer=42 but NOT -answer=42. That will be parsed by
            # the above rule as -a nswer=42. We're also not supporting -a=42,
            # since that's not standard at all. That will be parsed as -a =42
            else if match = /^(--\w+)=(.*)$/.exec(blob)
                result.param match[1], match[2]

            # -v or --verbose
            else if match = /^(-\w)$/.exec(blob) or
                            /^(--\w+)$/.exec(blob)
                name = match[1]
                if @isFlag name
                    result.flag name
                else
                    # If it's not a flag, consume the next argument as value
                    result.param name, argv[++i]
            else
                # treat everything else as positional
                result.arg(blob)

            i += 1

        return result.finalize()
