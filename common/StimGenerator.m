class StimGenerator

methods (static, Access=public)

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
    %     dutyCycle  (0<double<100): the stimulus's maximum duty cycle, as a percentage
        
    p = inputParser();
    addParameter(p, 'sampleRate', 1000, isdouble);
    addParameter(p, 'totalTicks', 1000, isdouble);
    addParameter(p, 'duration', -1, isdouble);
    addParameter(p, 'rampUp', 0, isdouble);
    addParameter(p, 'rampDown', 0, isdouble);
    addParameter(p, 'frequency', 30, isdouble);
    addParameter(p, 'dutyCycle', 50, isdouble);
    addParameter(p, 'name', 'PWM stim');
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
        || (params.duration == -1 && (params.rampUp + params.RampDown > StimGenerator.TicksToMs(params.totalTicks)))
        error('invalid parameters for stimulus: ramp duration must fit within overall duration');
    end

    periodTicks = round(rate/params.frequency); % period in ticks
    onTicks = round(periodTicks*(params.dutyCycle/100));
    totalPeriods = floor(durationTicks / periodTicks);
    if ramp
        rampUpPeriods = round(StimGenerator.MsToTicks(params.rampUp) / periodTicks); %TODO SIMPLIFY
        rampUpTickIncrease = onTicks / rampUpPeriods;
        rampDownPeriods = round(StimGenerator.MsToTicks(params.rampDown) / periodTicks); %TODO SIMPLIFY
        rampDownTickDecrease = onTicks / rampDownPeriods;
    else
        rampUpPeriods = 0;
        rampDownPeriods = 0;
    end
    highPeriods = totalPeriods - (rampUpPeriods + rampDownPeriods);
    offset = delay + startTPost*tPreLength;
    % generate stim
    singleStim = zeros(1, durationTicks);
    if ramp
        % ramp up
        for i = offset:rampUpPeriods:periodTicks
            singleStim(i:i+round(rampUpTickIncrease * i)) = 1;
        end
        st = rampUpPeriods*periodTicks + 1;
    else
        st = offset;
    end
    % max DC
    for i = st:st + highPeriods:periodTicks
        singleStim(i:i+onTicks) = 1;
    end
    st = st + (highPeriods * periodTicks);
    % ramp down
    if ramp
        for i = st:st + rampUpPeriods:periodTicks
            singleStim(i:i+round(onTicks - (rampDownTickDecrease * i))) = 1;
        end
    end
    if isfield(params, 'RepDel')
        repdelTicks = MsToTicks(params.RepDel);
        nRepeats = params.rep;
    else
        repdelTicks = 0;
        nRepeats = 1;
    end
    totalDurTicks = (repdelTicks + durationTicks) * nRepeats;
    if length(singleStim) == length(stim)
        stim = singleStim;
    elseif length(singleStim) > length(stim)
        stim = singleStim(1:length(stim));
    else
        maxLength = length(singleStim);
        for i = offset:offset+totalDurTicks:durationTicks+maxLength
            % if i + stimBlockLength - 1 <= stimLength
            %     stim(i : i + stimBlockLength - 1) = singleStim;
            % end
            stim(i:i+numel(singleStim)-1) = singleStim;
        end
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
    addParameter(p, '')
    addParameter()
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
    addParameter(p, 'sampleRate', 1000, isdouble);
    addParameter(p, 'totalTicks', 1000, isdouble);
    addParameter(p, 'duration', -1, isdouble);
    addParameter(p, 'rampUp', 0, isdouble);
    addParameter(p, 'rampDown', 0, isdouble);
    addParameter(p, 'frequency', 30, isdouble);
    addParameter(p, 'dutyCycle', 50, isdouble);
    addParameter(p, 'name', 'PWM stim');
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
        || (params.duration == -1 && (params.rampUp + params.RampDown > StimGenerator.TicksToMs(params.totalTicks)))
        error('invalid parameters for stimulus: ramp duration must fit within overall duration');
    end

    %% TODO
        
end

function stim = sinewave(varargin)

end


%% PRIVATE METHODS
function out = MsToTicks(x, rate)
    out = round(x*rate/1000);
end

function out = TicksToMs(x, rate)
    out = x*1000/rate;
end

function out = GetBaseStim()
end

function out = GetBaseFromTicks(totalTicks)
    out = zeros(totalTicks, 1);
end

function out = GetBaseFromDuration(durationMs, sampleRate)
    out = zeros(round(MsToTicks(durationMs, sampleRate)), 1);
end
