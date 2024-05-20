module BSON

using Mongoc

"""
    bson(content)

Returns a BSON object from a bson string.
"""
bson(content::String) = Mongoc.BSON(content)

"""
    bson(content)

Returns a BSON object from a Dict.
"""
bson(content::Dict) = Mongoc.BSON(content)

export bson

end
