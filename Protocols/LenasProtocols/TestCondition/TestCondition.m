function TestCondition

global BpodSystem

S.MaxTrials = 2;
for currentTrial = 1:S.MaxTrials
    
    %--- Assemble state machine
    sma = NewStateMachine();
    
    sma = SetCondition(sma, 1, 'Port2', 1);
    
    sma = AddState(sma, 'Name', 'Port1Light', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'Waiting1'},...
        'OutputActions', {'PWM1', 150});
    
    sma = AddState(sma, 'Name', 'Waiting1', ...
        'Timer', 1, ...
        'StateChangeConditions', {'Tup', 'Port2Light'}, ...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'Port2Light', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'Waiting2', 'Condition1', 'Port3Light'},...
        'OutputActions', {'PWM1', 150});
    
    sma = AddState(sma, 'Name', 'Waiting2', ...
        'Timer', 1, ...
        'StateChangeConditions', {'Tup', 'Port3Light'}, ...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'Port3Light', ...
        'Timer', 1,...
        'StateChangeConditions', {'Tup', 'Waiting3'},...
        'OutputActions', {'PWM1', 150});
    
    sma = AddState(sma, 'Name', 'Waiting3', ...
        'Timer', 5, ...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {});
    
    SendStateMachine(sma); % Send state machine to the Bpod state machine device
    RawEvents = RunStateMachine; % Run the trial and return events
    
    if ~isempty(fieldnames(RawEvents)) % If you didn't stop the session manually mid-trial
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Adds raw events to a human-readable data struct
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    
    %--- This final block of code is necessary for the Bpod console's pause and stop buttons to work
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
end

end