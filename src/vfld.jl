module logsout
    function write_log(args,logout)
        if args["--logfile"] !== nothing
            logfile = args["--logfile"]
            write(logout, logfile)
        end
    end
end



module vfld

doc = """vfld

Usage:
  vfld.jl [vfld_to_sqlite] [options]
  vfld.jl -h | --help
  vfld.jl --version

Options:
  -h --help                     Show this screen.
  --version                     Show version.
  -q, --quiet                   Print no info.
  -v, --verbose                 Print info.
  -d, --debug                   Print detailed info.
  --logfile <FILE>              Write full log to file
  --starttime <YYYY-MM-DD-HH>   start time (Required for vfld_to_sqlite).
  --endtime <YYYY-MM-DD-HH>     end time (Required for vfld_to_sqlite).
  --file-prefix <str>           Prefix of vfld files (eg. "vfldER5") [default: vfld]
  --indir <str>                 Input directory [default: ~/].
  --outdir <str>                Output directory [default: ~/].
  --sqlite-file <str>           Output to files [default: ~/out.db]


Development shortcuts:
    julia --project=~/git/vfld/ --color=yes vfld.jl vfld_to_sqlite

Notes:
    Assumes the naming of vfld files follows a structure like so:
    vfldER5201310312300 (must end with 12 date characters)
    
    It is recommended not to cover more than one month with "vfld_to_sqlite" command.
"""

# 'using' imports everything, while 'import' needs explicit declaration.
# this using * is similarly to "from package import *" in python

include("vfld_to_sqlite.jl")

import Base 
import Logging
import Dates
using DocOpt

import ..logsout
import .vfld_to_sqlite




    args = docopt(doc, version=v"2.0.0")


    if args["--debug"] || args["--verbose"]
        loglevel = Logging.Debug
    else
        loglevel = Logging.Info
    end

    if args["--logfile"] === nothing
        logout = stdout
    else
        logout = open(args["--logfile"], read=true, write=true, create=true)
    end

    if args["--quiet"]
        loggerDebug = Logging.NullLogger()
        old_logger = Logging.global_logger(loggerDebug)
    else
        loggerDebug = Logging.ConsoleLogger(logout, loglevel)
        old_logger = Logging.global_logger(loggerDebug)
    end

    

    if args["vfld_to_sqlite"]

        Logging.@info("starting makeSQLite")
        #Logging.@debug("want this")

        if (args["--indir"] === nothing)
            #printstyled("--indir not set: EXITING\n", color=:red)
            Logging.@error("--indir not set")
            logsout.write_log(args, logout)
            Base.exit(0)
        end

        if args["--starttime"] === nothing
            Logging.@info("--starttime not set, setting to year 1900")
            starttime = Dates.DateTime(1900)
        else
            df = Dates.DateFormat("y-m-d-H")
            starttime = Dates.DateTime(args["--starttime"], df)
            Logging.@debug(starttime)
        end

        if args["--endtime"] === nothing
            Logging.@info("--endtime not set, setting to year 2100")
            endtime = Dates.DateTime(2100)
        else
            df = Dates.DateFormat("y-m-d-H")
            endtime = Dates.DateTime(args["--endtime"], df)
            Logging.@debug(endtime)
        end


        files = readdir(args["--indir"], join=false)
        vfld_files = [x for x in files if startswith(x,args["--file-prefix"])]


        vfld_files_within_range = []
        for f in vfld_files
            dl = Dates.DateTime(f[length(f)-11:length(f)],"yyyymmddHHMM")
            
            if dl >= starttime && dl<endtime
                append!(vfld_files_within_range, [args["--indir"]*f])
            end
        end

        nofiles = length(vfld_files_within_range)

        Logging.@info("Found " * string(nofiles) * " files")
        # Now we have all the files we want to convert to a SQLite file.
        vfld_to_sqlite.make_sqlite(vfld_files_within_range, args["--sqlite-file"], Logging)
        
    end

end


