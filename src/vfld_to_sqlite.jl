module vfld_to_sqlite

import Base
import SQLite
import DataFrames
import Dates

    const parameters = Base.Dict([("ID", "ID"),
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


    function make_sqlite(cmd_message)
        """Converts VFLD files to a single SQLite file
        Assumes that the cmd_message comes in the following format:
        ("vfld_to_sqlite", "<starttime>", "<endtime>", "<file-prefix>", "<indir>", "<sqlfile>")
        """
        @info "Starting make_sqlite"
        starttime   = convert_string_to_datetime(cmd_message[2])
        endtime     = convert_string_to_datetime(cmd_message[3])
        file_prefix = cmd_message[4]
        file_postfix= cmd_message[5]
        indir       = cmd_message[6]
        sqlfile     = cmd_message[7]

        vfld_files = find_vfld_files(file_prefix, file_postfix, indir, starttime, endtime)

        vfld2sqlite(vfld_files, sqlfile)
      
        @info "Finished"
    end


    function convert_string_to_datetime(time)
        df = Dates.DateFormat("y-m-d-H")
        return Dates.DateTime(time, df)
    end


    function find_vfld_files(file_prefix::String, file_postfix::String, indir::String, starttime::Dates.DateTime, endtime::Dates.DateTime)

        files = readdir(indir, join=false)
        vfld_files = [x for x in files if (startswith(x, file_prefix) && endswith(x, file_postfix))]
        
        vfld_files_within_range = []
        for f in vfld_files

            try
                dl = Dates.DateTime(f[length(f)-11:length(f)],"yyyymmddHHMM")
                if dl >= starttime && dl<endtime
                    append!(vfld_files_within_range, [indir*f])
                end
            catch e
                dl = Dates.DateTime(f[length(f)-9:length(f)],"yyyymmddHH")
                if dl >= starttime && dl<endtime
                    append!(vfld_files_within_range, [indir*f])
                end
            end
            
            
        end
        return vfld_files_within_range
    end


    function vfld2sqlite(vfld_files, sqlfile::String)

        target_column_names = [k for (k,v) in parameters]

        db = SQLite.DB(sqlfile)
        make_missing_table(db)

        for f in vfld_files
            @info "Reading $f"
            i=1
            record = 1
            parameter_count = 1
            processed_header = false

            no_records = 0
            header_lines = 0
            column_names = []
            for l in eachline(f)
                if i == 1
                    no_records = parse(Int,Base.split(l)[1])
                elseif i == 2
                    header_lines = parse(Int,Base.split(l)[1])
                    column_names = ["" for k in 1:header_lines]
                elseif i > 2 && i <= header_lines::Int+2 #Parameters in file
                    column_parameter = Base.split(l)[1]
                    column_names[parameter_count] = column_parameter
                    parameter_count+=1
                elseif i > header_lines::Int+2 && i <= no_records::Int+header_lines::Int+2
                    #Adding header_lines::Int+2 to simulate resetting counter i
                    if !processed_header
                        # First we need to check if "FI" is present. In VOBS FI is always there,
                        # even though it is not listed.
                        is_FI_there = is_string_present("FI", column_names)
                        if !is_FI_there
                            column_names = append!(["FI"], column_names)
                        end
                        column_names = append!(["ID", "LAT", "LON"], column_names)
                        #println(column_names)
                        no_columns = length(column_names)
                        #println(no_columns)
                        processed_header = true
                        global data = zeros(Float64, no_records, no_columns)
                    end
                    
                    try
                       dataline = parse.(Float64, Base.split(l))
                       data[record,:] = dataline
                    catch e
                       println("ERROR: Could not convert string to Float64, skipping this line")
                    end

                    record+=1

                end
                i+=1
            end

            df = DataFrames.DataFrame(Base.zeros(Float64, no_records, length(target_column_names)))

            DataFrames.rename!(df, target_column_names)

            df = get_and_put_time(f, df)
            df = set_and_reorder_columns(df, column_names)

            inject_data(db, df)
            
        end

    end


    function is_string_present(str, str_array)
        b = filter(x->occursin(str,x), str_array)
        if length(b) == 0
            return false
        elseif length(b) > 0
            return true
        end
    end


    function get_and_put_time(f, df)
        """Inserting the Time into DataFrame"""

       # println(f[length(f)-11:length(f)])

        try
            current_time = Dates.DateTime(f[length(f)-11:length(f)],"yyyymmddHHMM")
        catch e
            current_time = Dates.DateTime(f[length(f)-9:length(f)],"yyyymmddHH")
        end
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
        DataFrames.select!(df,[:ID, :TIME, :LAT, :LON, :FI, :NN, :DD, :FF, :GG, :TT, :RH, :PS, :PSS, :PE, :PE1, :PE3, :PE6, :PE24, :QQ, :VI, :TD, :TX, :TM, :GM, :GX, :WX, :GW])
        return df
    end


    function inject_data(db, dataTable)
        """Inject data into SQLite Table"""
       try
           SQLite.load!(dataTable, db, "vfld")
       catch e
           if isa(e, LoadError)
             println("SQLite.SQLiteException, no such savepoint: Error caught but possibly data loss") 
           end
       end
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
                                    GM REAL DEFAULT NULL,
                                    GX REAL DEFAULT NULL,
                                    WX REAL DEFAULT NULL,
                                    GW REAL DEFAULT NULL,
                                    PRIMARY KEY (ID, TIME));"""

        SQLite.execute(db, sqliteCreateTable) 
    end


end
