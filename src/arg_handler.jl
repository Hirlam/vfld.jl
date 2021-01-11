module arg_handler
 
const doc = """This is the Julia vfld program
I can help you with:
Convert VFLD to SQLite (cmd: vfld_to_sqlite)
Rename files from date+leadtime to date only (cmd: date_naming)

date_naming: Before use, please ensure if you want to distunguish between analysis and forecasts. If you want that, then date_naming is not for you.

Usage:
  vfld.jl [vfld_to_sqlite] [date_naming] [options]
  vfld.jl -h | --help

Options:
  -h --help                     Show this screen.
  --starttime=<YYYY-MM-DD-HH>   start time.
  --endtime=<YYYY-MM-DD-HH>     end time.
  --file-prefix=<str>           Prefix of vfld files (eg. "vfldER5") [default: "vfld"]
  --file-postfix=<str>          Postfix of vfld files (eg. "01") [default: ""]
  --indir=<str>                 Input directory [default: ~/].

vfld_to_sqlite:
  --sqlite-file=<str>           Output to files [default: ~/out.db]

date_naming:
  --max-leadtime=<int>          Only use up x hours leadtime (eg. 2020-01-01-00+03 will be 2020-01-01-03, only if --max-leadtime is above 2) [default: 2]
  --leadtime-characters=<int>   How many of the last digits is the leadtime info? [default: 2]
  --outdir=<str>                Which directory to write renamed files to [default: .]

Development shortcuts:
    julia --project=~/git/vfld/ vfld_util.jl vfld_to_sqlite --starttime=2013-10-01-00 --endtime=2013-10-02-00 --file-prefix=vfld --sqlite-file=/home/kah/git/vfld/scr/test.db --indir=/home/kah/tmp/vfld/ERA5/
    julia --project=~/git/vfld/ vfld_util.jl date_naming --starttime=2013-10-01-00 --endtime=2020-11-01-00 --file-prefix=vfldDKREA --leadtime-characters=2 --max-leadtime=2 --indir=/home/kah/tmp/vfld/DKREA/201310/ --outdir=/home/kah/tmp/vfld/DKREA_RENAMED/

Notes:
    Assumes the naming of vfld files follows a structure like so:
    vfldER5201310312300 (must end with 10 or 12 date characters)
    
    It is recommended not to cover more than one month with "vfld_to_sqlite" command.
"""

const avail_commands = ["vfld_to_sqlite", "date_naming"]


function main_args(args)
    help_msg(args)
    cmds = make_dict(args)
    cmd_message = command_msg(cmds)
    return cmd_message
end


function help_msg(args)
    """Checks if just the doc string should be printed"""
    if "-h" in args || "--help" in args
        print(doc)
        exit(0)
    end
end


function make_dict(args)
    """Makes a dictionary of input arguments"""
    cmds = Dict()

    for k in args
        if startswith(k,"--")       # Identifier for an option
            opt = split(k,"=")
            cmds[opt[1]] = opt[2]
        elseif startswith(k,"-")    # Identifier for a flag 
            cmds[k] = "flag"
        else                        # Identifier for a command
            cmds[k] = "command" 
        end
    end
    return cmds
end


function command_msg(cmds)
    """Checks which command we are supposed to run"""

    for cmd in avail_commands

        # command: vfld_to_sqlite
        if cmd == "vfld_to_sqlite" && haskey(cmds,cmd) # Determine which command to run
            cmd_message = check_options(cmds,cmd)
            return cmd_message # We only allow one command at a time for now
        elseif cmd == "date_naming" && haskey(cmds,cmd)
            cmd_message = check_options(cmds,cmd)
            return cmd_message
        end

    end  
end


function check_options(cmds, cmd)
     """Further check for necessary options for this specific command"""
    if cmd == "vfld_to_sqlite"
       
        starttime = key_check("--starttime", cmds)
        endtime = key_check("--endtime", cmds)

        if starttime === missing || endtime === missing
            raise_missing_option("--starttime and --endtime")
        end

        file_prefix = key_check("--file-prefix", cmds)
        file_prefix===missing ? file_prefix = "vfld" : nothing

        file_postfix = key_check("--file-postfix", cmds)
        file_postfix===missing ? file_postfix = "" : nothing

        indir = key_check("--indir", cmds)
        indir===missing ? indir = "~/" : nothing

        sqlitefile = key_check("--sqlite-file", cmds)
        sqlitefile===missing ? sqlitefile = "~/out.db" : nothing
  
        cmd_message = String.((cmd, starttime, endtime, file_prefix, file_postfix, indir, sqlitefile))

        return cmd_message
    elseif  cmd == "date_naming"

        starttime = key_check("--starttime", cmds)
        starttime===missing ? starttime = "1970-01-01-00" : nothing

        endtime = key_check("--endtime", cmds)
        endtime===missing ? endtime = "2100-01-01-00" : nothing

        file_prefix = key_check("--file-prefix", cmds)
        file_prefix===missing ? file_prefix = "vfld" : nothing

        file_postfix = key_check("--file-postfix", cmds)
        file_postfix===missing ? file_postfix = "" : nothing

        indir = key_check("--indir", cmds)
        indir===missing ? indir = "~/" : nothing

        maxleadtime = key_check("--max-leadtime", cmds)
        maxleadtime===missing ? maxleadtime = 2 : nothing

        leadtimechars = key_check("--leadtime-characters", cmds)
        leadtimechars===missing ? leadtimechars = 2 : nothing

        outputdir = key_check("--outdir", cmds)
        outputdir===missing ? outputdir = "." : nothing

        cmd_message = String.((cmd, starttime, endtime, file_prefix, file_postfix, indir, maxleadtime, leadtimechars, outputdir))

        return cmd_message
    end

end


function key_check(key,dict)
    """Checks if a key exist in a dict and if so, return the value"""
    if haskey(dict,key)
        value = dict[key]
        return value
    else
        return missing
    end
end


function raise_missing_option(option)
    println(option*" necessary for this command")
    exit(0)
end


end