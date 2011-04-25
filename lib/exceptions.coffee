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
