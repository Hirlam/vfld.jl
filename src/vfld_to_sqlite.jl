module vfld_to_sqlite

import Base
import SQLite
import Tables
import DataFrames
import Dates
import Logging

    parameters = Base.Dict([("ID", "ID"),
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
                    ("GX", "WindSpeed_Maxima1H"),
                    ("TIME", "Time")])


    function make_sqlite(files, sqlfile, Logging)

        target_column_names = [k for (k,v) in parameters]
 
        db = SQLite.DB(sqlfile)
        make_missing_table(db)

        for f in files
            # First line are dimensions
            # Second line is header info (how many header lines that are present)

            i = 1
            parameter_count = 1
            processed_header = false
            record = 1
            
            Logging.@debug("Processing file ",f)

            for l in eachline(f)
                if i == 1
                    global no_records = parse(Int,Base.split(l)[1]) #SubString
                elseif i == 2
                    global header_lines = parse(Int,Base.split(l)[1])
                    global column_names = ["" for k in 1:header_lines]
                elseif i > 2 && i <= header_lines::Int+2 #Parameters in file
                    column_parameter = Base.split(l)[1]
                    column_names[parameter_count] = column_parameter
                    parameter_count+=1
                elseif i > header_lines::Int+2 && i <= no_records::Int+header_lines::Int+2
                    #Adding header_lines::Int+2 to simulate resetting counter i
                    if !processed_header
                        global column_names = append!(["ID", "LAT", "LON"], column_names)
                        no_columns = length(column_names)
                        processed_header = true
                        global data = zeros(Float32, no_records, no_columns)
                    end

                    dataline = parse.(Float32, Base.split(l))
                    
                    data[record,:] = dataline

                    record+=1
                end

                i+=1
            end

        
            # diff_cols_bool = in(column_names).(target_column_names)
            # diff_cols = [target_column_names[k] for k in 1:length(target_column_names) if !diff_cols_bool[k] && target_column_names[k] != "TIME"]

            df = DataFrames.DataFrame(Base.zeros(Float32, no_records, length(target_column_names)))

            DataFrames.rename!(df, target_column_names)


            df = get_and_put_time(f, df)
            df = set_and_reorder_columns(df, column_names)

            inject_data(db, df)

        end

        Logging.@info("Created SQLite database")
        
    end


    function get_and_put_time(f, df)
        """Inserting the Time into DataFrame"""
        current_time = Dates.DateTime(f[length(f)-11:length(f)],"yyyymmddHHMM")
        current_time = Int(Dates.datetime2unix(current_time))
        df["TIME"] = current_time
        return df
    end


    function set_and_reorder_columns(df, column_names)
        """Sets data is present columns and reorder to match SQL table"""
        k_itr = 1
        for k in column_names
            df[k] = data[:,k_itr]
            k_itr+=1
        end

        # Reordering columns
        # Order of columns gets important when inserted into sql table
        DataFrames.select!(df,[:ID, :TIME, :LAT, :LON, :FI, :NN, :DD, :FF, :GG, :TT, :RH, :PS, :PSS, :PE, :PE1, :PE3, :PE6, :PE24, :QQ, :VI, :TD, :TX, :TM, :GX])
        return df
    end


    function inject_data(db, dataTable)
        """Inject data into SQLite Table"""
       SQLite.load!(dataTable, db, "vfld")
    end


    function make_missing_table(db)
        """Makes the SQL Table if it does not exist"""

        sqliteCreateTable   = """CREATE TABLE IF NOT EXISTS vfld
                                    (ID INT DEFAULT NULL,
                                    TIME INT DEFAULT NULL,
                                    LAT REAL DEFAULT NULL,
                                    LON REAL DEFAULT NULL,
                                    FI REAL DEFAULT NULL,
                                    NN INT DEFAULT NULL,
                                    DD REAL DEFAULT NULL,
                                    FF REAL DEFAULT NULL,
                                    GG REAL DEFAULT NULL,
                                    TT REAL DEFAULT NULL,
                                    RH REAL DEFAULT NULL,
                                    PS REAL DEFAULT NULL,
                                    PSS REAL DEFAULT NULL,
                                    PE REAL DEFAULT NULL,
                                    PE1 REAL DEFAULT NULL,
                                    PE3 REAL DEFAULT NULL,
                                    PE6 REAL DEFAULT NULL,
                                    PE24 REAL DEFAULT NULL,
                                    QQ REAL DEFAULT NULL,
                                    VI REAL DEFAULT NULL,
                                    TD REAL DEFAULT NULL,
                                    TX REAL DEFAULT NULL,
                                    TM REAL DEFAULT NULL,
                                    GX REAL DEFAULT NULL,
                                    PRIMARY KEY (ID, TIME));"""

        SQLite.execute(db, sqliteCreateTable) 
    end


end