%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

%}

%% Susu 2018-April

function GoNoGoMultiPole()
    
    % SETUP
    % You will need:
    % - A Bpod.
    % > Port#1: Lickport, DI/O
    % > Port#2: Pole (LED channel)

    global BpodSystem S;

    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings

        S.GUI.WaterValveTime = 0.05;        % in sec
        S.GUI.PreSamplePeriod = 0.5;        % in sec
        S.GUI.SamplePeriod = 1.5;           % in sec
        S.GUI.AnswerPeriod = 1.5;           % in sec
        S.GUI.ConsumptionPeriod = 1.5;      % in sec
        S.GUI.StopLickingPeriod = 1.5;      % in sec
        S.GUI.TimeOut = 4;                  % in sec
        S.GUIPanels.Behaviour= {'WaterValveTime', 'PreSamplePeriod', 'SamplePeriod', 'AnswerPeriod', ...
            'ConsumptionPeriod', 'StopLickingPeriod', 'TimeOut'};


        S.GUI.GoPosition = 2e4;
        S.GUI.NoGoPosition = 7e4;
        S.GUI.MotorMoveTime = 2;
        S.GUI.APMotorPosition = 0;
        S.GUI.LateralPolePosition = 1e5;
        

        S.GUIPanels.PolePositions = {'GoPosition', 'NoGoPosition', 'MotorMoveTime', 'APMotorPosition', 'LateralPolePosition'};


        S.GUIMeta.ProtocolType.Style = 'popupmenu';     % protocol type selection
%         S.GUIMeta.ProtocolType.String = {'Water_Valve_Calibration', 'Licking', 'Training_Go_nolick', 'Go_NoGo_Multi_Pole_out'};
        
        S.GUIMeta.ProtocolType.String = {'Water_Valve_Calibration', 'Licking', 'Go_NoGo_Multi_Pole_in', 'Go_NoGo_Multi_Pole_out','Training1_Go_reward','Training2_NoGo_Go'};
        S.GUI.ProtocolType = 3;

        S.GUIPanels.Protocol= {'ProtocolType'};


        S.GUI.MaxSame = 3;
        S.GUI.NoGoProb = 0.5;
        S.GUI.Min_correct_Nogo = 1;
        S.GUI.Max_incorrect_Nogo = 3;
        S.GUI.Min_correct_Go = 1;
        S.GUI.Max_incorrect_Go = 3;

        S.GUIPanels.TrialSelection= {'MaxSame','NoGoProb','Min_correct_Nogo','Max_incorrect_Nogo','Min_correct_Go','Max_incorrect_Go'};

    end


    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);

%     % Initialize total Reward display
%     TotalRewardDisplay('init'); % Total Reward display (online display of the total amount of liquid Reward earned)

    % Sync the protocol selections
    p = cellfun(@(x) strcmp(x,'ProtocolType'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualChangeProtocol, S})


    % Initiate motor
    initiateZaberMotor;


    % Setup manual motor inputs
    p = cellfun(@(x) strcmp(x,'APMotorPosition'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualMoveZaberMotor,'1'})

    p = cellfun(@(x) strcmp(x,'LateralPolePosition'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualMoveZaberMotor,'2'})


    % Move motors to current values from config file
    p = cellfun(@(x) strcmp(x,'APMotorPosition'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    anterior_pole_position = get(BpodSystem.GUIHandles.ParameterGUI.Params(p),'String');
    move_absolute(motors,str2double(anterior_pole_position),1);

    p = cellfun(@(x) strcmp(x,'LateralPolePosition'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    lateral_pole_position = get(BpodSystem.GUIHandles.ParameterGUI.Params(p),'String');
    move_absolute(motors,str2double(lateral_pole_position),2);


    %% Define trials
    MaxTrials = 9999;
    TrialTypes = [];
    BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
    BpodSystem.Data.TrialOutcomes = []; % The trial outcomes


    %% Initialise plots
    BpodSystem.ProtocolFigures.GoNoGoPerfOutcomePlotFig = figure('Position', [150 800 1600 200], ...
        'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off', 'Color', [1 1 1]);

    BpodSystem.GUIHandles.GoNoGoPerfOutcomePlot = axes('Position', [.15 .2 .8 .7], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'nDisplay: ','Position',[20 170 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.DisplayNTrials = uicontrol('Style','edit','string','100','Position',[125 170 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'hit % (all): ','Position',[20 140 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.hitpct = uicontrol('Style','text','string','0','Position',[125 140 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'hit % (40): ','Position',[20 120 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.hitpctrecent = uicontrol('Style','text','string','0','Position',[125 120 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'hit % (go): ','Position',[20 90 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.hitpctgo = uicontrol('Style','text','string','0','Position',[125 90 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'hit % (nogo): ','Position',[20 70 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.hitpctnogo = uicontrol('Style','text','string','0','Position',[125 70 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'Trials: ','Position',[20 40 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.numtrials = uicontrol('Style','text','string','0','Position',[125 40 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'Rewards: ','Position',[20 20 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.numRewards = uicontrol('Style','text','string','0','Position',[125 20 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    GoNoGoPerfOutcomePlot(BpodSystem.GUIHandles.GoNoGoPerfOutcomePlot,1,'init',0);

    % BpodNotebook('init');

    
    % Pause the protocol before starting
    BpodSystem.Status.Pause = 1;
    HandlePauseCondition;


    % Define outputs
    io.WaterOutput  = {'ValveState',2^0};    % Valve 1 open 
    io.PoleOutput = {'PWM2',255};            % Behavioural port 2, LED pin
    io.AcqTrig = {'BNC1', 1};
    io.Bitcode = {'BNC2', 1};
    io.CameraTrig = {'WireState', 1};
   

    %% Main trial loop
    for currentTrial = 1 : MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin

        % Select trials here: 1's (Go trial) or 0's (Nogo trial)

        disp(['Starting trial ',num2str(currentTrial)])

        % Set the trial type
        TrialTypes(currentTrial) = TrialTypeSelection(currentTrial); 

        GoNoGoPerfOutcomePlot(BpodSystem.GUIHandles.GoNoGoPerfOutcomePlot,currentTrial,'next_trial',TrialTypes(currentTrial), BpodSystem.GUIHandles.DisplayNTrials);

        if TrialTypes(currentTrial) == 1
            str = 'Go';
        else
            str = 'Nogo';
        end

        disp(['Starting trial ',num2str(currentTrial),' TrialType: ' str ' (' num2str(TrialTypes(currentTrial)) ')'])

        sma = NewStateMatrix(); % Assemble state matrix

        % Build state matrix depending on the protocol type
        switch S.GUI.ProtocolType

            case 1          % Water_Valve_Calibration            
                % Water_Valve_Calibration when sensor is touched, release 50 drops every 0.5 seconds
                ndrops = 50; interval = 0.5;

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...                    
                    'Timer', interval, ...
                    'StateChangeConditions', {'Port1In', 'Drop1_Openvalve', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', {});

                for i_drop = 1:ndrops-1   

                    sma = AddState(sma, 'Name', ['Drop',num2str(i_drop),'_Openvalve'], ...
                        'Timer', S.GUI.WaterValveTime, ...
                        'StateChangeConditions', {'Tup', ['Drop',num2str(i_drop),'_Closevalve']}, ...
                        'OutputActions', io.WaterOutput);

                    sma = AddState(sma, 'Name', ['Drop',num2str(i_drop),'_Closevalve'], ...
                        'Timer', interval, ...
                        'StateChangeConditions', {'Tup', ['Drop',num2str(i_drop+1),'_Openvalve']}, ...
                        'OutputActions', {});           
                end

                sma = AddState(sma, 'Name', ['Drop',num2str(ndrops),'_Openvalve'], ...
                    'Timer', S.GUI.WaterValveTime,...
                    'StateChangeConditions', {'Tup', 'TrialEnd'}, ...
                    'OutputActions', io.WaterOutput);
                
                sma = AddState(sma, 'Name', 'TrialEnd', ...                            
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});


            case 2          % Licking

                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                sma = AddState(sma, 'Name', 'WaitForLick', ...
                    'Timer', 300,...
                    'StateChangeConditions', {'Port1In', 'Reward', 'Tup', 'NoResponse'}, ...
                    'OutputActions', {});
                sma = AddState(sma, 'Name', 'Reward', ...
                    'Timer', S.GUI.WaterValveTime,...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions',  io.WaterOutput);
                sma = AddState(sma, 'Name', 'NoResponse', ...
                    'Timer', 0.05,...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});


            case 3          % Go_NoGo_Multi_Pole_in - animal can lick when the pole is in

                % Determine trial-specific state matrix fields
                switch TrialTypes(currentTrial)
                    case 1  % Lick in Go
                        LickAction = 'Reward';
                    case 0  % Lick in No go
                        LickAction = 'Extra_ITI'; % Extra inter-trial-interval
                end         

                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                % Move motor into position
                moveZaberMotors(TrialTypes(currentTrial));

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Port1In', 'EarlyLickSample', 'Tup', 'AnswerPeriod'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   

                sma = AddState(sma, 'Name', 'EarlyLickSample', ... 
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup','SamplePeriod'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         % wait for response
                    'Timer', S.GUI.AnswerPeriod, ...
                    'StateChangeConditions', {'Port1In', LickAction, 'Tup', 'NoResponse'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.PoleOutput io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'NoResponse', ...                           % no response
                    'Timer', 0.002, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Extra_ITI', ...                            % incorrect response
                    'Timer', S.GUI.TimeOut, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % pole out and trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});


            case 4          % Go_NoGo_Multi_Pole_out - animal can lick when the pole is out

                % Determine trial-specific state matrix fields
                switch TrialTypes(currentTrial)
                    case 1  % Lick in Go
                        LickAction = 'Reward';
                    case 0  % Lick in No go
                        LickAction = 'Extra_ITI'; % Extra inter-trial-interval
                end         

                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                % Move motor into position
                moveZaberMotors(TrialTypes(currentTrial));

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...                       % pre-sample
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Port1In', 'EarlyLickSample', 'Tup', 'AnswerPeriod'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   

                sma = AddState(sma, 'Name', 'EarlyLickSample', ... 
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup','SamplePeriod'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         % pole out and wait for response
                    'Timer', S.GUI.AnswerPeriod, ...
                    'StateChangeConditions', {'Port1In', LickAction, 'Tup', 'NoResponse'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'NoResponse', ...                           % no response
                    'Timer', 0.002, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Extra_ITI', ...                            % incorrect response
                    'Timer', S.GUI.TimeOut, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});
                
                
            case 5          % case 5 Go_NoGo_Multi_Pole_in - water delivered on go trials without licking

                % Determine trial-specific state matrix fields
                switch TrialTypes(currentTrial)
                    case 1  % Lick in Go
                        LickAction = 'Reward';
                        AnswerTUPAction = 'Reward';
                    case 0  % Lick in No go
                        LickAction = 'Extra_ITI'; % Extra inter-trial-interval
                        AnswerTUPAction = 'NoResponse';
                end         

                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                % Move motor into position
                moveZaberMotors(TrialTypes(currentTrial));

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in, deliver reward
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Tup', 'AnswerPeriod'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   

               sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         % wait for response
                    'Timer', S.GUI.AnswerPeriod, ...
                    'StateChangeConditions', {'Port1In', LickAction, 'Tup', AnswerTUPAction}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.PoleOutput io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'NoResponse', ...                           % no response
                    'Timer', 0.002, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Extra_ITI', ...                            % incorrect response
                    'Timer', S.GUI.TimeOut, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % pole out and trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});


        

        case 6%    case 6          % Go_NoGo_Multi_Pole_in - water delivered on first go trial after no-go
                    

                % Determine trial-specific state matrix fields
                switch TrialTypes(currentTrial)
                    case 1  % Lick in Go/ Reward if previous trial was no-go
                        if currentTrial > 1 && (TrialTypes(currentTrial-1) == 0)
                            AnswerTUPAction = 'Reward';
                        else
                            AnswerTUPAction = 'NoResponse';
                        end
                        LickAction = 'Reward';
                    case 0  % Lick in No go
                        AnswerTUPAction = 'NoResponse';
                        LickAction = 'Extra_ITI'; % Extra inter-trial-interval
                end         

                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                % Move motor into position
                moveZaberMotors(TrialTypes(currentTrial));

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

%                 sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in
%                     'Timer', S.GUI.SamplePeriod, ...
%                     'StateChangeConditions', {'Port1In', 'EarlyLickSample', 'Tup', 'AnswerPeriod'}, ...
%                     'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   
                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Tup', 'AnswerPeriod'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);  
                
                sma = AddState(sma, 'Name', 'EarlyLickSample', ... 
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup','SamplePeriod'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         % wait for response
                    'Timer', S.GUI.AnswerPeriod, ...
                    'StateChangeConditions', {'Port1In', LickAction, 'Tup', AnswerTUPAction}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.PoleOutput io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'NoResponse', ...                           % no response
                    'Timer', 0.002, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Extra_ITI', ...                            % incorrect response
                    'Timer', S.GUI.TimeOut, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % pole out and trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});
                
                
                
                
                
        end
        SendStateMatrix(sma);
        RawEvents = RunStateMatrix;         % this step takes a long time and variable (seem to wait for GUI to update, which takes a long time)

        if ~isempty(fieldnames(RawEvents)) % If trial data was returned

            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data

            % BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin

            BpodSystem.Data.TrialSettings(currentTrial) = S; % Add the settings used for the current trial to the Data struct (to be saved after the trial ends)

            BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Add the trial type of the current trial to data

            if S.GUI.ProtocolType == 3 || S.GUI.ProtocolType == 4  || S.GUI.ProtocolType == 5  || S.GUI.ProtocolType == 6 

                UpdateGoNoGoPerfOutcomePlot(TrialTypes, BpodSystem.Data);

            end

%             UpdateTotalRewardDisplay(S.GUI.RewardAmount, currentTrial);

            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file

            BpodSystem.ProtocolSettings = S;

            SaveProtocolSettings(S); % SaveBpodProtocolSettings;

        end

        % Pause the protocol before starting if in Water-Valve-Calibration
        if S.GUI.ProtocolType == 1
            BpodSystem.Status.Pause = 1;
        end        

        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.Status.BeingUsed == 0
            return
        end

    end

end


%% 
function trial_type = TrialTypeSelection(currentTrial)

    global BpodSystem
    global S
    
    if S.GUI.ProtocolType == 2 % Licking
        trial_type = 1; % Make it always the go-trial position, so mouse doesn't have to unlearn anything.
    end    

    if S.GUI.MaxSame == Inf || S.GUI.MaxSame > currentTrial

        if rand(1) <= S.GUI.NoGoProb
            trial_type = 0; 
        else
            trial_type = 1;
        end

    else
        % MaxSame applies, check for its rules:
        % If there's been a string of MaxSame all the same, force change:
        if all(BpodSystem.Data.TrialTypes((currentTrial-S.GUI.MaxSame+1):currentTrial-1) == ...
                BpodSystem.Data.TrialTypes(currentTrial-1))

            if BpodSystem.Data.TrialTypes(currentTrial-1) == 1
                trial_type = 0;
            else
                trial_type = 1;
            end

        else
            % Haven't reached MaxSame limits yet, choose at random:
            if rand(1) <= S.GUI.NoGoProb
                trial_type = 0; 
            else
                trial_type = 1;
            end

        end

    end
    
end


%%
function UpdateGoNoGoPerfOutcomePlot(TrialTypes, Data)

    global BpodSystem

    Outcomes = zeros(1,Data.nTrials);

    for x = 1:Data.nTrials

        if Data.TrialSettings(x).GUI.ProtocolType == 3 || ...
           Data.TrialSettings(x).GUI.ProtocolType == 4 || ...
           Data.TrialSettings(x).GUI.ProtocolType == 5 || ...
           Data.TrialSettings(x).GUI.ProtocolType == 6

            if TrialTypes(x) == 1 % go

                if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
                    Outcomes(x) = 1;    % correct
                    BpodSystem.Data.TrialOutcomes(x) = 1;
                elseif ~isnan(Data.RawEvents.Trial{x}.States.NoResponse(1))
                    Outcomes(x) = 2;    % no repsonse
                    BpodSystem.Data.TrialOutcomes(x) = 2;
                elseif ~isnan(Data.RawEvents.Trial{x}.States.Extra_ITI(1))
                    Outcomes(x) = 0;    % error
                    BpodSystem.Data.TrialOutcomes(x) = 0;
                else
                    Outcomes(x) = 3;    % others
                    BpodSystem.Data.TrialOutcomes(x) = 3;
                end

            elseif TrialTypes(x) == 0 % nogo

                if ~isnan(Data.RawEvents.Trial{x}.States.NoResponse(1))
                    Outcomes(x) = 1;    % correct
                    BpodSystem.Data.TrialOutcomes(x) = 1;
                elseif ~isnan(Data.RawEvents.Trial{x}.States.Extra_ITI(1))
                    Outcomes(x) = 0;    % error
                    BpodSystem.Data.TrialOutcomes(x) = 0;
                else
                    Outcomes(x) = 3;    % others
                    BpodSystem.Data.TrialOutcomes(x) = 3;
                end        
            end

        else
            Outcomes(x) = 3;        % others
            BpodSystem.Data.TrialOutcomes(x) = 3;
        end

    end


    GoNoGoPerfOutcomePlot(BpodSystem.GUIHandles.GoNoGoPerfOutcomePlot,Data.nTrials,'update', ...
        TrialTypes, BpodSystem.GUIHandles.DisplayNTrials, Outcomes);

end


%%
function GoNoGoPerfOutcomePlot(ax, Ntrials, action, varargin)

    global BpodSystem
    sz = 10;

    switch action
        case 'update'
            types = varargin{1};
            displayHand = varargin{2};
            outcomes = varargin{3};

            Ndisplay = str2double(get(displayHand, 'String'));

            toPlot = false(1, Ntrials);

            ind1 = max(1, Ntrials-Ndisplay+1);
            ind2 = Ntrials;

            toPlot(ind1:ind2) = true;

            miss = (outcomes == 0);
            hit  = (outcomes == 1);
            noresponse  = (outcomes == 2);

            hold(ax, 'off');
            xdat = find(toPlot&hit);
            plot(ax, xdat, types(xdat)+1, 'go', 'MarkerSize', sz); hold(ax, 'on');

            xdat = find(toPlot&miss);
            plot(ax, xdat, types(xdat)+1, 'ro', 'MarkerSize', sz);

            xdat = find(toPlot&noresponse);
            plot(ax, xdat, types(xdat)+1, 'kx', 'MarkerSize', sz);

            hitpct = 100.*sum(hit)./Ntrials;
            ind40 = max(1, Ntrials-40+1):Ntrials;
            hitpctrecent = 100.*sum(hit(ind40))./numel(ind40);

            gotrial = (BpodSystem.Data.TrialTypes == 1);
            nogotrial  = (BpodSystem.Data.TrialTypes == 0);
            hitgo = hit(gotrial);

            hitpctgo = 100.*sum(hitgo)./sum(gotrial);
            hitpctnogo = 100.*(sum(hit) - sum(hitgo))./sum(nogotrial);

            set(BpodSystem.GUIHandles.hitpct, 'String', num2str(hitpct));
            set(BpodSystem.GUIHandles.hitpctrecent, 'String', num2str(hitpctrecent));
            set(BpodSystem.GUIHandles.hitpctgo, 'String', num2str(hitpctgo));
            set(BpodSystem.GUIHandles.hitpctnogo, 'String', num2str(hitpctnogo));
            set(BpodSystem.GUIHandles.numtrials, 'String', num2str(Ntrials));
            set(BpodSystem.GUIHandles.numRewards, 'String', num2str(sum(hitgo)));

            xlim(ax, [ind1 ind1+Ndisplay-1+5]);
            ylim(ax, [0 3]);


        case 'next_trial'
            currentType = varargin{1};
            displayHand = varargin{2};
            Ndisplay = str2double(get(displayHand, 'String'));
            ind1 = max(1, Ntrials-Ndisplay+1);
    %         ind2 = Ntrials;

            hold(ax, 'on');
            plot(ax, Ntrials, currentType+1, 'ko', 'MarkerSize', sz);
            xlim(ax, [ind1 ind1+Ndisplay-1+5]);

    end

    set(ax, 'YTick', [0 1 2 3], 'YTickLabel', {''; 'Nogo'; 'Go'; ''});

end


%%
% function UpdateTotalRewardDisplay(RewardAmount, currentTrial)
% % If Rewarded based on the state data, update the TotalRewardDisplay
%     global BpodSystem
% 
%     if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))
%         
%         TotalRewardDisplay('add', RewardAmount);
%         
%     end
%     
% end


%% Assemble Bitcode
function state_matrix = AddBitcode(state_matrix_in, trial_num, bitcodeCH_output, otherCH_output, next_state_name)
    
    state_matrix = state_matrix_in;

    bit_time = 0.002; % bit time
    gap_time = 0.008; % gap (inter-bit) time
    num_bits = 10;     % 2^10 = 1024 possible trial nums

    x = double(dec2binvec(trial_num)');
    if length(x) < num_bits
        x = [x; zeros([num_bits-length(x) 1])];
    end
    x = double(x); % x is now 10-bit vector giving trial num.

    for i_bit = 1:num_bits

        if x(i_bit)==1

            output_bitONState = [bitcodeCH_output otherCH_output];
        else

            output_bitONState = otherCH_output;
        end

        state_matrix = AddState(state_matrix, 'Name', ['Bitcode_bit',num2str(i_bit),'_ON'], ...                              % incorrect response
            'Timer', bit_time,...
            'StateChangeConditions', {'Tup', ['Bitcode_bit',num2str(i_bit),'_OFF']},...
            'OutputActions', output_bitONState);

        if i_bit < num_bits
            state_matrix = AddState(state_matrix, 'Name', ['Bitcode_bit',num2str(i_bit),'_OFF'], ...                              % incorrect response
                'Timer', gap_time,...
                'StateChangeConditions', {'Tup', ['Bitcode_bit',num2str(i_bit+1),'_ON']},...
                'OutputActions', otherCH_output);

        else
            state_matrix = AddState(state_matrix, 'Name', ['Bitcode_bit',num2str(i_bit),'_OFF'], ...                              % incorrect response
                'Timer', gap_time,...
                'StateChangeConditions', {'Tup', next_state_name},...
                'OutputActions', otherCH_output);
        end

    end

end