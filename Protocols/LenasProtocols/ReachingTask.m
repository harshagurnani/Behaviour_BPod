function ReachingTask

global BpodSystem

S.MaxTrials = 5;
for currentTrial = 1:S.MaxTrials
    sma = NewStateMachine();
    
    %% Move to start position
    % Georges function
    
    %% Wait for 2 s touch to resting bar
    % Wait for touch
    sma = AddState(sma, 'Name', 'WaitRestingTouch', ...
        'Timer', 20, ...
        'StateChangeConditions', ...
        {'Tup', 'exit', 'Port1In', 'TouchDuration'}, ...
        'OutputActions', {});
    
    % Verify touch length > 2 s
    sma = AddState(sma, 'Name', 'TouchDuration', ...
        'Timer', 2, ...
        'StateChangeConditions', ...
        {'Tup', 'DispenseDrop', 'Port1Out', 'WaitRestingTouch'}, ...
        'OutputActions', {});
    
    %% Dispense water drop
    sma = AddState(sma, 'Name', 'DispenseDrop', ...
        'Timer', 0.2, ...       % needs to be changed to match the actual time needed to dispense 5 ul
        'StateChangeConditions', {'Tup', 'WaitWaterTouch'}, ...
        'OutputActions', {ValveState}, 3);  % not sure whether this is the right command
    
    %% Wait for touch to water drop
    sma = AddState(sma, 'Name', 'WaitWaterTouch', ...
        'Timer', 7, ...
        'StateChangeConditions', ...
        {'Tup', 'Exit', 'Port2In', 'WaitWaterUntouch'}, ...
        'OutputActions', {});
    
    % Wait till touch is broken
    sma = AddState(sma, 'Name', 'WaitWaterUntouch', ...
        'Timer', 2, ...
        'StateChangeConditions', ...
        {'Tup', 'Exit', 'Port2Out', 'Exit'}, ...
        'OutputActions', {});
    
    SendStateMachine(sma); % Send state machine to the Bpod state machine device
    RawEvents = RunStateMachine; % Run the trial and return events
    
    %% Remove water drop
    % Georges function to move to pad
    
    % Georges function to move to home
    
    
    
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