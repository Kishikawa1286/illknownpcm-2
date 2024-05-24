module IntervalTable

using DataFrames
using Tables
using SQLite
using JSON3
using IntervalArithmetic

include("sqlite.jl")
using .SQLiteHelper

"""
    encodeInterval(x)

Encode an interval into a JSON array.
"""
function encodeInterval(
    x::Interval{T}
)::Union{Vector{Float64},String} where {T<:Real}
    if iscommon(x)
        return [Float64(inf(x)), Float64(sup(x))]
    end

    return "empty"
end

"""
    decodeInterval(x)

Decode a JSON array into an interval.
"""
function decodeInterval(
    x::Union{JSON3.Array,String}
)::Interval{Float64}
    if x == "empty"
        return emptyinterval()
    end

    if length(x) != 2
        throw(ArgumentError("Array length must be 2"))
    end

    return interval(x[1], x[2])
end

export encodeInterval, decodeInterval

"""
    insertIntervalData(db, tableName, id, data)

Insert an interval matrix or vector into the table.
"""
function insertIntervalData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    data::AbstractMatrix{Interval{T}}
) where {T<:Real}
    intervalData = [
        encodeInterval(x) for x in data]
    # JSON3.write returns the 2-dimensional array
    # rows are ignored
    # [ [a_1^L, a_1^U], [a_2^L, a_2^U], ..., [a_{m*n}^L, a_{m*n}^U] ]
    jsonData = JSON3.write(intervalData)
    queryMatrixDataInsert(
        db,
        tableName,
        id,
        "interval_matrix",
        size(data, 1),
        size(data, 2),
        jsonData
    )
end

function insertIntervalData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    data::AbstractVector{Interval{T}}
) where {T<:Real}
    intervalData = [
        encodeInterval(x) for x in data]
    jsonData = JSON3.write(intervalData)
    queryMatrixDataInsert(
        db,
        tableName,
        id,
        "interval_vector",
        length(data),
        1,
        jsonData
    )
end

export insertIntervalData

"""
    parseIntervalData(data)

Parse the interval matrix or vector from the table.
"""
function parseIntervalData(
    data::DataFrameRow
)::Union{
    Matrix{Interval{Float64}},
    Vector{Interval{Float64}}
}
    type = data[:type]
    jsonData = data[:data]

    if type == "interval_matrix"
        rows = data[:rows]
        cols = data[:cols]
        decodedJson = JSON3.read(jsonData) # m x n x 2 array
        return reshape(
            [decodeInterval(x) for x in decodedJson],
            rows,
            cols
        )
    end

    if type == "interval_vector"
        length = data[:rows]
        decodedJson = JSON3.read(jsonData) # m x 2 array
        return reshape(
            [decodeInterval(x) for x in decodedJson],
            length
        )
    end

    error("Unknown data type: $type")
end

"""
    getIntervalData(db, tableName, id)

Get the interval matrix or vector from the table.
Throws an `ArgumentError` if the document does not exist.
"""
function getIntervalData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString
)::Union{Matrix{Interval{Float64}},Vector{Interval{Float64}}}
    data = queryMatrixDataSelect(db, tableName, id)
    return parseIntervalData(data)
end

export parseIntervalData, getIntervalData

end
