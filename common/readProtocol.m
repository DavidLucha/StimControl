function [p,g] = readProtocol(filename,varargin)

% NB THINGS TO VALIDATE:
% hardware is not targeted by two functions simultaneously
% oddball params are valid: 
    % with buffers, it's physically possible to leave a buffer of x stims at nstims y and swap ratio z

%% DEBUG
% if isempty(filename)
%     filename = [pwd filesep 'StimControl' filesep 'protocolfiles' filesep 'TempandVibe.stim'];
% end

%% parse inputs
ip = inputParser;
addRequired(ip,'filename',...
    @(x)validateattributes(x,{'char'},{'nonempty'}));
parse(ip,filename,varargin{:});

%% read file
if ~exist(ip.Results.filename,'file')
    error('File not found: %s',ip.Results.filename)
end
pathBase = ip.Results.filename(1:find(ip.Results.filename == filesep, 1,'last'));
fid   = fopen(ip.Results.filename);
lines = textscan(fid,'%s','Delimiter','\n','MultipleDelimsAsOne',1);
fclose(fid);
lines = lines{1};

%% remove comment lines
lines(cellfun(@(x) strcmp(x(1),'%'),lines)) = [];

%% define defaults
g = struct(...              % general parameters
    'dPause',               5,...
    'nProtRuns',            1,...
    'rand',                 0);
trial = struct( ...
    'nRuns',                1, ...
    'tPre',                 1000, ...
    'tPost',                5000);
stimBlock = struct( ...
    'nStims',               1, ...
    'repDel',               0, ...
    'startDel',             0);

% function st1 = mergeStructs(st1, st2)
%     fs = fields(st2);
%     for i = 1:length(fs)
%         if ~isfield(st1, fs{i})
%             st1.(fs{i}) = st2.(fs{i});
%         end
%     end
% end

% standardStimStruct = struct( ...
%     'type', '', ...
%     'identifier', '', ...
%     'targetDevices', [], ...
%     'isAcquisitionTrigger', false, ...
%     'duration', 0);

QSTStimStruct = struct( ...
    'identifier', 'QST', ....
    'type', 'serial', ...
    'targetDevices', ["QST"], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0, ...
    'commands', struct(...
        'NeutralTemp',          32,...    
        'PacingRate',           ones(1,5) * 999,...
        'ReturnSpeed',          ones(1,5) * 999,...
        'SetpointTemp',         ones(1,5) * 32,...
        'SurfaceSelect',        true(1,5),...
        'dStimulus',            ones(1,5) * 1000,...
        'integralTerm',         1,...
        'nTrigger',             255,...
        'VibrationDuration',    0));
pwmStruct = struct( ...
    'type', 'PWM', ...
    'identifier', '', ...
    'targetDevices', [], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0, ...
    'rampUp', 0, ...
    'rampDown', 0, ...
    'frequency', 25, ...
    'dutyCycle', 50);
piezoStruct = struct( ...
    'identifier', 'piezoStim', ....
    'type', 'piezo', ...
    'targetDevices', ["Aurora"], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0, ...
    'frequency', 0, ...
    'stimNum', 0, ...
    'amplitude', 0, ...
    'ramp', 20, ...
    'nStims', 0);
digitalTriggerStruct = struct( ...
    'type', 'digitalTrigger', ...
    'identifier', '', ...
    'targetDevices', [], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0, ...
    'frequency', 20);
digitalPulseStruct = struct( ...
    'type', 'digitalPulse', ...
    'identifier', '', ...
    'targetDevices', [], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0);
analogPulseStruct = struct( ...
    'type', 'analogPulse', ...
    'identifier', '', ...
    'targetDevices', [], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0, ...
    'rampOn', 0, ...
    'rampOff', 0, ...
    'baseAmp', 0, ...
    'pulseAmp', 10);
sinewaveStruct = struct( ...
    'type', 'sineWave', ...
    'identifier', '', ...
    'targetDevices', [], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0, ...
    'amplitude', 0, ...
    'frequency', 30, ...
    'phase', 0, ...
    'verticalShift', 0, ...
    'amplitudeMod', 1);
noiseStruct = struct( ...
    'type', 'analogNoise', ...
    'identifier', '', ...
    'targetDevices', [], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0, ...
    'maxAmplitude', 10, ...
    'minAmplitude', -10, ...
    'distribution', 'normal'); %either normal or uniform
arbitraryStruct = struct( ...
    'type', 'arbitrary', ...
    'identifier', '', ...
    'targetDevices', [], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0, ...
    'filename', '', ...
    'interpolate', false);
squareWaveStruct = struct( ...
    'type', 'arbitrary', ...
    'identifier', '', ...
    'targetDevices', [], ...
    'isAcquisitionTrigger', false, ...
    'duration', 0, ...
    'frequency', 20, ...
    'pulseWidth', 0.5, ...
    'maxAmp', 10, ...
    'minAmp', -10);

oddballParams = struct(...
    'distributionMethod', 'random', ... %even / random / semirandom
    'minSwapDist', 0, ...
    'swapRatio', 0.5, ...
    'oddballRel', 'rand'); % rand / seq - | or |> 

% %% Finish initialising.
% p = repmat(p,1,1000);

%% parse general specs - on first line only
if regexpi(lines{1},'(nProtRep)|(randomize)|(dPause)')
    line      = lines{1};
    [line,~]  = strtok(line,'%');
    line      = strtrim(line);
    while ~isempty(line)
        [token,line] = strtok(line); %#ok<STTOK>
        tmp = regexpi(token,'^([a-z]+)(-?\d+)$','once','tokens');
        if ~isempty(tmp)
            val = str2double(tmp(2));
            switch lower(tmp{1})
                case 'nprotrep'
                    validateattributes(val,{'numeric'},{'positive'},...
                        mfilename,token)
                    g.nProtRep = val;
                    continue
                case 'randomize'
                    validateattributes(val,{'numeric'},{'nonnegative',...
                        '<=',2},mfilename,token)
                    g.randomize = val;
                    continue
                case 'dpause'
                    validateattributes(val,{'numeric'},{'nonnegative'},...
                        mfilename,token)
                    g.dPause = val;
                    continue
            end
        end
        error('Unknown parameter "%s"',token)
    end
    lines(1) = [];
end

%% parse stimulus definitions
for idxStim = 1:length(lines)
    line = lines{idxStim};
    
    % clip comments (indicated by '%')
    [line,tmp] = strtok(line,'%');
    if ~isempty(tmp)
        p(idxStim).Comments = cell2mat(regexp(tmp,'^[\s%]*(.*?)\s*$','tokens','once'));
        line = strtrim(line);
    end
    
    while ~isempty(line)
        % obtain the next token
        [token,line] = strtok(line); %#ok<STTOK>
        % Switch to appropriate subroutine for provided token.  
        if regexpi(token,'^(I[01]|[NT]\d{3}|C\d{4}|S[01]{5}|[VR]\d{5}|D\d{6})[A-Z]?$','once')
            % Thermode
            p = parseThermode(p,token,idxStim);
            continue
        elseif regexpi(token, ['^' regexArb '$'], 'once')
            % Specific arbitrary control - gotta read a text file.
            p = parseArbitrary(p,token,idxStim, pathBase);
            continue
        elseif regexpi(token, ['^((Ana)|(Vib)|(Piezo)|(Dig)|(PWM)|(LED)|(Cam))' ...
                standardRegexSuffix], 'once')
            % Standard format
            p = parseToken(p, token, idxStim);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
            continue
        end
        % parse remaining tokens
        tmp = regexpi(token,'^([a-z]+)(-?\d+)$','once','tokens');
        if ~isempty(tmp)
            val = str2double(tmp(2));
            switch lower(tmp{1})
                case 'tpre'
                    validateattributes(val,{'numeric'},{'positive'},...
                        mfilename,token,idxStim)
                    p(idxStim).tPre  = val;
                    continue
                case 'tpost'
                    validateattributes(val,{'numeric'},{'positive'},...
                        mfilename,token,idxStim)
                    p(idxStim).tPost = val;
                    continue
                case 'ttact' %TODO WHAT THIS - REMOVE? :)
                    p(idxStim).tTactile = val;
                    continue
                case 'dtact'
                    validateattributes(val,{'numeric'},{'nonnegative'},...
                        mfilename,token,idxStim)
                    p(idxStim).dTactile = val;
                    continue
                case 'nrep'
                    validateattributes(val,{'numeric'},{'nonnegative'},...
                        mfilename,token,idxStim)
                    p(idxStim).nRepetitions = val;
                    continue
            end
        end

        % if the token was not recognized, throw an error
        error('Unknown parameter "%s" for stimulus #%d',token,idxStim)
    end
end
p(idxStim+1:end) = [];

end

function p = parseArbitrary(p, token, idxStim, pathBase)
    tmp = regexpi(token, '^([A-Z]*)(\:)(.*)$', 'once', 'tokens');
    id = tmp{1};
    filename = tmp{3};
    % extend filename if necessary
    if ~contains(filename, ':')
        % referenced in relation to location of protocol file
        % standardise fileseps
        filename = replace(filename,'/',filesep);
        filename = replace(filename,'\',filesep);
        % extend to full path
        filename = [pathBase filename];
    end
    % read file
    if ~exist(filename,'file')
        error('File not found: %s',filename)
    end
    fid   = fopen(filename);
    lines = textscan(fid,'%s','Delimiter','\n','MultipleDelimsAsOne',1);
    fclose(fid);
    lines = lines{1};
    
    % remove comment lines
    lines(cellfun(@(x) (strcmp(x(1),'%') || strcmp(x(2), '%')) ,lines)) = [];
    try
        type = lower(lines{1});
        protocol = str2num(lines{2});
    catch
        error("Invalid protocol in file %s. Protocol line should have only numbers", filename);
    end
    if ~contains(['digital', 'analog'], type)
        error("invalid data type %s in file %s", type, filename);
    end
    p(idxStim).(id).type = type;
    p(idxStim).(id).filename = filename;
    p(idxStim).(id).data = protocol;
end

function p = parseToken(p, token, idxStim)
    tmp = regexpi(token, ['^((Ana)|(Vib)|(Piezo)|(Dig)|(PWM)|(LED)|(Cam))', ...
                            '([A-z]*)', '(\d*)', '([A-Z]?)', '$'], 'once', 'tokens');
    stimType = tmp{1};
    attr = tmp{2};
    val = str2double(tmp{3});
    subtype = upper(tmp{4});
    if isempty(subtype)
        % applies to all stimuli of that type
        surfaces = cellfun(@(x) regexpi(x, ['(', stimType, ')([A-Z]*)'], ...
            'match'), fields(p), 'UniformOutput', false);
        surfaces = unique(horzcat(surfaces{:}));
    else
        surfaces = {strcat(stimType, subtype)};
    end
    for sName = surfaces
        sName = sName{:};
        if ~isfield(p(idxStim).(sName), lower(attr))
            error('Faulty parameter "%s" for stimulus #%d (%s, valid values for %s: %s)', ...
                    attr,idxStim,p(idxStim).(sName),fields(p(idxStim).(sName)))
        end
        p(idxStim).(sName).(lower(attr)) = val;
    end
end

function p = parseThermode(p,token,idxStim)
% Read the parameter's value, define the fieldname and wether the parameter
% applies to multiple surfaces of the thermode
    switch token(1)
        case 'N'
            fieldname = 'NeutralTemp';
            value     = readRangeThermode(token,2:4,[200 500],idxStim)/10;
            multiSurf = false;
        case 'S'
            fieldname = 'SurfaceSelect';
            value     = token(2:6)=='1';
            multiSurf = false;
        case 'C'
            fieldname = 'SetpointTemp';
            value     = readRangeThermode(token,3:5,[0 600],idxStim)/10;
            multiSurf = true;
        case 'V'
            fieldname = 'PacingRate';
            value     = readRangeThermode(token,3:6,[1 9990],idxStim)/10;
            multiSurf = true;
        case 'R'
            fieldname = 'ReturnSpeed';
            value     = readRangeThermode(token,3:6,[100 9990],idxStim)/10;
            multiSurf = true;
        case 'D'
            fieldname = 'dStimulus';
            value     = readRangeThermode(token,3:7,[10 99999],idxStim);
            multiSurf = true;
        case 'T'
            fieldname = 'nTrigger';
            value     = readRangeThermode(token,2:4,[0 255],idxStim);
            multiSurf = false;
        case 'I'
            fieldname = 'integralTerm';
            value     = token(2)=='1';
            multiSurf = false;
    end
    
    % Does the parameter apply to individual surfaces of the thermode?
    % Obtain logical index for respective surface(s) ...
    %TODO WHAT
    if multiSurf
        idxSurface = readRangeThermode(token,2,[0 5],idxStim);
        if ~idxSurface, idxSurface = 1:5; end
    end

    thermodes = cellfun(@(x) regexpi(x, '(Thermode)([A-Z]?)', ...
            'match'), fields(p(idxStim)), 'UniformOutput', false); 
    thermodes = unique(horzcat(thermodes{:}));
    if isstrprop(token(end),'alpha')
        if ~ismember(['Thermode', upper(token(end))],thermodes)
      	    format = token;
            format(end) = 'X';
            error(['Faulty parameter "%s" for stimulus #%d (%s, valid ' ...
                'values for X: %s)'],token,idxStim,format,thermodes{:})
        end
        thermodes = {['Thermode' upper(token(end))]};
    end

    % Loop through the thermodes and assign the value
    for thermode = thermodes
        if multiSurf
            if ~isfield(p(idxStim).(thermode{:}),fieldname)
                p(idxStim).(thermode{:}).(fieldname) = NaN(1,5);
            end
        end
        p(idxStim).(thermode{:}).(fieldname) = value;
    end

end


function value = readRangeThermode(token,pos,range,idxStim)
value = str2double(token(pos));
if value<range(1) || value>range(2)
    x = sprintf('%%0%dd',max(arrayfun(@(x) length(num2str(x)),range)));
    format = subsasgn(token,struct('type','()','subs',{{pos}}),'X');
    error(['Faulty parameter "%s" for stimulus #%d (%s, valid ' ...
        'range for %s: ' x '-' x ')'],token,idxStim,format,...
        repmat('X',1,length(pos)),range(1),range(2))
end
end


% function checkRange(value,range,token,idxStim)
% if value<range(1) || value>range(2)
%     error(['Faulty parameter "%s" for stimulus #%d (expecting value ' ...
%         'to be within %d-%d)'],token,idxStim,range(1),range(2))
% end
% end