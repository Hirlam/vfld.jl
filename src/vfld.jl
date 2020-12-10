module vfld

using Base
import Dates
import DataFrames
import SQLite

include("arg_handler.jl")
include("vfld_to_sqlite.jl")
include("date_naming.jl")

import .arg_handler
import .vfld_to_sqlite
import .date_naming


function __init__()
   
end


function main(args)
    cmd_message = arg_handler.main_args(args)
    cmd_message[1]==="vfld_to_sqlite" ? vfld_to_sqlite.make_sqlite(cmd_message) : nothing
    cmd_message[1]==="date_naming" ? date_naming.rename(cmd_message) : nothing
end


end
