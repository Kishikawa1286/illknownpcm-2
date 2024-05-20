module Mongo

import Base: read

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


const client = Mongoc.Client("mongodb://mongo:27017")

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
collection(databaseName::String, collectionName::String) = client[databaseName][collectionName]

export database, collection

"""
    read(collection, id)

Reads a single document from a MongoDB collection by ID.
"""
function read(collection, id::String)
    selector = bson(Dict("_id" => id))
    return Mongoc.find_one(collection, selector)
end

export read

"""
    query(collection, query)

Queries a MongoDB collection with a BSON query object.
Query is a BSON object that filters the documents.

See: [Mongoc.jl document](https://felipenoris.github.io/Mongoc.jl/stable/crud/#Select)
"""
query(collection, query::Mongoc.BSON) = Mongoc.find(collection, query)

export query

"""
    create(collection, document)

Creates a BSON object into a MongoDB collection.
If the BSON object does not have an `_id` field, an error is thrown.
"""
function create(collection, document::Mongoc.BSON)
    if isnothing(document["_id"])
        throw(ArgumentError("BSON object must have an _id field"))
    end
    return Mongoc.insert_one(collection, document)
end

"""
    create(collection, document::Vector{Mongoc.BSON})

Creates multiple BSON objects into a MongoDB collection.
If any of the BSON objects do not have an `_id` field, an error is thrown.
"""
function create(collection, document::Vector{Mongoc.BSON})
    if any(document -> isnothing(document["_id"]), document)
        throw(ArgumentError("BSON object must have an _id field"))
    end
    return Mongoc.insert_many(collection, document)
end

export create

"""
    update(collection, id, update)

Updates a single document in a MongoDB collection.
Specify the updated document by ID.
"""
function update(collection, id::String, update::Mongoc.BSON)
    selector = bson(Dict("_id" => id))
    return Mongoc.update_one(
        collection,
        selector,
        bson(Dict("$set" => update))
    )
end

export update

"""
    delete(collection, id)

Deletes a single document from a MongoDB collection.
"""
function delete(collection, id::String)
    selector = bson(Dict("_id" => id))
    return Mongoc.delete_one(collection, selector)
end

export delete

end
