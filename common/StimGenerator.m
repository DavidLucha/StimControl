classdef StimGenerator

methods (Static, Access=public)


function stimBlock = GenerateStimBlock(varargin)
    % Generates a stim block of given length
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     nStims (double = 1): number of times to repeat the stim within the block
    %     stimParams
    %     stims (exclusive with stimParams)
    %     repDel
    %     oddball bool true
    %     display (logical, false)
        
    p = inputParser();
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'nStims', 1, @(x) isnumeric(x));
    addParameter(p, 'stimParams', [], @(x) isstruct(x));
    addParameter(p, 'repDel', 0, @(x) isnumeric(x) && x >=0);
    addParameter(p, 'display', false, @(x) islogical(x));
    parse(p, varargin{:});
    params = p.Results;
        % offset = delay + startTPost*tPreLength;

 % if isfield(params, 'RepDel')
    %     repdelTicks = MsToTicks(params.RepDel);
    %     nRepeats = params.rep;
    % else
    %     repdelTicks = 0;
    %     nRepeats = 1;
    % end
    % totalDurTicks = (repdelTicks + durationTicks) * nRepeats;
    % if length(stim) == length(stim)
    %     stim = stim;
    % elseif length(stim) > length(stim)
    %     stim = stim(1:length(stim));
    % else
    %     maxLength = length(stim);
    %     for i = offset:offset+totalDurTicks:durationTicks+maxLength
    %         % if i + stimBlockLength - 1 <= stimLength
    %         %     stim(i : i + stimBlockLength - 1) = singleStim;
    %         % end
    %         stim(i:i+numel(stim)-1) = stim;
    %     end
    % end
end

function stim = pwm(varargin)
    % Generates a PWM stim of given length
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     duration   (double=1000): duration of output (ms)
    %     totalTicks (double=1000): duration of output in total ticks. Alternative to duration. 
    %         When both are defined, duration will be limited to within totalTicks. 
    %     rampUp     (double=0): duration of any up ramping (ms), must fall within total duration
    %     rampDown   (double=0): duration of any down ramping (ms), must fall within total duration
    %     frequency  (double=30): frequency of PWM signal (Hz)
    %     dutyCycle  (0<double<100 =50): the stimulus's maximum duty cycle, as a percentage
        
    p = inputParser();
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'totalTicks', 1000, @(x) isnumeric(x));
    addParameter(p, 'duration', -1, @(x) isnumeric(x));
    addParameter(p, 'rampUp', 0, @(x) isnumeric(x));
    addParameter(p, 'rampDown', 0, @(x) isnumeric(x));
    addParameter(p, 'frequency', 30, @(x) isnumeric(x));
    addParameter(p, 'dutyCycle', 50, @(x) isnumeric(x));
    addParameter(p, 'name', 'PWM stim');
    addParameter(p, 'display', false, @(x) islogical(x));
    parse(p, varargin{:});
    params = p.Results;
    stim = StimGenerator.GetBase(params.totalTicks, params.duration, params.sampleRate);
    if (params.duration > 0 && params.rampUp + params.rampDown > params.duration) ...
        || (params.duration == -1 && (params.rampUp + params.rampDown > StimGenerator.TicksToMs(params.totalTicks, params.sampleRate)))
        error('invalid parameters for stimulus: ramp duration must fit within overall duration');
    end

    durationTicks = length(stim);
    periodTicks = round(params.sampleRate/params.frequency); % period in ticks
    onTicks = round(periodTicks*(params.dutyCycle/100));
    totalPeriods = floor(durationTicks / periodTicks);
    if params.rampUp > 0 || params.rampDown > 0
        rampUpPeriods = round(StimGenerator.MsToTicks(params.rampUp, params.sampleRate) / periodTicks); %TODO SIMPLIFY
        rampDownPeriods = round(StimGenerator.MsToTicks(params.rampDown, params.sampleRate) / periodTicks); %TODO SIMPLIFY
    else
        rampUpPeriods = 0;
        rampDownPeriods = 0;
    end
    highPeriods = totalPeriods - (rampUpPeriods + rampDownPeriods);
    % generate stim
    jj = 1;
    for i = 1:periodTicks:length(stim)
        if jj <= rampUpPeriods
            numOnTicks = round(onTicks/(rampUpPeriods+1))*jj;
        elseif jj > totalPeriods-rampDownPeriods
            tmp = (1+totalPeriods)-jj;
            numOnTicks = round(onTicks/(rampDownPeriods+1))*tmp;
        else
            numOnTicks = onTicks;
        end
       stim(i:i+numOnTicks) = 1;
       fprintf("%d %d %d \r\n", jj, i, numOnTicks);
       jj = jj+1; 
    end
    stim = stim(1:durationTicks);
    if params.display
        StimGenerator.show(stim);
    end
end

function stim = digitalpulse(varargin)
    % Generates a digital pulse stim of given length
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     duration   (double=1000): duration of output (ms)
    %     totalTicks (double=1000): duration of output in total ticks. Alternative to duration. 
    %         When both are defined, duration will be limited to within totalTicks. 
    p = inputParser();
    addParameter(p, 'display', false, @(x) islogical(x));
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'totalTicks', 1000, @(x) isnumeric(x));
    addParameter(p, 'duration', -1, @(x) isnumeric(x));
    parse(p, varargin{:});
    params = p.Results;
    stim = StimGenerator.GetBase(params.totalTicks, params.duration, params.sampleRate);
    stim = ones(length(stim), 1);
    if params.display
        StimGenerator.show(stim);
    end
end

function stim = analogpulse(varargin)
 % Generates an analog pulse stim of given length
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     duration   (double=1000): duration of output (ms)
    %     totalTicks (double=1000): duration of output in total ticks. Alternative to duration. 
    %         When both are defined, duration will be limited to within totalTicks. 
    %     rampUp     (double=0): duration of any up ramping (ms), must fall within total duration
    %     rampDown   (double=0): duration of any down ramping (ms), must fall within total duration
    %     maxAmp     (double=5): maximum amplitude of the pulse, V
    %     minAmp     (double=0): minimum of the pulse, V

    p = inputParser();
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'totalTicks', 1000, @(x) isnumeric(x));
    addParameter(p, 'duration', -1, @(x) isnumeric(x));
    addParameter(p, 'rampUp', 0, @(x) isnumeric(x));
    addParameter(p, 'rampDown', 0, @(x) isnumeric(x));
    addParameter(p, 'maxAmp', 5, @(x) isnumeric(x));
    addParameter(p, 'minAmp', 0, @(x) isnumeric(x));
    addParameter(p, 'name', 'analogPulse');
    addParameter(p, 'display', false, @(x) islogical(x));
    parse(p, varargin{:});
    params = p.Results;
    stim = StimGenerator.GetBase(params.totalTicks, params.duration, params.sampleRate);
    if (params.duration > 0 && params.rampUp + params.rampDown > params.duration) ...
        || (params.duration == -1 && (params.rampUp + params.RampDown > StimGenerator.TicksToMs(length(stim), params.sampleRate)))
        error('invalid parameters for stimulus: ramp duration must fit within overall duration');
    end

    rampUpTicks = StimGenerator.MsToTicks(params.rampUp, params.sampleRate);
    rampDownTicks = StimGenerator.MsToTicks(params.rampDown, params.sampleRate);
    stim(1:rampUpTicks+1) = linspace(params.minAmp, params.maxAmp, rampUpTicks);
    stim(rampUpTicks+1:length(stim)-rampDownTicks) = params.maxAmp;
    stim(end-rampDownTicks:end) = linspace(params.maxAmp, params.minAmp, rampDownTicks);

    if params.display
        StimGenerator.show(stim);
    end
end

function stim = sinewave(varargin)
    % Generates an analog sinewave stim of given length
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     duration   (double=1000): duration of output (ms)
    %     totalTicks (double=1000): duration of output in total ticks. Alternative to duration. 
    %                       When both are defined, duration will be limited to within totalTicks. 
    %     amplitude  (double=5): peak-peak amplitude of the signal (V)
    %     frequency  (double=30): wave frequency
    %     phase      (double=0): phase shift, radians
    %     constant   (double or vector = 0): constant term over course of sample. 
    %                       Must be of length totalTicks or a double
    %     amplitudeMod (vector = 1): modifications for amplitude over the course of the sample. 
    %                       Must be of length totalTicks.

    p = inputParser();
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'totalTicks', 1000, @(x) isnumeric(x));
    addParameter(p, 'duration', -1, @(x) isnumeric(x));
    addParameter(p, 'frequency', 30, @(x) isnumeric(x));
    addParameter(p, 'phase', 0, @(x) isnumeric(x));
    addParameter(p, 'amplitude', 5, @(x) isnumeric(x));
    addParameter(p, 'constant', 0, @(x) isnumeric(x));
    addParameter(p, 'amplitudeMod', 1, @(x) isnumeric(x));
    addParameter(p, 'name', 'sinewave');
    addParameter(p, 'display', false, @(x) islogical(x));
    parse(p, varargin{:});
    params = p.Results;
    if params.duration ~= -1
        N = params.duration * params.sampleRate;
        dur = params.duration;
    else
        N = params.totalTicks;
        dur = StimGenerator.TicksToMs(params.totalTicks, params.sampleRate) / 1000;
    end
    tax = linspace(0, dur, N);
    stim = sin(2*pi*params.frequency*tax + params.phase);
    stim = stim * params.amplitude;
    stim = stim + params.constant;
    stim = stim .* params.amplitudeMod;

    if params.display
        StimGenerator.show(stim);
    end
end

function stim = analognoise(varargin)
    % Generate analog noise.
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     duration   (double=1000): duration of output (ms)
    %     totalTicks (double=1000): duration of output in total ticks. Alternative to duration. 
    %                       When both are defined, duration will be limited to within totalTicks. 
    %     maxAmplitude  (double=5): maximum amplitude of the signal (V)
    %     minAmplitude  (double=-5): minimum amplitude of the signal (V)
    %     distribution  (string='uniform'): random distribution to use
    p = inputParser();
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'totalTicks', 1000, @(x) isnumeric(x));
    addParameter(p, 'duration', -1, @(x) isnumeric(x));
    addParameter(p, 'maxAmplitude', 5, @(x) isnumeric(x));
    addParameter(p, 'minAmplitude', -5, @(x) isnumeric(x));
    addParameter(p, 'distribution', 'uniform', @(x) ischar(x) || isstring(x));
    addParameter(p, 'name', 'noise');
    addParameter(p, 'display', false, @(x) islogical(x));
    parse(p, varargin{:});
    params = p.Results;
    
    if params.duration ~= -1
        len = StimGenerator.MsToTicks(params.duration, params.sampleRate);
    else
        len = params.totalTicks;
    end

    switch params.distribution
        case 'normal'
            p = 6;
            stim = sum(rand(len,p),2)/p;
        case 'uniform'
            stim = rand([len 1]);
        otherwise
            error("Invalid distribution: %s", params.distribution);
    end
    mul = (params.maxAmplitude - params.minAmplitude);
    stim = stim * mul;
    stim = stim + params.minAmplitude;
    
    if params.display
        StimGenerator.show(stim);
    end
end

function stim = squarewave(varargin)
    % Generates a squarewave stim
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     duration   (double=1000): duration of output (ms)
    %     totalTicks (double=1000): duration of output in total ticks. Alternative to duration. 
    %                       When both are defined, duration will be limited to within totalTicks. 
    %     frequency  (double=30): wave frequency (Hz)
    %     maxAmp     (double=5): maximum amplitude (V)
    %     minAmp     (double=-5): minimum amplitude (V)
    p = inputParser();
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'totalTicks', 1000, @(x) isnumeric(x));
    addParameter(p, 'duration', -1, @(x) isnumeric(x));
    addParameter(p, 'frequency', 30, @(x) isnumeric(x) && x>0);
    addParameter(p, 'maxAmp', 5, @(x) isnumeric(x));
    addParameter(p, 'minAmp', 0, @(x) isnumeric(x));
    addParameter(p, 'name', 'squareWave');
    addParameter(p, 'display', false, @(x) islogical(x));
    parse(p, varargin{:});
    params = p.Results;

    stim = StimGenerator.GetBase(params.totalTicks, params.durationMs, params.sampleRate);
    pulseTicks = round(params.sampleRate/params.frequency);
    stim = stim+params.minAmp;
    for i = 1:pulseTicks:length(stim)
        stim(i:i+round(pulseTicks/2)) = params.maxAmp;
    end

    if params.display
        StimGenerator.show(stim);
    end
end

function stim = digitaltrigger(varargin)
    % Generates a digital trigger stim
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     duration   (double=1000): duration of output (ms)
    %     totalTicks (double=1000): duration of output in total ticks. Alternative to duration. 
    %                       When both are defined, duration will be limited to within totalTicks. 
    %     frequency  (double=30): wave frequency

    p = inputParser();
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'totalTicks', 1000, @(x) isnumeric(x));
    addParameter(p, 'duration', -1, @(x) isnumeric(x));
    addParameter(p, 'frequency', 30, @(x) isnumeric(x) && x>0);
    addParameter(p, 'name', 'digitalTrigger');
    addParameter(p, 'display', false, @(x) islogical(x));
    parse(p, varargin{:});
    params = p.Results;

    stim = StimGenerator.GetBase(params.totalTicks, params.durationMs, params.sampleRate);
    pulseTicks = round(params.sampleRate/params.frequency);

    for i = 1:pulseTicks:length(stim)
        stim(i:i+round(pulseTicks/2)) = 1;
    end

    if params.display
        StimGenerator.show(stim);
    end

end

function stim = arbitrarystim(varargin)

end

function stim = constantvalue(varargin)

end

function stim = thermalpreview(varargin)
    % Generates a thermal preview stim of given length
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     duration   (double=1000): duration of output (ms)
    %     totalTicks (double=1000): duration of output in total ticks. Alternative to duration. 
    %         When both are defined, duration will be limited to within totalTicks. 
    %     display     (logical=false): whether to display the generated stimulus
    % PARAMS (THERMAL):
    %     pStruct   (struct): structure of parameters for thermal stimulus
    %        If provided, will override individual parameters (below)
    %     NeutralTemp (double=32): neutral temperature (°C)
    %     PacingRate  (double=300): pacing rate (ms)
    %     ReturnSpeed (double=300): return speed (ms)
    %     SetpointTemp (double=32): setpoint temperature (°C)
    %     SurfaceSelect (vector[1x5]=[1 1 0 0 0]): surface select (1=on, 0=off)
    %     dStimulus   (double=2000): stimulus duration (ms)
    %     integralTerm (double=1): integral term
    %     nTrigger    (double=1): number of triggers
    %     VibrationDuration (double=0): vibration duration (ms)

    p = inputParser();
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'totalTicks', 1000, @(x) isnumeric(x));
    addParameter(p, 'duration', -1, @(x) isnumeric(x)); 
    addParameter(p, 'display', false, @(x) islogical(x));

    addParameter(p, 'pStruct', [], @(x) isstruct(x));

    addParameter(p, 'NeutralTemp', 32, @(x) isnumeric(x));
    addParameter(p, 'PacingRate', 300, @(x) isnumeric(x));
    addParameter(p, 'ReturnSpeed', 300, @(x) isnumeric(x));
    addParameter(p, 'SetpointTemp', 32, @(x) isnumeric(x));
    addParameter(p, 'SurfaceSelect', [1 1 0 0 0], @(x) isnumeric(x) && isvector(x) && length(x) == 5);
    addParameter(p, 'dStimulus', 2000, @(x) isnumeric(x));
    addParameter(p, 'VibrationDuration', 0, @(x) isnumeric(x));

    parse(p, varargin{:});
    params = p.Results;

    if ~contains(p.UsingDefaults, 'totalTicks')
        stim = StimGenerator.GetBaseFromTicks(params.totalTicks);
    elseif params.duration ~= -1
        stim = StimGenerator.GetBaseFromDuration(params.duration, params.SampleRate);
    else
        error('please specify either the total stimulus ticks or the stimulus duration')
    end

    fs = params.sampleRate;
    if ~isempty(pStruct)
        N = params.pStruct.NeutralTemp;
        C = params.pStruct.SetpointTemp;
        D = params.pStruct.dStimulus;
        V = params.pStruct.PacingRate;
        R = params.pStruct.ReturnSpeed;
        S = params.pStruct.SurfaceSelect;
    else
        N = params.NeutralTemp;
        C = params.SetpointTemp;
        D = params.dStimulus;
        V = params.PacingRate;
        R = params.ReturnSpeed;
        S = params.SurfaceSelect;
    end
    

    tax = linspace(1/fs, length(stim)/fs, length(stim));
    stim = ones(length(tax),5) * N;
    [~,t0] = min(abs(tax));

    for ii = find(S)
        dP    = D(ii)*fs-1;
        pulse = ones(dP,1);
        dV    = round(abs(C(ii)-N)/V(ii)*fs);
        dR    = round(abs(C(ii)-N)/R(ii)*fs);
        tmp   = linspace(0,1,dV)';
        pulse(1:min([dV dP])) = tmp((1:min([dV dP])));
        pulse = [pulse; linspace(pulse(end),0,dR)'] * (C(ii)-N) + N;
        
        tmp   = min([round(tPost*fs)+1 length(pulse)]);
        stim(t0+(1:tmp)-1,ii) = pulse(1:tmp);
    end

    %% TODO
    if params.display
        StimGenerator.show(stim);
    end
end

%% HELPER METHODS
function out = MsToTicks(x, rate)
    out = round(x*rate/1000);
end

function out = TicksToMs(x, rate)
    % p = inputParser;
    % addrequired(p, 'ticks');
    % addoptional(p, 'rate', 1000);
    % p.parse(varargin{:});
    % ticks = p.Results.ticks;
    % rate = p.Results.rate;
    out = x*1000/rate;
end

function out = GetBase(totalTicks, durationMs, sampleRate)
    % contains(p.UsingDefaults, 'totalTicks')
    if durationMs ~= -1
        out = zeros(round(StimGenerator.MsToTicks(durationMs, sampleRate)), 1);
    else
        out = zeros(totalTicks, 1);
    end
end

function p = show(stim)
    tax = linspace(1, length(stim), length(stim));
    p = plot(tax, stim);
    % p.YLim = [min(stim) max(stim)] + [-1 1]*max([range(stim)*.1 .5]);
end
end
end
