function Touch2Positions

global BpodSystem

cstage=roboport;
cstage.setorigin()

chanceMat = round(rand(100,1));

S.MaxTrials = 100;
for currentTrial = 1:S.MaxTrials
    
    %--- Assemble state machine
    sma = NewStateMachine();
    
    cstage.move(20,20)
    pause(0.5);
    
    if chanceMat(currentTrial,1) == 0
        cstage.move(-15,30);
    else
        cstage.move(-18,26.5);
    end

    %% Measure 2s contact
    sma = AddState(sma, 'Name', 'WaitForContact', ...
        'Timer', 60, ...
        'StateChangeConditions', {'Port2In', 'HoldContact', ...
            'Tup', 'exit'}, ...     % Tup happens when the timer runs out
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'HoldContact', ...
        'Timer', 2, ...
        'StateChangeConditions', {'Port2Out', 'WaitForContact', 'Tup', 'DispenseDrop'}, ...
        'OutputActions', {});
    
    %%
    sma = AddState(sma, 'Name', 'DispenseDrop', ...
        'Timer', 0.065, ...
        'StateChangeConditions', {'Tup', 'Waiting'}, ...
        'OutputActions', {'Valve1', 1});
    
    %% Wait after dispense
    sma = AddState(sma, 'Name', 'Waiting', ...
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
    
    cstage.move(20,30)
    pause(0.5);
    cstage.move(0,0)
    pause(1);
    
    %--- This final block of code is necessary for the Bpod console's pause and stop buttons to work
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
end

cstage.motorsoff()

end