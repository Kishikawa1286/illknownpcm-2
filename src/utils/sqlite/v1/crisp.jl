module CrispTable

using DataFrames
using Tables
using SQLite
using JSON3

include("sqlite.jl")
using .SQLiteHelper

"""
    insertCrispData(db, tableName, id, data)

Insert a crisp matrix or vector into the table.
"""
function insertCrispData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    data::AbstractMatrix{T}
) where {T<:Real}
    float64Data = convert(Matrix{Float64}, data)
    jsonData = JSON3.write(float64Data)
    return queryMatrixDataInsert(
        db,
        tableName,
        id,
        "crisp_matrix",
        size(float64Data, 1),
        size(float64Data, 2),
        jsonData
    )
end

function insertCrispData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    data::AbstractVector{T}
) where {T<:Real}
    float64Data = convert(Vector{Float64}, data)
    jsonData = JSON3.write(float64Data)
    return queryMatrixDataInsert(
        db,
        tableName,
        id,
        "crisp_vector",
        length(float64Data),
        1,
        jsonData
    )
end

export insertCrispData

"""
    parseCrispData(data)

Parse the crisp matrix or vector from the table.
"""
function parseCrispData(
    data::DataFrameRow
)::Union{
    AbstractMatrix{Float64},
    AbstractVector{Float64}
}
    type = data[:type]
    jsonData = data[:data]

    if type == "crisp_matrix"
        rows = data[:rows]
        cols = data[:cols]
        return reshape(JSON3.read(jsonData), rows, cols)
    end

    if type == "crisp_vector"
        length = data[:rows]
        return reshape(JSON3.read(jsonData), length)
    end

    error("Unknown data type: $type")
end

"""
    getCrispData(db, tableName, id)

Get a crisp matrix or vector from the table by ID.
Throws an `ArgumentError` if the document does not exist.
"""
function getCrispData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString
)::Union{
    AbstractMatrix{Float64},
    AbstractVector{Float64}
}
    data = queryMatrixDataSelect(db, tableName, id)
    return parseCrispData(data)
end

export parseCrispData, getCrispData

end
