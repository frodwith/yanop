ex            = require './exceptions'
type          = require './types'
specification = require './specification'

class Result
    constructor: (@parser) ->
        @argv   = []
        @given  = {}

    # Add a positional argument to the result
    _arg: (blob) -> @argv.push blob

    # Mark a flag by given option name
    _flag: (name) ->
        throw new ex.NoValue name unless @parser.isFlag name
        target = @parser.index[name]
        @given[target] = true

    # Mark a param (scalar, array, or object) by name with value.
    _param: (name, value) ->
        throw new ex.NoValue name unless value

        p      = @parser
        target = p.index[name]
        throw new ex.UnknownOption name unless target
        spec   = p.spec[target]

        switch spec.type
            when type.flag
                throw new ex.FlagWithValue name: name, value: value
            when type.scalar
                throw new ex.ScalarWithValues name if target of @given
                @given[target] = value
            when type.array
                o = @given[target] or= []
                o.push value
            when type.object
                match = /^([^=]*)(?:=(.+))?$/.exec(value)
                o = @given[target] or= {}
                o[match[1]] = match[2]
            else
                throw new ex.UnvalidatedType(name)

    _finalize: () ->
        p = @parser
        @values = {}
        for own target, spec of p.spec
            # Setup values (as opposed to given) with defaults and whatnot
            if spec.type is type.flag
                v = !!@given[target]
            else if target of @given
                v = @given[target]
            else
                v = spec.default

            # throw errors if required parameters weren't seen
            if spec.required and (
                (spec.type is type.scalar and not v) or
                (spec.type is type.array  and v.length < 1)
            )
                throw new ex.RequiredMissing(target)

            @values[target] = v

            # fills out the convenience properties. Public methods and
            # properties can be overriden by these convenience properties if
            # they begin with an underscore.
            this[target] = v unless target of this and target.charAt(0) != '_'

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
                result._arg blob

            # -- stop processing and treat the rest of argv
            else if blob is '--'
                result._arg(a) for a in argv.slice(i+1)
                break

            # -vax is equivalent to -v -a -x if -v is a flag
            # -Dfoo is equivalent to -D=foo if -D isn't a flag
            else if match = /^-(\w.+)$/.exec(blob)
                name   = match[1]
                first  = '-' + name.charAt(0)

                if @isFlag first
                    result._flag('-' + f) for f in name.split('')
                else
                    result._param first, name.slice(1)

            # --answer=42 but NOT -answer=42. That will be parsed by
            # the above rule as -a nswer=42. We're also not supporting -a=42,
            # since that's not standard at all. That will be parsed as -a =42
            else if match = /^(--\w+)=(.*)$/.exec(blob)
                result._param match[1], match[2]

            # -v or --verbose
            else if match = /^(-\w)$/.exec(blob) or
                            /^(--\w+)$/.exec(blob)
                name = match[1]
                if @isFlag name
                    result._flag name
                else
                    # If it's not a flag, consume the next argument as value
                    result._param name, argv[++i]
            else
                # treat everything else as positional
                result._arg(blob)

            i += 1

        return result._finalize()
