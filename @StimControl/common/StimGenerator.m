classdef StimGenerator

methods (Static, Access=public)

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
    if ~contains(p.UsingDefaults, 'totalTicks')
        stim = StimGenerator.GetBaseFromTicks(params.totalTicks);
    elseif params.duration ~= -1
        stim = StimGenerator.GetBaseFromDuration(params.duration, params.SampleRate);
    else
        error('please specify either the total stimulus ticks or the stimulus duration')
    end
    if (params.duration > 0 && params.rampUp + params.rampDown > params.duration) ...
        || (params.duration == -1 && (params.rampUp + params.rampDown > StimGenerator.TicksToMs(params.totalTicks, params.sampleRate)))
        error('invalid parameters for stimulus: ramp duration must fit within overall duration');
    end

    durationTicks = length(stim);
    periodTicks = round(params.sampleRate/params.frequency); % period in ticks
    onTicks = round(periodTicks*(params.dutyCycle/100));
    totalPeriods = floor(durationTicks / periodTicks);
    if params.rampUp > 0 || params.rampDown > 0
        rampUpPeriods = round(StimGenerator.MsToTicks(params.rampUp) / periodTicks); %TODO SIMPLIFY
        rampUpTickIncrease = onTicks / rampUpPeriods;
        rampDownPeriods = round(StimGenerator.MsToTicks(params.rampDown) / periodTicks); %TODO SIMPLIFY
        rampDownTickDecrease = onTicks / rampDownPeriods;
    else
        rampUpPeriods = 0;
        rampDownPeriods = 0;
    end
    highPeriods = totalPeriods - (rampUpPeriods + rampDownPeriods);
    % offset = delay + startTPost*tPreLength;
    % generate stim
    if params.rampUp > 0 || params.rampDown > 0
        % ramp up
        for i = 1:rampUpPeriods:periodTicks
            stim(i:i+round(rampUpTickIncrease * i)) = 1;
        end
        st = rampUpPeriods*periodTicks + 1;
    else
        st = 1;
    end
    % max DC
    for i = st:periodTicks:(st + highPeriods)*periodTicks
        stim(i:i+onTicks) = 1;
    end
    st = st + (highPeriods * periodTicks);
    % ramp down
    if params.rampUp > 0 || params.rampDown > 0
        for i = st:st + rampUpPeriods:periodTicks
            stim(i:i+round(onTicks - (rampDownTickDecrease * i))) = 1;
        end
    end
    %todo this is DODGYYY
    stim = stim(1:durationTicks);
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
    addParameter(p, '')
    addParameter()

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
    %     amplitude  (double=5): amplitude of the pulse, V

    p = inputParser();
    addParameter(p, 'sampleRate', 1000, @(x) isnumeric(x));
    addParameter(p, 'totalTicks', 1000, @(x) isnumeric(x));
    addParameter(p, 'duration', -1, @(x) isnumeric(x));
    addParameter(p, 'rampUp', 0, @(x) isnumeric(x));
    addParameter(p, 'rampDown', 0, @(x) isnumeric(x));
    addParameter(p, 'frequency', 30, @(x) isnumeric(x));
    addParameter(p, 'dutyCycle', 50, @(x) isnumeric(x));
    addParameter(p, 'name', 'analogPulse');
    addParameter(p, 'display', false, @(x) islogical(x));
    parse(p, varargin{:});
    params = p.Results;
    if ~contains(p.UsingDefaults, 'totalTicks')
        stim = StimGenerator.GetBaseFromTicks(totalTicks);
    elseif params.duration ~= -1
        stim = StimGenerator.GetBaseFromDuration(params.duration, params.SampleRate);
    else
        error('please specify either the total stimulus ticks or the stimulus duration')
    end
    if (params.duration > 0 && params.rampUp + params.rampDown > params.duration) ...
        || (params.duration == -1 && (params.rampUp + params.RampDown > StimGenerator.TicksToMs(params.totalTicks, params.sampleRate)))
        error('invalid parameters for stimulus: ramp duration must fit within overall duration');
    end

    %% TODO
    if params.display
        StimGenerator.show(stim);
    end
end

function stim = sinewave(varargin)

end

function stim = thermalpreview(varargin)
    % Generates a thermal preview stim of given length
    % PARAMS:
    %     sampleRate (double=1000): sample rate of output array (Hz)
    %     duration   (double=1000): duration of output (ms)
    %     totalTicks (double=1000): duration of output in total ticks. Alternative to duration. 
    %         When both are defined, duration will be limited to within totalTicks. 
    p = inputParser();
    addParameter(p, 'display', false, @(x) islogical(x));
    parse(p, varargin{:});
    params = p.Results;

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

function out = GetBaseFromTicks(totalTicks)
    out = zeros(totalTicks, 1);
end

function out = GetBaseFromDuration(durationMs, sampleRate)
    out = zeros(round(MsToTicks(durationMs, sampleRate)), 1);
end

function p = show(stim)
    tax = linspace(1, length(stim), length(stim));
    p = plot(tax, stim);
end
end
end
