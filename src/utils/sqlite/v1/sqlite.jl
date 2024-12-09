module SQLiteHelper

using DataFrames
using SQLite
using Tables

# Database operations

"""
    database(filePath)

Create a SQLite database at the given file path.
"""
database(filePath::AbstractString) = SQLite.DB(filePath)

"""
    load(db, tableName)

Load the table with the given name from the database.
"""
load(db::SQLite.DB, tableName::AbstractString) = SQLite.load!(db, tableName)

export database, load

# Table operations

"""
    createTable(db, tableName, schema)

Create a table with the given name and schema in the database.
If the table already exists, an error will be thrown.
"""
createTable(
    db::SQLite.DB,
    tableName::AbstractString,
    schema::Tables.Schema
) = SQLite.createtable!(db, tableName, schema)

"""
    dropTable(db, tableName)

Drop the table with the given name from the database.
If the table does not exist, an error will be thrown.
"""
dropTable(
    db::SQLite.DB,
    tableName::AbstractString
) = SQLite.drop!(db, tableName; ifexists=false)

export createTable, dropTable

# Matrix table operations

matrixDataSchema = Tables.Schema(
    [:id, :type, :rows, :cols, :data],
    [String, String, Int, Int, String]
)

"""
    createMatrixTable!(db, tableName)

Create a matrix table with the given name in the database.
"""
createMatrixTable(
    db::SQLite.DB,
    tableName::AbstractString
) = SQLite.createtable!(db, tableName, matrixDataSchema)

"""
    queryMatrixDataSelect(db, tableName, id)

Insert a matrix or vector into the table.
"""
queryMatrixDataInsert(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    type::AbstractString,
    rows::Int,
    cols::Int,
    data::AbstractString
) = DBInterface.execute(
    db,
    """
    INSERT INTO $tableName (id, type, rows, cols, data)
    VALUES (?, ?, ?, ?, ?)
    """,
    (id, type, rows, cols, data)
)

"""
    queryMatrixDataSelect(db, tableName, id)

Select a matrix or vector from the table.
Returns a DataFrameRow.
Throw an `ArgumentError` if no data is found for the given id.
"""
function queryMatrixDataSelect(
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

function matrixDataExists(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString
)::Bool
    try
        queryMatrixDataSelect(db, tableName, id)
        return true
    catch
        return false
    end
end

export createMatrixTable, queryMatrixDataInsert, queryMatrixDataSelect, matrixDataExists

# ID table operations

idSchema = Tables.Schema(
    [:id],
    [String]
)

"""
    createIDTable(db, tableName)

Create an ID table with the given name in the database.
"""
function createIDTable(
    db::SQLite.DB,
    tableName::AbstractString
)
    SQLite.createtable!(db, tableName, idSchema)
end

"""
    insertID(db, tableName, id)

Insert an ID into the table.
"""
function insertID(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString
)
    DBInterface.execute(
        db,
        """
        INSERT INTO $tableName (id)
        VALUES (?)
        """,
        (id,)
    )
end

"""
    getAllIDs(db, tableName) -> Vector{String}

Get all IDs from the table.
"""
function getAllIDs(
    db::SQLite.DB,
    tableName::AbstractString
)::Vector{String}
    df = DBInterface.execute(
        db,
        """
        SELECT id FROM $tableName
        """
    ) |> DataFrame
    return df.id
end

export createIDTable, insertID, getAllIDs

# Bool table operations

boolSchema = Tables.Schema(
    [:id, :value],
    [String, Bool]
)

"""
    createBoolTable(db, tableName)

Create a bool table with the given name in the database.
"""
function createBoolTable(
    db::SQLite.DB,
    tableName::AbstractString
)
    SQLite.createtable!(db, tableName, boolSchema)
end

"""
    insertBool(db, tableName, id, value)

Insert an ID and a Bool value into the table.
"""
function insertBool(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString,
    value::Bool
)
    DBInterface.execute(
        db,
        """
        INSERT INTO $tableName (id, value)
        VALUES (?, ?)
        """,
        (id, value)
    )
end

"""
    getBool(db, tableName, id) -> Bool

Get a Bool value from the table by ID.
Throw an `ArgumentError` if the ID does not exist.
"""
function getBool(
    db::SQLite.DB,
    tableName::AbstractString,
    id::AbstractString
)::Bool
    df = DBInterface.execute(
        db,
        """
        SELECT value FROM $tableName
        WHERE id = ?
        """,
        (id,)
    ) |> DataFrame
    if isempty(df)
        throw(ArgumentError("No Bool value found for id: $id"))
    end
    return df.value[1]
end

export createBoolTable, insertBool, getBool

end
