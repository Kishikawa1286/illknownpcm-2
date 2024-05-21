module CrispTable

using DataFrames
using Tables
using SQLite
using JSON3

crispDataSchema = Tables.Schema(
    [:id, :type, :rows, :cols, :data],
    [String, String, Int, Int, String]
)

"""
    createCrispDataTable!(db, tableName)

Create a Crisp table with the given name in the database.
"""
createCrispDataTable(
    db::SQLite.DB,
    tableName::AbstractString
) = SQLite.createtable!(db, tableName, crispDataSchema)

export createCrispDataTable

queryCrispDataInsert(
    db::SQLite.DB,
    tableName::AbstractString,
    id::String,
    type::String,
    rows::Int,
    cols::Int,
    data::String
) = DBInterface.execute(
    db,
    """
    INSERT INTO $tableName (id, type, rows, cols, data)
    VALUES (?, ?, ?, ?, ?)
    """,
    (id, type, rows, cols, data)
)

"""
    insertCrispData(db, tableName, id, data)

Insert a crisp matrix or vector into the table.
"""
function insertCrispData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::String,
    data::AbstractMatrix{T}
) where {T<:Real}
    float64Data = convert(Matrix{Float64}, data)
    jsonData = JSON3.write(float64Data)
    return queryCrispDataInsert(
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
    id::String,
    data::AbstractVector{T}
) where {T<:Real}
    float64Data = convert(Vector{Float64}, data)
    jsonData = JSON3.write(float64Data)
    return queryCrispDataInsert(
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

queryCrispDataSelect(
    db::SQLite.DB,
    tableName::AbstractString,
    id::String
) = begin
    df = DBInterface.execute(
        db,
        """
        SELECT * FROM $tableName
        WHERE id = ?
        """,
        (id,)
    ) |> DataFrame
    if nrow(df) == 0
        throw(ArgumentError("ID not found: $id"))
    end
    return df[1, :]
end

"""
    getCrispData(db, tableName, id)

Get a crisp matrix or vector from the table by ID.
Throws an `ArgumentError` if the document does not exist.
"""
function getCrispData(
    db::SQLite.DB,
    tableName::AbstractString,
    id::String
)::Union{
    AbstractMatrix{Float64},
    AbstractVector{Float64}
}
    data = queryCrispDataSelect(db, tableName, id)
    type = data[2]
    jsonData = data[5]
    if type == "crisp_matrix"
        rows = data[3]
        cols = data[4]
        return reshape(JSON3.read(jsonData), rows, cols)
    end

    if type == "crisp_vector"
        length = data[3]
        return reshape(JSON3.read(jsonData), length)
    end

    error("Unknown data type: $type")
end

export getCrispData

end
