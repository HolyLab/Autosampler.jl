module Autosampler

using CSV, DataFrames
using Random

export stim_randomize, update_imagine

"""
    stim_randomize(filein, trials::Int, fileout=insertfilename(filein, "_sequence"))

Generate a randomize sequence of stimuli. `filein` is a string containing the name
of a CSV file that describes the unique stimuli (see format described in the README).
`trials` specifies the number of pseudo-random sequences used to generate the
final stimulus sequence.
`fileout` is an optional argument used to control the name of the output file;
the default is to insert "_sequence" right before the extension of `filein`.
"""
function stim_randomize(filein::AbstractString, trials::Int; fileout=insertfilename(filein, "_sequence"), kwargs...)
    open(fileout, "w") do io
        stim_randomize(io, filein, trials; kwargs...)
    end
    return fileout
end

function stim_randomize(io::IO, filein::AbstractString, trials::Int; writeheader=false, kwargs...)
    df = CSV.File(filein) |> DataFrame!
    println("Headers found: ", String.(names(df)))
    n = size(df, 1)
    println(n, " stimuli found")
    p = Int[]
    for i = 1:trials
        append!(p, randperm(n))
    end
    CSV.write(io, df[p, :]; writeheader=writeheader, kwargs...)
    flush(io)
end

function update_imagine()
end

function insertfilename(filename, tail)
    basename, ext = splitext(filename)
    return basename*tail*ext
end

end # module
