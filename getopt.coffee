exports[t] = t.toUpperCase() for t in ['flag', 'scalar', 'array', 'object']

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

exports.FlagWithValue     = class FlagWithArguments extends ParseError
    describe: () ->
        "#{ @desc.name } was given \"#{ @desc.value }\", but takes no arguments"

exports.ScalarWithValues  = class ScalarWithValues extends ParseError
    describe: () -> @desc + " was given more than one value"

exports.ObjectNotPair     = class ObjectNotPair extends ParseError
    describe: () ->
        @desc.name + " expects a key=value pair, but got " + @desc.value

exports.ObjectKeyRepeated = class ObjectKeyRepeated extends ParseError
    describe: () -> "#{ @desc.name }.#{ @desc.key } given more than once"

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
                pair = value.split '='
                unless pair.length is 2
                    throw new ObjectNotPair name: name, value: value
                o = this[target] or= {}
                [k,v] = pair
                if o[k]
                    throw new ObjectKeyRepeated name: name, key: k
                o[k] = v
            else
                throw new UnvalidatedType(name)

    # Set defaults, throw errors if required parameters weren't seen.
    finalize: () ->
        p = @parser
        for own target, spec of p.spec
            if (spec.type isnt exports.flag) and this[target]?
                this[target] = spec.default

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
            longs = [longs] unless longs.length?
            subspec.long = longs

            shorts = subspec.short or []
            shorts = [shorts] unless shorts.length?
            subspec.short = shorts

            alias = longs.slice(0)

            for s in shorts
                if s.length isnt 1
                    throw new InvalidShort(s)
                alias.push s

            for a in alias
                existing = @index[a]
                throw new Conflict(target, a, existing) if existing
                @index[a] = target

            t = subspec.type
            throw new NoType(target) unless t

            if t is exports.array
                spec.default or= []
            else if t is exports.object
                spec.default or= {}
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

            # -vax is equivalent to -v -a -x
            else if match = /^-(\w\w+)$/.exec(blob)
                result.flag(f) for f in match[1].split()

            # -a=42 or --answer=42 or even -answer=42 (DWIM a bit)
            else if match = /^--?(\w+)=(.*)$/.exec(blob)
                result.param(match[1], match[2])

            # -v or --verbose
            else if match = /^-(\w)$/.exec(blob) or
                            /^--(\w+)$/.exec(blob)
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
