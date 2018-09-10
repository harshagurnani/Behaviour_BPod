function DropDispense

global BpodSystem


S.MaxTrials = 50;
for currentTrial = 1:S.MaxTrials
    
    %--- Assemble state machine
    sma = NewStateMachine();

    %% Dispense water drop
    
    sma = AddState(sma, 'Name', 'DispenseDrop', ...
        'Timer', 0.050, ...       % needs to be changed to match the actual time needed to dispense 5 ul
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {'Valve1', 1});  % not sure whether this is the right command

    
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
    
    if currentTrial < S.MaxTrials
        currentTrial
        %figure, imagesc(zeros(10,10))
        %k = waitforbuttonpress;
        %close
        waitTime = 10;%round(rand*5+5);
        pause(waitTime)
    end
end

end