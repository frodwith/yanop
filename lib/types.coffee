exports[t] = t.toUpperCase() for t in ['flag', 'scalar', 'array', 'object']

exports[key] = exports[val] for own key, val of {
    string: 'scalar'
    list: 'array'
    hash: 'object'
    bool: 'flag'
}
