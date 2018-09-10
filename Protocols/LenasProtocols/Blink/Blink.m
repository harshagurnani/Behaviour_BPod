function Blink

global BpodSystem

S.MaxTrials = 3;
for currentTrial = 1:S.MaxTrials
    
    %--- Assemble state machine
    sma = NewStateMachine();
    
    sma = SetCondition(sma, 1, 'Port2', 1);
    
    sma = AddState(sma, 'Name', 'LightPort1', ... 
        'Timer', 3, ...
        'StateChangeConditions', {'Tup', 'ShortLightPause'}, ...
        'OutputActions', {'PWM1', 50});
    
    sma = AddState(sma, 'Name', 'ShortLightPause', ... 
        'Timer', 1, ...
        'StateChangeConditions', {'Tup', 'LightPause'}, ...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'LightPause', ... 
        'Timer', 20, ...
        'StateChangeConditions', {'Condition1', 'ShortLightPort1', 'Port2In', 'ShortLightPort1', 'Tup', 'exit'}, ...
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'ShortLightPort1', ... 
        'Timer', 0.5, ...
        'StateChangeConditions', {'Tup', 'ShortLightPause2'}, ...
        'OutputActions', {'PWM1', 50});
    
    sma = AddState(sma, 'Name', 'ShortLightPause2', ... 
        'Timer', 1, ...
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