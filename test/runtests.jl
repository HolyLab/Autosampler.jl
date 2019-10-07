using Autosampler, ImagineFormat, CSV, DataFrames
using Test, Random

@testset "Autosampler.jl" begin
    for stimfile in ("stimuli_tabs.csv", "stimuli_comma_quotes.csv")
        Random.seed!(1234321)
        mktemp() do pathcsv, iocsv
            stim_randomize(iocsv, stimfile, 4)
            str = read(pathcsv, String)
            @test str == """
            chemical1_10uM,RA1
            chemical1_01uM,RA2
            chemical1_10uM,RA1
            chemical1_01uM,RA2
            chemical1_01uM,RA2
            chemical1_10uM,RA1
            chemical1_10uM,RA1
            chemical1_01uM,RA2
            """
            # mktemp() do pathi, ioi
            #     update_imagine(ioi, "recording.imagine", pathcsv; pixelspacing=[0.3, 0.3, 5.2])
            #     header = ImagineFormat.parse_header(pathi)
            #     # @test header["stimulus"]
            # end
        end
    end
end
