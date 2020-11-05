module arg_handler
 
const doc = """This is the Julia vfld program
I can help you with:
Convert VFLD to SQLite (cmd: vfld_to_sqlite)

Usage:
  vfld.jl [vfld_to_sqlite] [options]
  vfld.jl -h | --help

Options:
  -h --help                     Show this screen.
  --starttime=<YYYY-MM-DD-HH>   start time.
  --endtime=<YYYY-MM-DD-HH>     end time.
  --file-prefix=<str>           Prefix of vfld files (eg. "vfldER5") [default: vfld]
  --indir=<str>                 Input directory [default: ~/].
  --sqlite-file=<str>           Output to files [default: ~/out.db]


Development shortcuts:
    julia --project=~/git/vfld/ vfld_util.jl vfld_to_sqlite --starttime=2013-10-01-00 --endtime=2013-10-02-00 --file-prefix=vfld --sqlite-file=/home/kah/git/vfld/scr/test.db --indir=/home/kah/tmp/vfld/ERA5/

Notes:
    Assumes the naming of vfld files follows a structure like so:
    vfldER5201310312300 (must end with 12 date characters)
    
    It is recommended not to cover more than one month with "vfld_to_sqlite" command.
"""

const avail_commands = ["vfld_to_sqlite"]


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

        indir = key_check("--indir", cmds)
        indir===missing ? indir = "~/" : nothing

        sqlitefile = key_check("--sqlite-file", cmds)
        sqlitefile===missing ? sqlitefile = "~/out.db" : nothing
  
        cmd_message = String.((cmd, starttime, endtime, file_prefix, indir, sqlitefile))

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