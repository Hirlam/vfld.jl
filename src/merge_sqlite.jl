module merge_sqlite

import Base
import SQLite
import DataFrames

const all_parameters = Base.Dict([("ID", "ID"),
                    ("LAT", "Latitude"),
                    ("LON", "Longitude"),
                    ("NN", "CloudCover2D"),
                    ("FI", "GeopotentialHeight"),
                    ("DD", "WindDirection"),
                    ("FF", "WindSpeed"),
                    ("GG", "WindGust"),
                    ("TT", "T2m"),
                    ("RH", "RH2m"),
                    ("PS", "MSLP"),
                    ("PSS", "PSurface"),
                    ("PE", "Precip12H"),
                    ("PE1", "Precip1H"),
                    ("PE3", "Precip3H"),
                    ("PE6", "Precip6H"),
                    ("PE24", "Precip24H"),
                    ("QQ", "Q2m"),
                    ("VI", "Visibility"),
                    ("TD", "TD2m"),
                    ("TX", "T2m_MaximaPast6H"),
                    ("TM", "T2m_MinimaPast6H"),
                    ("GM", "WindSpeed_Maxima1H"),
                    ("GX", "Max_Windgust1H"),
                    ("WX", "Unknown1"),
                    ("GW", "Unknown2"),
                    ("TIME", "Time")])


function merge(cmd_message)
    """Merges multiple SQLite files to a single SQLite file
    Assumes that the cmd_message comes in the following format:
    ("merge_sqlite", "db_prefix", "db_postfix", "indir", "query_string", "sqlitefile")
    """
    @info "Starting merge_sqlite"
    
    db_prefix     = cmd_message[2]
    db_postfix    = cmd_message[3]
    indir         = cmd_message[4]
    query         = cmd_message[5]
    sqlfile       = cmd_message[6]

    parameters = split_query_to_parameters(query)
    
    db_files = find_db_files(db_prefix, db_postfix, indir)
   
    merge_sqlite_files(db_files, parameters, query, sqlfile)
  
    @info "Finished"
end

function split_query_to_parameters(query::String)
    splitted_query = Base.split(query," ")
    parameters = String.(Base.split(splitted_query[2],",")) # Convert substring to array of strings

    if parameters[1] == "*"
        parameters = [k for (k,v) in all_parameters]
    end    
    return parameters
end


function find_db_files(db_prefix::String, db_postfix::String, indir::String)

    files = readdir(indir, join=false)
    db_files = [indir*x for x in files if (startswith(x, db_prefix) && endswith(x, db_postfix))]

    return db_files
end


function merge_sqlite_files(db_files::Array, parameters::Array, query::String, sqlfile::String)

    db_target = SQLite.DB(sqlfile)
    make_target_table(db_target, parameters)

    get_and_put_data(db_files, parameters, query, db_target)

    return
end


function get_and_put_data(db_files::Array, parameters::Array, query::String, db_target::SQLite.DB)
    
    println(query)
    for f in db_files
        db_source = SQLite.DB(f)

        # TODO: If query returns too much data, StackOverflowError occurs. Instead one can possibly iterate over parameters 
        # or limit the query. Until then: 
        try
            data = SQLite.DBInterface.execute(db_source, query) |> DataFrames.DataFrame
        catch e
            if isa(e, StackOverflowError)
                @warn "LoadError: StackOverflowError. Try to reduce the data size returned by the query"
            end
        end


    end
end


function make_target_table(db::SQLite.DB, parameters::Array)
    """Makes the SQL Table if it does not exist"""

        id_present   = false
        time_present = false

        create_table_string = "CREATE TABLE IF NOT EXISTS vfld ("

        for par in parameters
            if par == "ID"
                parstring = "ID INT DEFAULT NULL, "
                id_present = true
            elseif par == "TIME"
                parstring = "TIME INT DEFAULT NULL, "
                time_present = true
            else
                parstring = String(par) * " REAL DEFAULT NULL, "
            end
            create_table_string = create_table_string * parstring
        end
 
        if id_present && time_present
            create_table_string = create_table_string * "PRIMARY KEY (ID, TIME));"
        elseif id_present
            create_table_string = create_table_string * "PRIMARY KEY (ID));"
        elseif time_present
            create_table_string = create_table_string * "PRIMARY KEY (TIME));"
        else
            create_table_string = create_table_string[1:length(create_table_string)-2] * ");"
        end

        SQLite.execute(db, create_table_string)
end


function inject_data(db::SQLite.DB, dataTable)
    """Inject data into SQLite Table"""
   try
       SQLite.load!(dataTable, db, "vfld")
   catch e
       if isa(e, LoadError)
         println("SQLite.SQLiteException, no such savepoint: Error caught but possibly data loss") 
       end
   end
end

end