using Autosampler, ImagineFormat, CSV, DataFrames
using Test, Random

if !isfile("recording.ai")
    include("create_ai.jl")
end

@testset "Autosampler.jl" begin
    rows = ["chemical1_10uM,RA1", "chemical1_01uM,RA2"]
    rowid = [split(row, ',')[1] for row in rows]
    # The sequence of random numbers might change across Julia versions,
    # so determine what the sequence is
    Random.seed!(1234321)
    p = vcat(randperm(2), randperm(2), randperm(2), randperm(2))
    for stimfile in ("stimuli_tabs.csv", "stimuli_comma_quotes.csv")
        Random.seed!(1234321)
        mktemp() do pathcsv, iocsv
            # Generate sequence file
            stim_randomize(iocsv, stimfile, 4)
            str = readlines(pathcsv)
            @test str == rows[p]
            # Test insertion into .imagine file
            pathi, io = mktemp()
            close(io)
            update_imagine("recording.imagine", pathcsv; updatedfile=pathi, um_per_pixel=0.33)
            header = ImagineFormat.parse_header(pathi)
            @test split(header["stimulus sequence"], '\$') == rowid[p]
            @test header["stimulus pulses"] == 1000:1000:8000
            @test length(header["stimulus frame"]) == 8
            rm(pathi)
        end
    end
end
