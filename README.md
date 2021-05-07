![Test Build](https://github.com/khintz/vfld.jl/actions/workflows/TestBuild.yml/badge.svg)
[![codecov](https://codecov.io/gh/khintz/vfld.jl/branch/main/graph/badge.svg?token=MBQFPOXAQ4)](https://codecov.io/gh/khintz/vfld.jl)

# vfld.jl
This is a small utility program for working with vfld files written in Julia. It is work in progress and more commands and options may come along the way. The list below is updated whenever new commands are available.

# How?
You can set this package up from the Julia REPL with the `add` command and the url of this repository:
```
julia> ]
pkg> add https://github.com/khintz/vfld.jl
```
Which will make it possible to import the modules into your own scripts. 

If you rather just use the program as a CLI, I recommend to clone and build it like so:
```
git clone https://github.com/khintz/vfld.jl
```
and instantiate from the Julia REPL:
```
pkg> instantiate
```

The main script to run is `vfld_util.jl` within the `scr/` directory. \
The Julia source code is found within `src/`

From within the `scr/` directory you can do:\
`julia --project=$PWD/.. vfld_util.jl --help` \
to get a help message

# What can vfld.jl do?
- **Convert vfld files into a single SQLite file, eg:**\
`julia --project=$PWD/.. vfld_util.jl vfld_to_sqlite --starttime=2013-10-01-00 --endtime=2013-10-02-00 --file-prefix=vfld --indir=/data/vfld/ --sqlite-file=vfld_20131001.db`

This will search for all files within `/data/vfld/` which starts with `vfld` and is valid between `starttime` and `endtime`.

***NOTE***: It is assumed the vfld files end with a date string with 12 characters as usual, eg: *vfldyyyymmddHHMM*, otherwise the date can not be obtained and it will fail.

***NOTE***: When running vfld.jl the first time every module gets compiled, which takes a few seconds extra. This is only the first time it runs.
