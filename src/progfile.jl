# These parameters were chosen from .pgm files used by former Holy lab members
# Most parameters were kept the same between users, with the exception of the flowrate "Flow" and wait time "Delay"
# Some of these parameters may be extraneous when using "InjectMode = UserProg".
const default_params = Dict{String,String}(
    "Flow"                  => "0.540",     # mL/min
    "Delay"                 => "0.500",     # min

    "PreflushVolume"        => "5.0",       # μL

    "TempCtrl"              => "On",
    "TemperatureNominal"    => "30.0",      # [°C]
    "TemperatureLowerLimit" => "27.0",      # [°C]
    "TemperatureUpperLimit" => "33.0",      # [°C]
	"ReadyTempDelta"        => "2.0",       # [°C]
	"PressureLowerLimit"    => "0",         # [bar]
	"PressureUpperLimit"    => "350",       # [bar]
	"MaximumFlowRampDown"   => "6.000",     # [ml/min²]
	"MaximumFlowRampUp"     => "6.000",     # [ml/min²]
	"%A.Equate"             => "%A",
	"DrawSpeed"             => "10.000",    # [µl/s]
	"DrawDelay"             => "1000",      # [ms]
	"DispSpeed"             => "20.000",    # [µl/s]
	"DispenseDelay"         => "0",
	"WasteSpeed"            => "20.000",    # [µl/s]
	"SampleHeight"          => "2.000",     # [mm]
	"InjectWash"            => "AfterDraw",
	"WashVolume"            => "100.000",   # [µl]
	"WashSpeed"             => "30.000",    # [µl/s]
	"LoopWashFactor"        => "1.000",
	"PunctureOffset"        => "0.0",       # [mm]
	"PumpDevice"            => "\"Pump\"",
	"SyncWithPump"          => "Off",
	"Pump_Pressure.Step"    => "0.01",      # [s]
	"Pump_Pressure.Average" => "Off",
	"Curve"                 => "5",
)

"""
    chromeleon_program(fileout::AbstractString, params::Dict{String,String}=default_params)

Generate a Chromeleon program file (.pgm) to be used for timing injections performed by the autosampler
with an external TTL input (e.g. one from Imagine). 
`fileout` is a string containing the name of the program file to be written.
`params` specifies the parameters to be used in the program file. Default settings based on settings used 
by current and former Holy lab members are provided in `default_params`.
For typical use, only the flowrate `params["Flow"]` and wait time `params["Delay"]` need to be changed between experiments.
"""
function chromeleon_program(fileout::AbstractString, params::Dict{String,String}=default_params)
    split(fileout, ".")[end] == "pgm" || error("fileout must have .pgm extension")
    open(fileout, "w") do io
        chromeleon_program(io, params)
    end
    return fileout
end

function chromeleon_program(io::IO, params=default_params)
    write(io, 
        "\tTempCtrl =\t$(params["TempCtrl"])\n",
        "\tTemperature.Nominal =\t$(params["TemperatureNominal"]) [°C]\n",
        "\tTemperature.LowerLimit =\t$(params["TemperatureLowerLimit"]) [°C]\n",
        "\tTemperature.UpperLimit =\t$(params["TemperatureUpperLimit"]) [°C]\n",
        "\tReadyTempDelta =\t$(params["ReadyTempDelta"]) [°C]\n",
        "\tPressure.LowerLimit =\t$(params["PressureLowerLimit"]) [bar]\n",
        "\tPressure.UpperLimit =\t$(params["PressureUpperLimit"]) [bar]\n",
        "\tMaximumFlowRampDown =\t$(params["MaximumFlowRampDown"]) [ml/min²]\n",
        "\tMaximumFlowRampUp =\t$(params["MaximumFlowRampUp"]) [ml/min²]\n",
        "\t%A.Equate =\t$(params["%A.Equate"])\n",
        "\tDrawSpeed =\t$(params["DrawSpeed"]) [µl/s]\n",
        "\tDrawDelay =\t$(params["DrawDelay"]) [ms]\n",
        "\tDispSpeed =\t$(params["DispSpeed"]) [µl/s]\n",
        "\tDispenseDelay =\t$(params["DispenseDelay"]) [ms]\n",
        "\tWasteSpeed =\t$(params["WasteSpeed"]) [µl/s]\n",
        "\tSampleHeight =\t$(params["SampleHeight"]) [mm]\n",
        "\tInjectWash =\t$(params["InjectWash"])\n",
        "\tWashVolume =\t$(params["WashVolume"]) [µl]\n",
        "\tWashSpeed =\t$(params["WashSpeed"]) [µl/s]\n",
        "\tLoopWashFactor =\t$(params["LoopWashFactor"])\n",
        "\tPunctureOffset =\t$(params["PunctureOffset"]) [mm]\n",
        "\tPumpDevice =\t$(params["PumpDevice"])\n",
        "\tSyncWithPump =\t$(params["SyncWithPump"])\n",
        "\tPump_Pressure.Step =\t$(params["Pump_Pressure.Step"]) [s]\n",
        "\tPump_Pressure.Average =\t$(params["Pump_Pressure.Average"])\n",
        "\tCurve =\t$(params["Curve"])\n\n",

        "\tFlow =\t$(params["Flow"]) [ml/min]\n\n",

        "\t; Wait for the Ready signals from the pump and autsosampler\n",
        " 0.000\tWait\tPump.Ready and Sampler.Ready and PumpModule.Ready\n\n",

        "\tInjectMode =\tUserProg\n\n",

        "\t; Wait for the stimulus input to have a Low signal, to prevent trigger of two injections from a single signal\n",
        "\tUdpWaitInput\tInput=Inp1, State=Low\n\n",

        "\t; Preflush the injection needle\n",
        "\tUdpInjectValve\tPosition=Inject\n",
        "\tUdpSyringeValve\tPosition=Needle\n",
        "\tUdpDraw\tFrom=SampleVial, Volume=$(params["PreflushVolume"]), SyringeSpeed=GlobalSpeed, SampleHeight=Globalheight\n",
        "\tUdpMixWait\tDuration=$(parse(Float64, params["DrawDelay"])/1000) ; Pause to avoid air intake from aspirating the sample too quickly\n\n",

        "\t; Fill the Sample Loop with the plate position and volume specified by the sequence file\n",
        "\tUdpInjectValve\tPosition=Load\n",
        "\tUdpDraw\tFrom=SampleVial, Volume=Volume, SyringeSpeed=GlobalSpeed, SampleHeight=Globalheight\n",
        "\tUdpMixWait\tDuration=$(parse(Float64, params["DrawDelay"])/1000) ; Pause to avoid air intake from aspirating the sample too quickly\n\n",

        "\t; Wait for the signal from Image before performing the injection\n",
        "\tUdpWaitInput\tInput=Inp1, State=High\n\n",

        "\t; Inject the sample and signal to Chromeleon that the injection has been performed\n",
        "\tUdpInjectValve\tPosition=Inject\n",
        "\tUdpInjectMarker\n\n",

        "\t; Send timestamp signal to imagine\n",
        "\tRelay_4.State\tOn\n\n",

        "\t; Start recording the pump pressure (not used for optical records, but I'm not sure if it is safe to omit this step)\n",
        "\tPump_Pressure.AcqOn\n\n",

        "\t; Wash the needle\n",
        "\tUdpSyringeValve\tPosition=Waste\n",
        "\tUdpMoveSyringeHome\tSyringeSpeed=GlobalSpeed\n",
        "\tUdpMixNeedleWash\tVolume=$(params["WashVolume"])\n\n",

        " $(params["Delay"])\tPump_Pressure.AcqOff ; Stop pressure acquisition\n",
        "\t; Note the time of the above command (in minutes).\n",
        "\t; This time interval may be important for fully emptying/washing the Sample Loop.\n",
        "\t; If set too long, it might also cause Chromeleon to \"miss\" a signal from Imagine.\n\n",

        "\t; Check your flowrate for the pump (\"Flow\" above), sample volume in your sequence file,\n", 
        "\t; and inter-trial delay for your Imagine waveforms to avoid issues.\n\n",

        "\t; Turn off Relay 4\n",
        "\tRelay_4.State\tOff\n\n",

        "\tEnd\n",
    )
    flush(io)
end

