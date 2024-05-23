module SampleTable

using DataFrames
using UUIDs
using SQLite
using Tables
using JSON3

include("../../../utils/sqlite/v1/sqlite.jl")
using .SQLiteHelper

samplesDataSchema = Tables.Schema(
    [:id, :matrix_ids],
    [String, String]
)

"""
    createSamplesTable(db, tableName)

Create a table to store samples in the database.
"""
createSamplesTable(
    db::SQLite.DB,
    tableName::AbstractString
) = createTable(db, tableName, samplesDataSchema)

export createSamplesTable

querySampleInsert(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    matrixIds::AbstractString
) = DBInterface.execute(
    db,
    """
    INSERT INTO $tableName (id, matrix_ids)
    VALUES (?, ?)
    """,
    (id, matrixIds)
)

"""
    insertSample(db, tableName, id, matrixIds)

Insert a sample into the table.
"""
function insertSample(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    matrixIds
)
    encodedMatrixIds = JSON3.write(matrixIds)
    println(encodedMatrixIds)
    querySampleInsert(db, tableName, id, encodedMatrixIds)
end

export insertSample

function querySampleSelect(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString
)::DataFrameRow
    df = DBInterface.execute(
        db,
        """
        SELECT * FROM $tableName
        WHERE id = ?
        """,
        (id,)
    ) |> DataFrame
    if isempty(df)
        throw(ArgumentError("No data found for id: $id"))
    end
    return df[1, :]
end

"""
    getSample(db, tableName, id)

Get a sample from the table.
"""
function getMatrixIds(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString
)::Vector{AbstractString}
    sample = querySampleSelect(db, tableName, id)
    return JSON3.read(sample.matrix_ids)
end

export getMatrixIds

"""
    getSampleIds(db, tableName)

Get the ids of all samples in the table.
"""
function getSampleIds(
    db::SQLite.DB,
    tableName::AbstractString
)::Vector{AbstractString}
    df = DBInterface.execute(
        db,
        """
        SELECT id FROM $tableName
        """
    ) |> DataFrame
    return df.id
end

export getSampleIds

end
