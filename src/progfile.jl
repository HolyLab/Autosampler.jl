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
    # Newlines use the \r\n convention for compatibility with Windows/Notepad
    write(io, 
        "\tTempCtrl =\t$(params["TempCtrl"])\r\n",
        "\tTemperature.Nominal =\t$(params["TemperatureNominal"]) [°C]\r\n",
        "\tTemperature.LowerLimit =\t$(params["TemperatureLowerLimit"]) [°C]\r\n",
        "\tTemperature.UpperLimit =\t$(params["TemperatureUpperLimit"]) [°C]\r\n",
        "\tReadyTempDelta =\t$(params["ReadyTempDelta"]) [°C]\r\n",
        "\tPressure.LowerLimit =\t$(params["PressureLowerLimit"]) [bar]\r\n",
        "\tPressure.UpperLimit =\t$(params["PressureUpperLimit"]) [bar]\r\n",
        "\tMaximumFlowRampDown =\t$(params["MaximumFlowRampDown"]) [ml/min²]\r\n",
        "\tMaximumFlowRampUp =\t$(params["MaximumFlowRampUp"]) [ml/min²]\r\n",
        "\t%A.Equate =\t$(params["%A.Equate"])\r\n",
        "\tDrawSpeed =\t$(params["DrawSpeed"]) [µl/s]\r\n",
        "\tDrawDelay =\t$(params["DrawDelay"]) [ms]\r\n",
        "\tDispSpeed =\t$(params["DispSpeed"]) [µl/s]\r\n",
        "\tDispenseDelay =\t$(params["DispenseDelay"]) [ms]\r\n",
        "\tWasteSpeed =\t$(params["WasteSpeed"]) [µl/s]\r\n",
        "\tSampleHeight =\t$(params["SampleHeight"]) [mm]\r\n",
        "\tInjectWash =\t$(params["InjectWash"])\r\n",
        "\tWashVolume =\t$(params["WashVolume"]) [µl]\r\n",
        "\tWashSpeed =\t$(params["WashSpeed"]) [µl/s]\r\n",
        "\tLoopWashFactor =\t$(params["LoopWashFactor"])\r\n",
        "\tPunctureOffset =\t$(params["PunctureOffset"]) [mm]\r\n",
        "\tPumpDevice =\t$(params["PumpDevice"])\r\n",
        "\tSyncWithPump =\t$(params["SyncWithPump"])\r\n",
        "\tPump_Pressure.Step =\t$(params["Pump_Pressure.Step"]) [s]\r\n",
        "\tPump_Pressure.Average =\t$(params["Pump_Pressure.Average"])\r\n",
        "\tCurve =\t$(params["Curve"])\r\n\r\n",

        "\tFlow =\t$(params["Flow"]) [ml/min]\r\n\r\n",

        "\t; Wait for the Ready signals from the pump and autsosampler\r\n",
        " 0.000\tWait\tPump.Ready and Sampler.Ready and PumpModule.Ready\r\n\r\n",

        "\tInjectMode =\tUserProg\r\n\r\n",

        "\tThe following section of code (containing all beginning with 'Udp') is not evaluated by Chromeleon as it is read.\r\n",
        "\tInstead, the commands are carried out when the 'Inject' command is read.\r\n\r\n",

        "\t; USER DEFINED INJECTION STARTS HERE\r\n\r\n",

        "\t; Wait for the stimulus input to have a Low signal, to prevent trigger of two injections from a single signal\r\n",
        "\tUdpWaitInput\tInput=Inp1, State=Low\r\n\r\n",

        "\t; Preflush the injection needle\r\n",
        "\tUdpInjectValve\tPosition=Inject\r\n",
        "\tUdpSyringeValve\tPosition=Needle\r\n",
        "\tUdpDraw\tFrom=SampleVial, Volume=$(params["PreflushVolume"]), SyringeSpeed=GlobalSpeed, SampleHeight=Globalheight\r\n",
        "\tUdpMixWait\tDuration=$(parse(Float64, params["DrawDelay"])/1000) ; Pause to avoid air intake from aspirating the sample too quickly\r\n\r\n",

        "\t; Fill the Sample Loop with the plate position and volume specified by the sequence file\r\n",
        "\tUdpInjectValve\tPosition=Load\r\n",
        "\tUdpDraw\tFrom=SampleVial, Volume=Volume, SyringeSpeed=GlobalSpeed, SampleHeight=Globalheight\r\n",
        "\tUdpMixWait\tDuration=$(parse(Float64, params["DrawDelay"])/1000) ; Pause to avoid air intake from aspirating the sample too quickly\r\n\r\n",

        "\t; Wait for the signal from Image before performing the injection\r\n",
        "\tUdpWaitInput\tInput=Inp1, State=High\r\n\r\n",

        "\t; Inject the sample and signal to Chromeleon that the injection has been performed\r\n",
        "\tUdpInjectValve\tPosition=Inject\r\n",
        "\tUdpInjectMarker\r\n\r\n",

        "\t; Wash the needle\r\n",
        "\tUdpSyringeValve\tPosition=Waste\r\n",
        "\tUdpMoveSyringeHome\tSyringeSpeed=GlobalSpeed\r\n",
        "\tUdpMixNeedleWash\tVolume=$(params["WashVolume"])\r\n\r\n",

        "\t; USER DEFINED INJECTION ENDS HERE\r\n\r\n",

        "\t; Perform the user-defined injection (see above)\r\n",
        "\tInject\r\n\r\n",

        "\t; Send timestamp signal to imagine\r\n",
        "\tRelay_4.State\tOn\r\n\r\n",

        "\t; Start recording the pump pressure (not used for optical records, but I'm not sure if it is safe to omit this step)\r\n",
        "\tPump_Pressure.AcqOn\r\n\r\n",

        " $(params["Delay"])\tPump_Pressure.AcqOff ; Stop pressure acquisition\r\n",
        "\t; Note the time of the above command (in minutes).\r\n",
        "\t; This time interval may be important for fully emptying/washing the Sample Loop.\r\n",
        "\t; If set too long, it might also cause Chromeleon to \"miss\" a signal from Imagine.\r\n\r\n",

        "\t; Check your flowrate for the pump (\"Flow\" above), sample volume in your sequence file,\r\n", 
        "\t; and inter-trial delay for your Imagine waveforms to avoid issues.\r\n\r\n",

        "\t; Turn off Relay 4\r\n",
        "\tRelay_4.State\tOff\r\n\r\n",

        "\tEnd\r\n",
    )
    flush(io)
end

