using ImagineFormat

header = ImagineFormat.parse_header("recording.imagine")
ailabels = split(header["label list"], '\$')
stimidx = findfirst(isequal("stimuli"), ailabels)
frameidx = findfirst(isequal("camera frame TTL"), ailabels)

function volts2i(v, header)
    threshnorm = (v - header["min input"])/(header["max input"] - header["min input"])
    0 <= threshnorm <= 1 || error(v, " is out of bounds for sample range [", header["min input"], ',', header["max input"], ']')
    return round(Int16, threshnorm*header["max sample"] + (1-threshnorm)*header["min sample"])
end

ttlhi = volts2i(5, header)
ttllo = volts2i(0, header)

function write_aifile(io, nchans, nscans, stimidx, frameidx, ttllo, ttlhi, nstim, nstacks, framesperstack)
    Δstim = nscans ÷ (nstim + 2)
    Δstack = nscans ÷ (nstacks + 3)
    Δframe = Δstack ÷ (2*framesperstack)
    stackstart, framesleft = nscans+1, 0
    for j = 1:nscans
        for i = 1:nchans
            if i == frameidx
                if framesleft == 0 && j % Δstack == 0 && nstacks > 0
                    # start a stack
                    stackstart = j
                    framesleft = framesperstack - 1
                    nstacks -= 1
                    write(io, ttlhi)
                elseif framesleft > 0 && (j - stackstart + 1) % Δframe == 0
                    write(io, ttlhi)
                    framesleft -= 1
                else
                    write(io, ttllo)
                end
            elseif i == stimidx
                if nstim > 0 && j % Δstim == 0
                    write(io, ttlhi)
                    nstim -= 1
                else
                    write(io, ttllo)
                end
            else
                write(io, ttllo)
            end
        end
    end
end

open("recording.ai", "w") do io
    write_aifile(io, length(header["channel list"]), header["nscans"], stimidx, frameidx,
                     ttllo, ttlhi, 8, header["nStacks"], header["frames per stack"])
end
