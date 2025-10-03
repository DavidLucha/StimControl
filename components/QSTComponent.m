classdef (HandleCompatible) QSTComponent < HardwareComponent
% Component for the QST device
% % poll batteries
%         for ii=1:obj.nThermodes
%             obj.h.(['Thermode' char(64+ii)]).battery.Value = obj.s(ii).battery;
%         end

% NOTE: I'm doing a bit of versioning nonsense for SOME future-proofing. 
% The library that will soon be deprecated is serial, to be replaced with serialport.
% serialport is only half implemented in the version of MATLAB I'm coding in (2023b)
% so some of the updated functions are untested.
% Here are two resources, plus a transition guide, which may be helpful:
% (deprecated ~2025): serial - https://au.mathworks.com/help/instrument/serialport.html#mw_b5492b6b-bb1c-409b-a54d-effbd128452b
% (introduced ~2024): serialport - https://au.mathworks.com/help/instrument/serialport.html#mw_b5492b6b-bb1c-409b-a54d-effbd128452b
% transition guide: https://au.mathworks.com/help/instrument/transition-your-code-to-serialport-interface.html 
% Good luck, brave soldier. - MS

properties(Constant, Access = public)
    ComponentProperties = QSTComponentProperties.Data;
end

properties (Access = public)
    
end

methods(Access=public)
% Constructor that sets generic values for the class
function obj = QSTComponent(varargin)
    p = obj.GetBaseParser();
    parse(p, varargin{:});
    params = p.Results;
    obj = obj.Initialise(params);
    if params.Initialise && ~params.Abstract
        obj = obj.InitialiseSession(params);
    end
end

% Initialise the hardware session. 
function obj = InitialiseSession(obj, params)
    obj.ConfigStruct = obj.GetConfigStruct(params.ConfigStruct);
    if all(~params.ComponentID)
        obj.ComponentID = obj.GetComponentID;
    else
        obj.ComponentID = params.ComponentID;
    end

    %check port is available
    if ~ismember(obj.ConfigStruct.Port, obj.FindPorts)
        warning('Serial port "%s" is not available',port)
        return
    end

    % close and delete all serial port objects on the target port
    obj.ClearPort(obj.ConfigStruct.Port);

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

end
end

methods(Access=protected)

% gets current device status
% Options: ready / running / error
function status = GetSessionStatus(obj)

end

function componentID = GetComponentID(obj)
    componentID = strcat(obj.ConfigStruct.Port, '-', obj.ConfigStruct.Tag);
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

function ClearPort(obj, port)
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

function out = FindPorts(obj)
    % Find all a computer's available ports.
    if isMATLABReleaseOlderThan('R2024a')
        out = seriallist;
    else
        out = serialportlist('available'); % untested. 'available' arg may be unnecessary + limiting
    end
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

    function qstObjects = FindAll()
        
    end
end
end