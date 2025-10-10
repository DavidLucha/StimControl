# STIM CONTROL
This repo contains a Matlab-based stimulus/acquisition interfacing program. 
Initially a fork from [WidefieldImager](https://github.com/churchlandlab/WidefieldImager) by the Churchland lab, and incorporating portions of code taken from the [Poulet Lab](https://github.com/poulet-lab)'s QST control program, it aims to provide a fully modular and configurable interface for neural stimulus and imaging.

# Supported Libraries / Hardware
- imaq toolbox (currently gentl and gige have been explicitly tested)
- data acquisition toolbox
- Serial library

# NOTES FOR USERS
## PROTOCOL FILES
Types of Stimulus:
Camera
    hardware: repeat trigger
    software: software trigger
    rolling acquisition: frame captured record & start/stop trigger
Light
    Excitation (exclusive on right before imaging)
    Illumination (solid on/off in trials or flash)

## PARAMETER FILES 
Parameters are read from .json files. See ComponentProperties for a full list of the properties currently supported.

### DAQs
#### General Params
Information for DAQ parameters can be found [here](https://au.mathworks.com/help/daq/daq.html#d126e10400)
- Vendor (string: "ni" / "adi" / "mcc" / "directsound" / "digilent") - the device vendor
- Rate

#### Channel Params
DAQ Channel Param files take the following fields and possible values. Information about DAQ channel configuration can be found [here](https://au.mathworks.com/help/daq/daq.interfaces.dataacquisition.addinput.html)
- deviceID (string or blank) - the name of the DAQ. Leave blank for default value. Currently only one DAQ per param file is supported. You can get the names of all DAQs connected to the computer using "daqlist" in the MATLAB terminal.
- portNum (string or int) - the channel identifier. e.g. '1', pf0', 'port0/line7', 'port0/line20:21'
- ioType (string: 'input' / 'output' / 'bidirectional') - the channel type. 
- signalType (string: 
    - input: 'Voltage'/ 'Current'/ 'Thermocouple'/ 'Accelerometer'/ 'RTD'/ 'Bridge'/ 'Microphone'/ 'IEPE'/ 'Digital'/ 'EdgeCount'/ 'Frequency'/ 'PulseWidth'/ 'Position'/ 'Audio'
    - output: 'Voltage'/ 'Current'/ 'Digital'/ 'PulseGeneration'/ 'Audio'/ 'Sine'/ 'Square'/ 'Triangle'/ 'RampUp'/ 'RampDown'/ 'DC'/ 'Arbitrary'
    - bidirectional)

## To Do List
### General
- [ ] GUI that spits out hardware parameters and protocol
- [ ] Implement additional hardware: Aurora serial
- [ ] add widefield stuff to StimControl?
- [ ] get David's stim paradigms in that bad boy
- [ ] Select at the start of the session which hardware you want to use, and initialise DAQ channels etc. then - DO NOT reaload channels for every new protocol file!!!
- [ ] PROTOCOL FILES: allow a single identifier for multiple types of output (a syntax for function definitions) -currently surmountable using arbitrary files so no pressure (see StimControl QOL)
- [ ] put something in protocolmap for "trigger device" so you don't have to trigger them all one after another?
- [ ] Choose active hardware at start of session, not start of protocol. Pick it ONCE
- [ ] refine stopping criteria - make it more precise when recordings end, make the visual timers more reliable

### StimControl QOL
- [x] for loadprotocol etc. - only do it if not already assigned or "select new" has been pressed
- [ ] make it so you only have to click the map once (sidequest - why does it automatically minimise when you click the component map??)
- [ ] DENOTE TRIGGERED DEVICES AND START *ALL* OF THOSE FIRST
- [ ] 'AlternativesOk' in HardwareComponent for device searching vs strict init behaviour
- [ ] make componentconfig automatically pop up when config table is clicked, no need for "edit component config" to see config
- [ ] can't currently see protocol previews without an attached session handle? (DAQ relevant) 
- [ ] some way of ensuring a session is preloaded before allowing 'start' - if you stop then start without changing the trial number it causes crashes atm
- [ ] error handling during run that doesn't require an app restart
- [ ] (LOW PRIO) python socketing - make it easy to add functionality with python
- [ ] check timers for busymode - should be queue for the important ones, NOT DROP
- [ ] draggable / rescalable preview UI

### StimControl config
- [ ] rejig the stimulus files to allow for function-style definitions. The mapping is driving me bonkers.
- [ ] also rejig daq channel mapping: see 48AC-D74C_Dev1-ni-PCIe-6323.csv in config, and the associated logic (computer ID + DAQ ID) in DAQComponentProperties for automatic mapping per computer. Look into enabling / disabling specific hardware per session
- [ ] add ability to repeat arbitrary stims - maybe within the .astim?
- [ ] make more robust to mismatches between hardware and software labels
- [ ] persistent text file(?) mapping computer IDs with protocol / param / mapping files so you only have to select everything once per PC or if something changes

### Widefield GUI
- [x] jank when changing bin size / folders / etc.
- [ ] creating new animal may also create erroneous experiment folders if you're ALSO changing experiment
- [ ] Session param saving! (nb this should be done in matlab) - LOW PRIORITY
- [ ] ROI masking
- [ ] be able to also see deltaF/F (set pre-stim time and set average for pre-stim as zero) (for fluorescence trace: (F - F0) / F0)
- [ ] pause button

### Camera
- [x] Visualisation: Indicator when saturation / brightness is reaching full intensity so we know to adjust gain / light
- [ ] Figure out the buffering issues for multi-image-per-trigger acquisition, maybe thread it (check [imaq documentation](https://au.mathworks.com/help/imaq/videoinput.html) and [parallel computing documentation](https://au.mathworks.com/help/parallel-computing/quick-start-parallel-computing-in-matlab.html)) NB - this is something nobody at the lab has figured out how to do yet
- [ ] set all HardwareComponents up so that ConfigStruct is initialised to reflect current hardware config if it exists. This will involve not setting ComponentConfig until component is initialised or config is provided, and then reading config struct 

### DAQ
- [x] get session loading working
- [x] FIX SAVING - currently only coming in two columns.
- [ ] add parametrised analog outputs - ramp, noise, sine
- [ ] for arbitrary outputs, put some check that rates line up
- [ ] Clean up SaveComponentConfig - you don't need to search for the daq, you have all the params already. Just return the config file.
- [ ] Live preview! Look into data linking below
- [ ] add config for primary vs secondary (hardware-triggered) daqs?
- [ ] configure which lines you want to see the preview for and which you don't.

### Code Cleanup
- [ ] move ComponentID to ComponentProperties with generator function
- [ ] switch preview build to single createpanelpreview function
- [ ] add [progress bar](https://au.mathworks.com/help/matlab/ref/uiprogressdlg.html) to loading screens?
- [ ] put runTrial into ONE TIMER with a startfcn
- [ ] go through all the TODOs and get rid of commented code