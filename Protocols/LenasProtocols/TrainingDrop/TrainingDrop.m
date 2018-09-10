function TrainingDrop

global BpodSystem

cstage=roboport;
cstage.setorigin()

S.MaxTrials = 1;
for currentTrial = 1:S.MaxTrials
    
    cstage.move(20,20)
    pause(0.5);
    cstage.move(-13,30);
    
    %--- Assemble state machine
    sma = NewStateMachine();

    %% Dispense water drop
    sma = AddState(sma, 'Name', 'DispenseDrop', ...
        'Timer', 0.065, ...       % needs to be changed to match the actual time needed to dispense 5 ul
        'StateChangeConditions', {'Tup', 'Waiting'}, ...
        'OutputActions', {'Valve1', 1});  % not sure whether this is the right command
    
    %% Wait after dispense
    sma = AddState(sma, 'Name', 'Waiting', ...
        'Timer', 3, ...
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
    cstage.move(20,20)
    
    %--- This final block of code is necessary for the Bpod console's pause and stop buttons to work
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0
        return
    end
    
    k = waitforbuttonpress;
    
end

cstage.move(0,0)
cstage.motorsoff()

end