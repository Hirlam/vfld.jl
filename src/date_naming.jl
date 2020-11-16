module date_naming

import Base
import Dates

function rename(cmd_message)
    @info "Starting date_naming"
    starttime     = convert_string_to_datetime(cmd_message[2])
    endtime       = convert_string_to_datetime(cmd_message[3])
    file_prefix   = cmd_message[4]
    indir         = cmd_message[5]
    leadtimechars = parse(Int, cmd_message[6])
    maxleadtime   = parse(Int, cmd_message[7])
    outputdir     = cmd_message[8]

    make_output_dir(outputdir)

    rename_vfld_files(file_prefix, indir, starttime, endtime, leadtimechars, maxleadtime, outputdir)

    @info "Finished"
end


function convert_string_to_datetime(time)
    df = Dates.DateFormat("y-m-d-H")
    return Dates.DateTime(time, df)
end


function make_output_dir(dir::String)
    Base.mkpath(dir)
end


function rename_vfld_files(file_prefix::String, indir::String, starttime::Dates.DateTime, endtime::Dates.DateTime, 
                         leadtimechars::Integer, maxleadtime::Integer, outdir::String)

    files = readdir(indir, join=false)
    vfld_files = [x for x in files if startswith(x, file_prefix)]
    vfld_files_within_range = []

    for f in vfld_files
        datestring = f[lastindex(f)-11:lastindex(f)-leadtimechars]
        leadtime = parse(Int, f[lastindex(f)-leadtimechars+1:lastindex(f)])
        dl = Dates.DateTime(datestring, "yyyymmddHH")
        if dl >= starttime && dl<endtime && leadtime <= maxleadtime
           dl_new = dl + Dates.Hour(leadtime)
           ff_new = file_prefix * Dates.format(dl_new, "yyyymmddHH")  
           Base.cp(indir*f, outdir*ff_new)
        end
    end
end

end