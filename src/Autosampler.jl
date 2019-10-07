module Autosampler

using CSV, DataFrames, ImagineFormat, ImagineInterface
using Random, Mmap

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
    # $ is a disallowed character since we will use it as a separator
    for i = 1:n
        occursin('\$', df[i,1]) && error("\$ is disallowed in stimulus names")
    end
    p = Int[]
    for i = 1:trials
        append!(p, randperm(n))
    end
    CSV.write(io, df[p, :]; writeheader=writeheader, kwargs...)
    flush(io)
end

function update_imagine(imaginefile, sequencefile; um_per_pixel=nothing, aifile=replaceext(imaginefile, ".ai"), updatedfile=imaginefile, csvheader=0, kwargs...)
    function pulsestarts(ai, chan_name)
        sig = ai[findfirst(sig->sig.chan_name == chan_name, ai)]
        starts = find_pulse_starts(sig; sampmap=:volts)
    end

    header = ImagineFormat.parse_header(imaginefile)
    haskey(header, "stimulus sequence") && error(imaginefile, " already has a `stimulus sequence` entry")
    if um_per_pixel === nothing
        um_per_pixel = header["um per pixel"]
    end
    um_per_pixel < 0 && error("must specify um_per_pixel")
    header["um per pixel"] = um_per_pixel

    df = CSV.File(sequencefile; header=csvheader, kwargs...) |> DataFrame!
    n = size(df, 1)

    # Scan the AI file for stimulus triggers
    ai = parse_ai(aifile, header)
    stimstarts  = pulsestarts(ai, "stimuli")
    framestarts = pulsestarts(ai, "camera frame TTL")

    # Record as frameidx after the stimulus trigger
    fps = header["frames per stack"]
    frameidx = Int[]
    for i in stimstarts
        idx = last(searchsorted(framestarts, i))
        push!(frameidx, idx)
    end

    # Add to header
    header["stimulus sequence"] = join(df[:,1], '\$')
    header["stimulus pulses"] = stimstarts
    header["stimulus frame"] = frameidx

    if updatedfile == imaginefile
        mv(imaginefile, imaginefile*".orig")
        sleep(0.25)
        isfile(imaginefile) && error("failed to move the old file")
    end
    ImagineFormat.save_header(updatedfile, header; misc=("stimulus sequence", "stimulus pulses", "stimulus frame"))
    return header
end

function insertfilename(filename, tail)
    basename, ext = splitext(filename)
    return basename*tail*ext
end

function replaceext(filename, ext)
    basename, _ = splitext(filename)
    return basename*ext
end

end # module
