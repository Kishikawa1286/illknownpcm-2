module SampleTable

using DataFrames
using UUIDs
using SQLite
using Tables
using JSON3

include("../../../utils/sqlite/v1/sqlite.jl")
using .SQLiteHelper

include("../../../utils/sqlite/v1/parser.jl")
using .MatrixParser

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

function getAllSamplesWithMatrixData(
    db::SQLite.DB,
    tableName::AbstractString,
    matrixTableName::AbstractString,
)::DataFrame
    query = """
    SELECT s.id AS sample_id, m.id AS matrix_id, m.type, m.rows, m.cols, m.data
    FROM $tableName AS s
    JOIN json_each(s.matrix_ids) AS je ON je.value = m.id
    JOIN $matrixTableName AS m ON je.value = m.id
    """
    result = DBInterface.execute(db, query) |> DataFrame
    if isempty(result)
        throw(ArgumentError("No matrix data found for sample id: $sampleId"))
    end
    return result
end

function parseAndReturnAllMatrixData(
    db::SQLite.DB,
    tableName::AbstractString,
    matrixTableName::AbstractString
)
    dataFrame = getAllSamplesWithMatrixData(db, tableName, matrixTableName)
    groupedData = groupby(dataFrame, :sample_id)
    parsedData = [
        (
            sample_id=key.sample_id,
            matrices=[
                (
                    id=row[:matrix_id],
                    data=parseMatrixData(row)
                ) for row in eachrow(subgroup)
            ]
        ) for (key, subgroup) in pairs(groupedData)
    ]
    return parsedData
end

export parseAndReturnAllMatrixData

end
