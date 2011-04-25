reexport = (module) ->
    m = require module
    exports[key] = val for own key, val of m

reexport m for m in [
    './types'
    './exceptions'
    './Parser'
    './Help'
]
