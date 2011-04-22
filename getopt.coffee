exports[t] = t.toUpperCase() for t in ['flag', 'scalar', 'array', 'object']
exports.list = exports.array
exports.hash = exports.object
exports.bool = exports.flag

exports.BaseError         = class BaseError extends Error
    constructor: (@desc) ->
        Error.captureStackTrace(this, this.constructor)
        @message = @describe()

    toString: () ->
        'getopt.' + @constructor.name + ': ' + @describe()

    describe: () ->
        JSON.stringify(@desc)

exports.InternalError     = class InternalError extends BaseError
exports.UnvalidatedType   = class UnvalidatedType extends InternalError

exports.SpecError         = class SpecError extends BaseError
exports.InvalidShort      = class InvalidShort extends SpecError
exports.Conflict          = class Conflict extends SpecError
exports.NoType            = class NoType extends SpecError
exports.UnknownType       = class UnknownType extends SpecError

exports.ParseError        = class ParseError extends BaseError

exports.UnknownOption     = class UnknownOption extends ParseError
    describe: () -> "Unknown option #{ @desc } encountered"

exports.NoValue           = class NoValue extends ParseError
    describe: () -> @desc + " requires a value, but none was given"

exports.FlagWithValue     = class FlagWithValue extends ParseError
    describe: () ->
        "#{ @desc.name } was given \"#{ @desc.value }\", but takes no arguments"

exports.ScalarWithValues  = class ScalarWithValues extends ParseError
    describe: () -> @desc + " was given more than one value"

exports.RequiredMissing   = class RequiredMissing extends ParseError
    describe: () -> "Required option #{ @desc } was missing"

class Result
    constructor: (@parser) ->
        @argv = []

    # Add a positional argument to the result
    arg: (blob) -> @argv.push blob

    # Mark a flag by given option name
    flag: (name) ->
        throw new NoValue name unless @parser.isFlag name
        target = @parser.index[name]
        this[target] = true

    # Mark a param (scalar, array, or object) by name with value.
    param: (name, value) ->
        throw new NoValue name unless value

        p      = @parser
        target = p.index[name]
        throw new UnknownOption name unless target
        spec   = p.spec[target]

        switch spec.type
            when exports.flag
                throw new FlagWithValue name: name, value: value
            when exports.scalar
                if this[target]
                    throw new ScalarWithValues name
                this[target] = value
            when exports.array
                o = this[target] or= []
                o.push value
            when exports.object
                match = /^([^=]*)(?:=(.+))?$/.exec(value)
                o = this[target] or= {}
                o[match[1]] = match[2]
            else
                throw new UnvalidatedType(name)

    # Set defaults, throw errors if required parameters weren't seen.
    finalize: () ->
        p = @parser
        for own target, spec of p.spec
            if (spec.type isnt exports.flag) and not this[target]
                this[target] = spec.default

            value = this[target]
            if spec.required and (
                (spec.type is exports.scalar and not value) or
                (spec.type is exports.array  and value.length < 1)
            )
                throw new RequiredMissing(target)

        return this

exports.Parser = class Parser
    constructor: (spec) ->
        @spec  = spec
        @index = {}
        for own target, subspec of spec

            # upgrade scalars to arrays
            longs = subspec.long or [target]
            longs = [longs] unless Array.isArray longs
            subspec.long = longs

            shorts = subspec.short or []
            shorts = [shorts] unless Array.isArray shorts
            subspec.short = shorts

            alias = ('--' + l for l in longs)

            for s in shorts
                if s.length isnt 1
                    throw new InvalidShort(s)
                alias.push '-' + s

            for a in alias
                existing = @index[a]
                throw new Conflict(target, a, existing) if existing
                @index[a] = target

            t = subspec.type
            throw new NoType(target) unless t

            if t is exports.array
                subspec.default or= []
            else if t is exports.object
                subspec.default or= {}
            else if t isnt exports.scalar and t isnt exports.flag
                throw new UnknownType name: target, type: t


    isFlag: (name) ->
        target = @index[name]
        throw new UnknownOption(name) unless target
        @spec[target].type is exports.flag

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
