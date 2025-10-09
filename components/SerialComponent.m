classdef (HandleCompatible) SerialComponent < HardwareComponent
% Component for the QST device
% % poll batteries
%         for ii=1:obj.nThermodes
%             obj.h.(['Thermode' char(64+ii)]).battery.Value = obj.s(ii).battery;
%         end

% NOTE: I'm doing a bit of versioning nonsense for future-proofing. 
% The library that will soon be deprecated is serial, to be replaced with serialport.
% serialport is only half implemented in the version of MATLAB I'm coding in (2023b)
% so some of the updated functions are untested.
% Here are two resources, plus a transition guide, which may be helpful:
% (deprecated ~2025): serial - https://au.mathworks.com/help/instrument/serialport.html#mw_b5492b6b-bb1c-409b-a54d-effbd128452b
% (introduced ~2024): serialport - https://au.mathworks.com/help/instrument/serialport.html#mw_b5492b6b-bb1c-409b-a54d-effbd128452b
% transition guide: https://au.mathworks.com/help/instrument/transition-your-code-to-serialport-interface.html 
% Good luck, brave soldier. - MS

properties(Constant, Access = public)
    ComponentProperties = SerialComponentProperties;
end

properties (Access = public)
    
end

methods(Access=public)
% Constructor that sets generic values for the class
function obj = SerialComponent(varargin)
    p = obj.GetBaseParser();
    parse(p, varargin{:});
    params = p.Results;
    obj = obj.Initialise(params);
    if params.Initialise && ~params.Abstract
        obj = obj.InitialiseSession('ConfigStruct', params.ConfigStruct);
    end
end

% Initialise the hardware session. 
function obj = InitialiseSession(obj, varargin)
    p = inputParser;
    addParameter(p, 'ConfigStruct', []);
    addParameter(p, 'KeepHardwareSettings', []);
    addParameter(p, 'ActiveDeviceIDs', {}, @iscellstr);
    parse(p, varargin{:});
    params = p.Results;

    obj.ConfigStruct = obj.GetConfigStruct(params.ConfigStruct);
    if ~isfield(params, 'ComponentID')
        obj.ComponentID = obj.GetComponentID;
    else
        obj.ComponentID = params.ComponentID;
    end

    %check port is available
    if ~ismember(obj.ConfigStruct.Port, SerialComponent.FindPorts)
        warning('Serial port "%s" is not available',port)
        return
    end

    % close and delete all serial port objects on the target port
    SerialComponent.ClearPort(obj.ConfigStruct.Port);

    % start the connection with the target port.
    obj = obj.OpenSerialConnection();
    obj.query('Ose'); % activate external triggering (required with newer QST devices). added 2024.10.30
    obj.query('Om550'); % enable 55deg stim. added 2025.05.08

end


function SaveAuxiliaryConfig(obj, filepath)
    return;
end

% Start device. For synchronisation reasons, should only be used for
% self-triggered devices and 
function StartTrial(obj)

end

% Stop device
function Stop(obj)

end

% Change device parameters
function SetParams(obj, varargin)
    error("SetParams not implemented for SerialComponent");
end

% Dynamic visualisation of the object output
function StartPreview(obj)

end

% Dynamic visualisation of the object output
function StopPreview(obj)

end

% Print device information
function PrintInfo(obj)
    disp(obj.temperature);
end

% Preload a single trial
function LoadTrialFromParams(obj, componentTrialData, genericTrialData)
    obj.trialData = componentTrialData;
    preloadSingleStim(obj)
end
end

methods(Access=protected)

% gets current device status
% Options: connected / ready / running / error
function status = GetSessionStatus(obj)
    % get current device status.
    % STATUS:
    %   connected       device session initialised; not ready to start trial
    %   ready           device session initialised, trial loaded
    %   running         currently running a trial

    %TODO check the strings for this are consistent with the
    % strings for everything else. Not tested for serialport devices.
    b = obj.battery;
    status = '';
    if ~obj.isConnected
        status = "not connected";
    elseif ~strcmpi(obj.SessionHandle.TransferStatus, 'idle')
        status = 'running';
    else
        if strcmpi(obj.SessionHandle.Status, 'open')
            status = 'connected';
            %TODO how to check if it has loaded data for 'ready'
        else
            status = 'unknown';
        end
    end
end

function preloadSingleStim(obj, stimStruct)
    %QSTControl p2Serial
    for ii = 1:length(obj.s)
        idTherm = sprintf('Thermode%s',64+ii);
        if ~isfield(p,idTherm)
            continue
        end
        
        % build command stack
        stack = {};
        for param = fieldnames(p.(idTherm))'
            val = p.(idTherm).(param{:});
            switch param{:}
                case 'NeutralTemp'
                    cmd = sprintf('N%03d',round(val*10));
                case 'SurfaceSelect'
                    cmd = sprintf('S%d%d%d%d%d',val>0);
                case 'SetpointTemp'
                    cmd = helper('C%d%03d',round(val*10));
                case 'PacingRate'
                    cmd = helper('V%d%04d',round(val*10));
                case 'ReturnSpeed'
                    cmd = helper('R%d%04d',round(val*10));
                case 'dStimulus'
                    cmd = helper('D%d%05d',round(val));
                case 'nTrigger'
                    cmd = sprintf('T%03d',round(val));
                case 'integralTerm'
                    cmd = sprintf('I%d',round(val));
            end
            stack = [stack cmd]; %#ok<AGROW>
        end
        
        % send command stack to thermode
        tmp = [stack; repmat({' '},size(stack))];
        obj.s(ii).query([tmp{:}]);
    end

        function out = helper(format,val)
            if all(val==val(1))
                out = sprintf(format,0,val(1));
            else
                out = cell(1,sum(~isnan(val)));
                for idx = find(~isnan(val))
                    out{idx} = sprintf(format,idx,val(idx));
                end
            end
    end
end

function componentID = GetComponentID(obj)
    componentID = convertStringsToChars([obj.ConfigStruct.Port '-' obj.ConfigStruct.Tag]);
    componentID = [componentID{:}];
end

function SoftwareTrigger(obj, ~, ~)

end

function varargout = query(obj, query, timeout)
    % Query the serial object
    % ARGS: 
    %   query   (string): the command to be sent
    %   timeout (double): the timeout in ms
    % RETURNS: 
    %   varargout
        
    if ~exist('timeout','var')
        timeout = .03;
    end
    if isMATLABReleaseOlderThan('R2024a')
        obj.fprintfd(query,.001)
        java.lang.Thread.sleep(timeout*1000)
        n = obj.SessionHandle.BytesAvailable;
        if n
            varargout{1} = fread(obj.SessionHandle,n,'char');
            varargout{1} = char(varargout{1}(2:end))';
        elseif ~n && nargout
            varargout{1} = '';
        else
            varargout = {};
        end
    else
        timeout = timeout / 1000; % NB timeout in serialport is in seconds, while timeout in serial is in ms
        % NOT IMPLEMENTED
    end
end

 function out = queryN(obj,string,nBytes)
    obj.fprintfd(string,.001)
    out = fread(obj.SessionHandle,nBytes+1,'char');
    out = char(out(2:end))';
end

function fprintfd(obj,query,delay)
    % Write a command to the serial session handle.
    if isMATLABReleaseOlderThan('R2024a')
        for ii = 1:length(query)
            tic
            fwrite(obj.SessionHandle,string(ii));
            t = (delay-toc)*1000;
            if t > 0
                java.lang.Thread.sleep(t)
            end
        end
        fwrite(obj.SessionHandle,'\n');
    else
        % NOT IMPLEMENTED
    end
end

function bench(obj,query)
    % Benchmarking information. Tracks the time taken per byte sent.

    if isMATLABReleaseOlderThan('R2024a')
        if ~exist('query','var')
            query = 'H';
        end
        if obj.s.BytesAvailable > 0
            fread(obj.SessionHandle,obj.SessionHandle.BytesAvailable);
        end
        figure
        hold on
        for jj = 1:100
            t = nan(1,300);
            d = nan(1,300);
            fprintf(obj.s,query);
            tic
            for ii = 1:length(t)
                t(ii) = toc;
                d(ii) = obj.SessionHandle.BytesAvailable;
            end
            stairs(t*1000,d)
            fread(obj.SessionHandle,obj.SessionHandle.BytesAvailable);
        end
        xlabel('time (ms)')
        ylabel('Bytes')
        tmp = find(d==d(end),1)+1;
        fprintf('%f ms per Byte\n',t(tmp)/d(tmp)*1000)
    else
        % NOT IMPLEMENTED
    end
end

function out = temperature(obj)
    out = str2num(obj.queryN('E',23)); %#ok<ST2NM>
end

function out = battery(obj)
    out = sscanf(obj.queryN('B',13),'%*fv %d%%');
end

function help(obj)
    disp(obj.query('H',.14))
end

function response = isConnected(obj)
    varargout = obj.query('H', 1);
    response = ~isempty(varargout);
end

function obj = OpenSerialConnection(obj)
    % Open the component's serial connection, given an established ConfigStruct
    if isMATLABReleaseOlderThan('R2024a')
        obj.SessionHandle = serial(obj.ConfigStruct.Port, ...
            'BaudRate', obj.ConfigStruct.BaudRate, ...
            'Terminator', obj.ConfigStruct.Terminator, ...
            'InputBufferSize', obj.ConfigStruct.InputBufferSize);
    else
        obj.SessionHandle = serialport(obj.ConfigStruct.Port, ...
            obj.ConfigStruct.BaudRate, ...
            'Terminator', obj.ConfigStruct.Terminator, ...
            'InputBufferSize', obj.ConfigStruct.InputBufferSize);
    end
    fopen(obj.SessionHandle);
end


end

methods(Static, Access=public)
    % Complete reset. Clear device and all handles of device type.
    function Clear()
        
    end

    function components = FindAll(varargin)
        p = inputParser();
        addParameter(p, 'Initialise', true, @islogical);
        p.parse(varargin{:});
        components = {};
        for port = SerialComponent.FindPorts
            initStruct = struct( ...
                'Port', port);
            comp = SerialComponent('Initialise', p.Results.Initialise, ...
                'ConfigStruct', initStruct);
            if comp.isConnected
                components{end+1} = comp;
            else
                SerialComponent.ClearPort(port);
            end
            % for i = 1:2
            %     % sometimes the port takes a second to initialise 
            %     % - ping twice to avoid missing available ports.
            %     if comp.isConnected
            %         components{end+1} = comp;
            %         break
            %     end
            % end
            % if ~comp.isConnected
            %     SerialComponent.ClearPort(port);
            % end
        end
    end

    function out = FindPorts()
        % Find all a computer's available ports.
        if isMATLABReleaseOlderThan('R2020a')
            out = seriallist;
        else
            out = serialportlist;
        end
    end

    function ClearPort(port)
        % clear any existing session on the target port.
        if isMATLABReleaseOlderThan('R2024a')
            tmp = instrfind('port', port);
        else
            tmp = serialportfind(Port=port);
        end
        if ~isempty(tmp)
            fclose(tmp);
            delete(tmp);
        end
    end
end
end

% serial Construct serial port object.
 
%     serial will be removed in a future release. Use serialport instead.
 
%     S = serial('PORT') constructs a serial port object associated with
%     port, PORT. If PORT does not exist or is in use you will not be able
%     to connect the serial port object to the device.
 
%     In order to communicate with the device, the object must be connected
%     to the serial port with the FOPEN function.
 
%     When the serial port object is constructed, the object's Status property
%     is closed. Once the object is connected to the serial port with the
%     FOPEN function, the Status property is configured to open. Only one serial
%     port object may be connected to a serial port at a time.
 
%     S = serial('PORT','P1',V1,'P2',V2,...) constructs a serial port object
%     associated with port, PORT, and with the specified property values. If
%     an invalid property name or property value is specified the object will
%     not be created.
 
%     Note that the property value pairs can be in any format supported by
%     the SET function, i.e., param-value string pairs, structures, and
%     param-value cell array pairs.
 
%   serial Functions
%   serial object construction.
%     serial        - Construct serial port object.
 
%   Getting and setting parameters.
%     get           - Get value of serial port object property.
%     set           - Set value of serial port object property.
 
%   State change.
%     fopen         - Connect object to device.
%     fclose        - Disconnect object from device.
%     record        - Record data from serial port session.
 
%   Read and write functions.
%     fprintf       - Write text to device.
%     fgetl         - Read one line of text from device, discard terminator.
%     fgets         - Read one line of text from device, keep terminator.
%     fread         - Read binary data from device.
%     fscanf        - Read data from device and format as text.
%     fwrite        - Write binary data to device.
%     readasync     - Read data asynchronously from device.
 
%   serial port functions.
%     serialbreak   - Send break to device.
 
%   General.
%     delete        - Remove serial port object from memory.
%     inspect       - Open inspector and inspect instrument object properties.
%     instrcallback - Display event information for the event.
%     instrfind     - Find serial port objects with specified property values.
%     instrfindall  - Find all instrument objects regardless of ObjectVisibility.
%     isvalid       - True for serial port objects that can be connected to
%                     device.
%     stopasync     - Stop asynchronous read and write operation.
 
%   serial Properties
%     BaudRate                  - Specify rate at which data bits are transmitted.
%     BreakInterruptFcn         - Callback function executed when break interrupt
%                                 occurs.
%     ByteOrder                 - Byte order of the device.
%     BytesAvailable            - Specifies number of bytes available to be read.
%     BytesAvailableFcn         - Callback function executed when specified number
%                                 of bytes are available.
%     BytesAvailableFcnCount    - Number of bytes to be available before
%                                 executing BytesAvailableFcn.
%     BytesAvailableFcnMode     - Specifies whether the BytesAvailableFcn is
%                                 based on the number of bytes or terminator
%                                 being reached.
%     BytesToOutput             - Number of bytes currently waiting to be sent.
%     DataBits                  - Number of data bits that are transmitted.
%     DataTerminalReady         - State of the DataTerminalReady pin.
%     ErrorFcn                  - Callback function executed when an error occurs.
%     FlowControl               - Specify the data flow control method to use.
%     InputBufferSize           - Total size of the input buffer.
%     Name                      - Descriptive name of the serial port object.
%     ObjectVisibility          - Control access to an object by command-line users and
%                                 GUIs.
%     OutputBufferSize          - Total size of the output buffer.
%     OutputEmptyFcn            - Callback function executed when output buffer is
%                                 empty.
%     Parity                    - Error detection mechanism.
%     PinStatus                 - State of hardware pins.
%     PinStatusFcn              - Callback function executed when pin in the
%                                 PinStatus structure changes value.
%     Port                      - Description of a hardware port.
%     ReadAsyncMode             - Specify whether an asynchronous read operation
%                                 is continuous or manual.
%     RecordDetail              - Amount of information recorded to disk.
%     RecordMode                - Specify whether data is saved to one disk file
%                                 or to multiple disk files.
%     RecordName                - Name of disk file to which data sent and
%                                 received is recorded.
%     RecordStatus              - Indicates if data is being written to disk.
%     RequestToSend             - State of the RequestToSend pin.
%     Status                    - Indicates if the serial port object is connected
%                                 to serial port.
%     StopBits                  - Number of bits transmitted to indicate the end
%                                 of data transmission.
%     Tag                       - Label for object.
%     Terminator                - Character used to terminate commands sent to
%                                 serial port.
%     Timeout                   - Seconds to wait to receive data.
%     TimerFcn                  - Callback function executed when a timer event
%                                 occurs.
%     TimerPeriod               - Time in seconds between timer events.
%     TransferStatus            - Indicate the asynchronous read or write
%                                 operations that are in progress.
%     Type                      - Object type.
%     UserData                  - User data for object.
%     ValuesReceived            - Number of values read from the device.
%     ValuesSent                - Number of values written to device.
 
%     Example:
%         % To construct a serial port object:
%           s1 = serial('COM1');
%           s2 = serial('COM2', 'BaudRate', 1200);
 
%         % To connect the serial port object to the serial port:
%           fopen(s1)
%           fopen(s2)
 
%         % To query the device.
%           fprintf(s1, '*IDN?');
%           idn = fscanf(s1);
 
%         % To disconnect the serial port object from the serial port.
%           fclose(s1);
%           fclose(s2);
 
%     See also serial/fopen.

%     Documentation for serial