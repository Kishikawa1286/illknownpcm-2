module SQLiteHelper

using SQLite
using Tables

# Database operations

"""
    database(filePath)

Create a SQLite database at the given file path.
"""
database(filePath::AbstractString) = SQLite.DB(filePath)

"""
    load!(db, tableName)

Load the table with the given name from the database.
"""
load!(db::SQLite.DB, tableName::AbstractString) = SQLite.load!(db, tableName)

export database, load!

# Table operations

"""
    createTable!(db, tableName, schema)

Create a table with the given name and schema in the database.
If the table already exists, an error will be thrown.
"""
createTable!(
    db::SQLite.DB,
    tableName::AbstractString,
    schema::Tables.Schema
) = SQLite.createtable!(db, tableName, schema; ifnotexists=false)

"""
    dropTable!(db, tableName)

Drop the table with the given name from the database.
If the table does not exist, an error will be thrown.
"""
dropTable!(
    db::SQLite.DB,
    tableName::AbstractString
) = SQLite.drop!(db, tableName; ifexists=false)

export createTable!, dropTable!

end
