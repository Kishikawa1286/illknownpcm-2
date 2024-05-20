module Mongo

using Mongoc
using JSON3

include("bson_base.jl")
using .BSON
export bson

include("crisp_bson.jl")
using .CrispBSON
export crispBson, parseCrispBson

include("interval_bson.jl")
using .IntervalBSON
export intervalBson, parseIntervalBson

include("twofold_interval_bson.jl")
using .TwofoldIntervalBSON
export twofoldIntervalBson, parseTwofoldIntervalBson


const client = Mongoc.Client("mongodb://localhost:27017")

"""
    database(name)

Returns a MongoDB database object.
"""
database(name::String) = client[name]

"""
    collection(database, name)

Returns a MongoDB collection object.
"""
collection(database, name::String) = database[name]

"""
    database_collection(databaseName, collectionName)

Returns a tuple of a MongoDB database and collection object.
"""
collection(databaseName, collectionName) = client[databaseName][collectionName]

export database, collection

"""
    parseBson(bson)

Returns a matrix or vector from a BSON object.
"""
function parseBson(bson)
    type = bson["type"]

    if type == "crispMatrix" || type == "crispVector"
        return parseCrispBson(bson)
    end

    if type == "intervalMatrix" || type == "intervalVector"
        return parseIntervalBson(bson)
    end

    if type == "twofoldIntervalMatrix" || type == "twofoldIntervalVector"
        return parseTwofoldIntervalBson(bson)
    end

    throw(ArgumentError("Unknown BSON type: $type"))
end

export parseBson

end
