function DropWithTouch

global BpodSystem

R = RoboPort(true, 'COM9', '115200');
R.set_origin

middlePosition = [-18 20];
dropPosition = [-14 24];

R.move(middlePosition(1,1), middlePosition(1,2));
R.move(dropPosition(1,1), dropPosition(1,2));

S.MaxTrials = 20;
for currentTrial = 1:S.MaxTrials
    
    %--- Assemble state machine 
    sma = NewStateMachine();
    sma = SetCondition(sma, 1, 'Port2', 1);
    
    %% Wait for and measure 2s contact
    
    sma = AddState(sma, 'Name', 'WaitForContact', ...
        'Timer', 10, ...
        'StateChangeConditions', {'Condition1', 'HoldContact', 'Port2In', 'HoldContact', 'Tup', 'exit'}, ... 
        'OutputActions', {});
    
    sma = AddState(sma, 'Name', 'HoldContact', ...
        'Timer', 2, ...
        'StateChangeConditions', {'Port3Out', 'WaitForContact', 'Tup', 'DispenseDrop'}, ...
        'OutputActions', {});
    
    %% Dispense drop
    
    sma = AddState(sma, 'Name', 'DispenseDrop', ...
        'Timer', 0.1, ...
        'StateChangeConditions', {'Tup', 'Waiting'}, ...
        'OutputActions', {'Valve1', 1});
    
    %% Wait for drop pickup
    sma = AddState(sma, 'Name', 'Waiting', ...
        'Timer', 10, ...
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

R.move(middlePosition);
R.close()

end