module TwofoldIntervalTable

using Tables
using SQLite
using JSON3
using IntervalArithmetic

include("../../ahp/twofold_interval/v1/twofold_interval.jl")
using .TwofoldIntervalArithmetic

include("interval.jl")
using .IntervalTable

include("sqlite.jl")
using .SQLiteHelper

"""
    encodeTwofoldInterval(x)

Encode a twofold interval into a JSON array.
"""
function encodeTwofoldInterval(
    x::TwofoldInterval{T}
)::Vector{Union{Vector{Float64},String}} where {T<:Real}
    if !isTwofoldInterval(x)
        throw(ArgumentError("Invalid twofold interval: ($(x[1]), $(x[2]))"))
    end
    return [
        encodeInterval(x[1]),
        encodeInterval(x[2])
    ]
end

"""
    decodeTwofoldInterval(x)

Decode a JSON array into a twofold interval.
"""
function decodeTwofoldInterval(
    x::JSON3.Array
)::TwofoldInterval{Float64}
    if length(x) != 2
        throw(ArgumentError("Array length must be 2"))
    end

    return (
        decodeInterval(x[1]),
        decodeInterval(x[2])
    )
end

"""
    insertTwofoldIntervalData(db, tableName, id, data)

Insert a twofold interval matrix or vector into a SQLite database.
"""
function insertTwofoldIntervalData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    data::AbstractMatrix{TwofoldInterval{T}}
) where {T<:Real}
    twofoldIntervalData = [encodeTwofoldInterval(x) for x in data]
    jsonData = JSON3.write(twofoldIntervalData)
    queryMatrixDataInsert(
        db,
        tableName,
        id,
        "twofold_interval_matrix",
        size(data, 1),
        size(data, 2),
        jsonData
    )
end

function insertTwofoldIntervalData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    data::AbstractVector{TwofoldInterval{T}}
) where {T<:Real}
    twofoldIntervalData = [encodeTwofoldInterval(x) for x in data]
    jsonData = JSON3.write(twofoldIntervalData)
    queryMatrixDataInsert(
        db,
        tableName,
        id,
        "twofold_interval_vector",
        length(data),
        1,
        jsonData
    )
end

export insertTwofoldIntervalData

"""
    getTwofoldIntervalData(db, tableName, id)

Get the twofold interval matrix or vector from the table.
Throws an `ArgumentError` if the document does not exist.
"""
function getTwofoldIntervalData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString
)::Union{
    AbstractMatrix{TwofoldInterval{Float64}},
    AbstractVector{TwofoldInterval{Float64}}
}
    data = queryMatrixDataSelect(db, tableName, id)
    type = data[:type]
    jsonData = data[:data]

    if type == "twofold_interval_matrix"
        rows = data[:rows]
        cols = data[:cols]
        decodedJson = JSON3.read(jsonData)
        return reshape(
            [decodeTwofoldInterval(x) for x in decodedJson],
            rows,
            cols
        )
    end

    if type == "twofold_interval_vector"
        length = data[:rows]
        decodedJson = JSON3.read(jsonData)
        return reshape(
            [decodeTwofoldInterval(x) for x in decodedJson],
            length,
        )
    end

    error("Unknown data type: $type")
end

export getTwofoldIntervalData

end
