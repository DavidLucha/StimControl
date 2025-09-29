# STIM CONTROL
This repo contains a Matlab-based stimulus/acquisition interfacing program. 
Initially a fork from [WidefieldImager](https://github.com/churchlandlab/WidefieldImager) by the Churchland lab, and incorporating portions of code taken from the [Poulet Lab](https://github.com/poulet-lab)'s QST control program, it aims to provide a fully modular and configurable interface for neural stimulus and imaging.

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


# NOTES FOR DEVELOPERS
## General Notes
I'm not a native MATLAB developer, so I've found it helpful to put comments in functions of the documentation that I found useful when building that function. 

### The StimControl h struct
% GUI objects
baseGrid
tabs
Setup
    Control.panel
    Preview.panel
    ComponentConfig.panel
    Logo
Session
    Tab
    Grid
    Control.panel
    Info.panel
    Hardware.panel
    Preview.panel
    Logo
Menu
    File
        Save
            ComponentConfig
            Protocol
            StimControlSession
        Load
            ComponentConfig
            StimControlSession
ConfirmComponentConfigBtn
CancelComponengConfigBtn
ComponentConfig
    Label
    Table
% notably not GUI objects but spiritually close
ComponentConfig
    SelectedComponentIndex
    ConfigStruct
    Component
        Handle
        Properties
    ValsToUpdate

### The StimControl d struct
Available 
Active 
IDComponentMap          map from ComponentIDs to component handles
IDidxMap                map from ComponentIDs to component's index in 'Available' - todo remove this, now we have IDComponentMap I don't know if it's needed?
ProtocolComponents      map from Protocol subnames to ComponentIDs 
ComponentProtocols      map from ComponentIDs to Protocol subnames (e.g. 'DAQ-Dev1': 'ThermodeA')

### The StimControl path struct
setup.base
session.base
paramBase           hardware params
protocolBase        experiment protocol files
sessionBase         for StimControl session saving
componentMaps       mapping components to protocols

## Adding New Hardware
New hardware components should implement the HardwareComponent abstract class (which outlines required functions and properties), and have their defaults written in a struct of named Component Properties. 
To fully integrate a new HardwareComponent into StimControl, you will need to implement the following functionality:
- in StimControl.m under 'findAvailableHardware', find all hardware of the component type and add it to obj.d.Available as a struct compatible with the 'Struct' argument of the HardwareComponent class
- in callbackEditComponentConfig, under 'extract component', extract the component from the struct.

### Component Properties
Device component properties are statically defined per device type. A DeviceComponentProperties obj has a single attribute - Data - which is a struct of named ComponentProperties. Each ComponentProperty has the following settable values 
|Field          |Default            |DataType               |Description|
|-----          |-----              |-----                  |-----|
|default        |[]                 |any                    |Default value for the property|
|allowable      |{}                 |categorical-compatible |Allowable values for the property. Should be categorical-compatible ([see below](#categoricals))|
|validatefcn    |@(val) true        |function handle        |Validation function handle for inserted value. Takes value as arg. Either this or allowable should be set.|
|dependencies   |@(propStruct) true |function handle        |Validation function handle for requirements for property to be set. Takes full struct as arg.|
|dependents     |{}                 |cellstr                |List of properties that are affected when the value for this property is changed
|required       |@(propStruct) true |function handle        |Function handle that returns whether a property needs to be defined. Takes full struct as arg. Will only be evaluated if dependencies evaluates to true.|
|dynamic        |false              |logical                |If true, property can be changed without restarting device.|
|note           |""                 |string or char array   |Comments.|

All DeviceComponentProperties should include a ComponentProperty named ID.

#### Hints for Non-Matlab Devs
When working with a ComponentProperty that takes a vector as its value (e.g. camera ROI - see CameraComponent and CameraComponentProperties for examples of this), you should format it as a string, then just use str2num and num2str to convert when necessary to interface with the hardware itself. The StimControl software uses some of Matlab's built-in table/struct/transposition tools that don't play well with non-scalar numeric values.

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

### StimControl QOL
- [x] for loadprotocol etc. - only do it if not already assigned or "select new" has been pressed
- [ ] make it so you only have to click the map once (sidequest - why does it automatically minimise when you click the component map??)
- [ ] DENOTE TRIGGERED DEVICES AND START *ALL* OF THOSE FIRST
- [ ] 'AlternativesOk' in HardwareComponent for device searching vs strict init behaviour
- [ ] make componentconfig automatically pop up when config table is clicked, no need for "edit component config" to see config
- [ ] can't currently see protocol previews without an attached session handle? (DAQ relevant) 
- [ ] some way of ensuring a session is preloaded before allowing 'start' - if you stop then start without changing the trial number it causes crashes atm
- [ ] error handling during run that doesn't require an app restart
- [ ] python socketing - make it easy to add functionality with python
- [ ] check timers for busymode - should be queue for the important ones, NOT DROP

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
- [ ] get session loading working
- [ ] TEST SAVING
- [ ] add parametrised analog outputs - ramp, noise, sine
- [ ] Clean up SaveComponentConfig - you don't need to search for the daq, you have all the params already. Just return the config file.
- [ ] Live preview! Look into data linking below
- [ ] add config for primary vs secondary (hardware-triggered) daqs?

### Code Cleanup
- [ ] move ComponentID to ComponentProperties with generator function
- [ ] switch preview build to single createpanelpreview function
- [ ] add [progress bar](https://au.mathworks.com/help/matlab/ref/uiprogressdlg.html) to loading screens?
- [ ] put runTrial into ONE TIMER with a startfcn
- [ ] go through all the TODOs and get rid of commented code

## A Non-Matlab User's Guide To Matlab
Consider this like that one counter:
![Dear programmer: When I wrote this code, only god and I knew how it worked. Now, only god knows it! Therefore, if you are trying to optimize this routine and it fails (most surely), please increase this counter as a warning for the next person: total_hours_wasted_here = 254](https://preview.redd.it/hwqj7yx9vm211.jpg?width=640&crop=smart&auto=webp&s=d8dbb52e8272c553603a8ca66f48ca85a8a40de9)

### Categoricals
I used categoricals because they're the easiest way I could find to dynamically code dropdowns for component config. If you ever end up wanting to use them elsewhere, first reconsider. Then, if you're ABSOLUTELY SUREhere are some things that helped me:

if you want to extract the value from a categorical, I extracted it from its categories() like this:
```
newVal = src.Data.values{rownum};
    if iscategorical(newVal)
        cat = categories(newVal);
        idx = find(categorical(cat) == newVal);
        newVal = cat{idx};
        %if ~isNan str2double(newVal)
            %newVal = str2double(newVal) %for numeric categories
    end
```

if you want to set the displayed value of the categorical, I did it like this:
```
cat = prop.getCategorical; #nb look in ComponentProperty for this. It is not a built-in function.
configVal = component.ConfigStruct.(rowNames{fnum});
if ischar(configVal)
    configCat = categorical(cellstr(configVal));
    idx = find(cat == configCat);
    values{fnum} = cat(idx);
elseif isstring(configVal)
    configCat = categorical(cellstr(configVal));
    idx = find(cat == configCat);
    values(fnum) = {cat(idx)};
elseif isnumeric(configVal)
    configCat = categorical(configVal);
    idx = find(cat == configCat);
    values(fnum) = {cat(idx)};
end
```

Also remember with categoricals that they only accept certain kinds of input: a numeric array, logical array, string array, or cell array of character vectors. [Helpful link](https://au.mathworks.com/help/matlab/ref/categorical.html), I hope.


### Calling anonymous functions with additional arguments
```
function createPanelThermode(obj,hPanel,~,idxThermode,nThermodes)
```
```
obj.h.(thermodeID).panel.params = uipanel(obj.h.fig,...
    'CreateFcn',    {@obj.createPanelThermode,ii,length(obj.s)});
```

### Things To Look Into
[Data Linking](https://au.mathworks.com/help/matlab/ref/matlab.graphics.internal.linkdata.html) - dynamic updates of plots as the data changes