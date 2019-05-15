function thumb_movement_fMRI_joystick(subjname,session)


commandwindow
%%% CHANGE LINE 67 AND 70


%% Insert this code at the beginning of your script.
commandwindow % this is important to rpevent keypresses spilling into the editor
KbName('UnifyKeyNames');
escapeKey = KbName('ESCAPE');
timingKey = KbName('t')
acceptedKeys = ([KbName('0)'),KbName('1!'),KbName('2@'),KbName('3#'),...
    KbName('4$'),KbName('5%'),KbName('6^'),KbName('7&'),KbName('8*'),KbName('9(')]);

% % Prevent spilling of keystrokes into console:
% ListenChar(-1);
KbQueueCreate
while KbCheck; end % Wait until all keys are released.

% END OF PRE-AMBLE

% try
    % Davinia Fernandez-Espejo (Jan,2017)
    % Script for the baseline and post-tDCS command following task
    % Motion tracking is doe with fORP joystick
    % audio has better timing than in the old script
    %% prepare screen params and display blank grey screen
%     sca;
%     commandwindow
%     KbName('UnifyKeyNames');
    screens = Screen('Screens');
    screenNumber = max(screens);
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    Screen('Preference', 'SkipSyncTests', 1);
    %PsychDebugWindowConfiguration
    % window= Screen('OpenWindow', 0, black, [0 0 900 600]); % for debugging
    window = Screen('OpenWindow', 0, black); % for fullscreen
    Screen('Flip', window);
    Screen('TextSize', window, 40);

%% Initialise Labjack DMc
    % Make the UD .NET assembly visible in MATLAB.
    ljasm = NET.addAssembly('LJUDDotNet');
    ljudObj = LabJack.LabJackUD.LJUD;
    % Open the first found LabJack U3.
    [ljerror, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU3', 'LJ_ctUSB', '0', true, 0);

    % Start by using the pin_configuration_reset IOType so that all pin
    % assignments are in the factory default condition.
    ljudObj.ePutS(ljhandle, 'LJ_ioPIN_CONFIGURATION_RESET', 0, 0, 0);

    % Set the state of FIO7.
    U3channel = 7;
    U3stateZero = 0;
    U3stateOne = 1; 
    ljudObj.eDO(ljhandle, U3channel, U3stateZero);

%% end of LabJack 

    
    %% Initialize Sounddriver load wave files and create audioplayer objects
    InitializePsychSound(1);
    wavfiles = load('relax_move_audio.mat');
    % Setting up beep parameters (code for playing beeps
    % taken from peterscarfe.com/beepdemo.html
    nrchannels = 2;
    freq = 48000; %expected to be 44100 but runs with it being 48000
    repetitions = 1;  % How many tmes to we wish to play the sound
    beepLengthsecs = 0.25; % Lenght of the beep
    beepTimes = [2,2,2.5,2.5,3,3]; % Lenght of the pause between beeps; this is variable so it's not predictible and leaves room for 1 second before the first beep and 2 after the last]
    startCue = 0; % Start inmediately (0=inmediately)
    waitForDeviceStart = 1; % should we wait for the device to really start (1=yes) % INFO : see help PsychPortAudio
    % Open Psych-Audio port with the follow arguments
    %(1) []= default sound device
    %(2) 1 = sound playback only
    %(3) 1 = default level of latency
    %(4) Requested frequency in samples per second
    %(5) 2 = stereo output
    pahandle = PsychPortAudio('Open', [], 1, 1, freq, nrchannels);
    
    % make a beep which we will play back to the user and fill the buffer with
    % the audio data
    myBeep = MakeBeep(500,beepLengthsecs, freq);
    % PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
    
    %% define some timing variables
    numtrials = 8; %changed this to 8 as the protocol is now 2 hours long - more power with 8 as opposed to 5/6/7
    movelength = 20; % in seconds
    relaxlength = 20;
    numbeeps =7; % I've changed this on 28th Feb 2017. Original version in the pilot had 6 beeps
    sampleTime = (1/1200); %sampling rate for motion capture
    
    %% create log variable
    log_time = cell(2,numtrials*2+1); %this one is for the onsets
    logid = 1;
    
    %% Instructions and fixation cross
    HideCursor;
    DrawFormattedText(window, 'Start moving your thumb \n as quickly as you can \n every time you hear a beep. \n Stay still when you hear "relax". \n Make sure you keep looking at \n the fixation cross at all times', 'center', 'center', white);
    Screen('Flip', window);
    WaitSecs(3);
    DrawFormattedText(window, '+', 'center', 'center', white);
    Screen('Flip', window);
    
    disp('Waiting for Trigger....');
    
    
    % the problem comes from here
    %% 't' detection code. Place at part of script where you need the first volume.
    keypress_enum = 0;
    
    KbQueueStart
    loop_start = GetSecs
    while 1 % await 't' press
        % Check the queue for key presses.
        [pressed, firstPress, firstRelease, lastPress, lastRelease]=KbQueueCheck;
        % If the user has pressed a key, then display its code number and name.
        %if pressed
        if pressed == 0
            %we don't change k to blank - a, h, s start - any other key except
            %ESCAPE pauses.  ESCAPE...escapes.
        else
            if firstPress(timingKey)
                % we have our timing event...
                lastPress_timingKey = lastPress(timingKey);
                % this retain the timing of the 't' press from KbQueueStart
                % recover this for verification if required
                break % we now exit this loop
            end
        end
        
        % if you want to force the program to continue - press escape.
        if firstPress(escapeKey)
            break;
        end
        
        pause(0.000001)
        % clc
    end
    
    %disp(['The `t` timing event occured - EXPERIMENT BEGINS',num2str(lastPress_timingKey),'ms after the KbQueueStart command'])
    
    
    %%%% up to here
    %% loop acceptedKeys detection with t rejection (at the end, not in loop)
    
    %     %%  fMRI Trigger
    %
    %     % first create a paralle port object
    %
    %     % this requires the Data Acquisition ToolBox
    %
    %
    %     dio = digitalio('parallel', 'LPT1');
    %
    %     % now we consider 16 of the lines
    %
    %     addline(dio,1:16,'in'); %we now examine the parallel port for the current values pins = getvalue(dio);
    %
    %
    %     pins = getvalue(dio);
    %
    %     if pins(11) == 1
    %
    %         error('The trigger from the fMRI is already firing. Check the Parallel Ribbon Cable is secure.')
    %
    %     else
    %
    %         while pins(11) == 0
    %
    %             pins = getvalue(dio);
    %
    %             if(pins(11))
    %
    %                 disp('The Trigger has transitioned from low to high! We can continue with the experiment!');
    %
    %                 break
    %
    %             end
    %
    %         end
    %
    %     endt
    %     disp('Triggered....');
    %% Task
    trialtime = GetSecs;
    
    for trial = 1:numtrials
        disp('trials started')
        %     PsychPortAudio('FillBuffer', pahandle, wavfiles.move');
        PsychPortAudio('FillBuffer', pahandle, [wavfiles.move(:,1) wavfiles.move(:,2)]'); % Dagmar edit. PsychPortAudio('FillBuffer', pahandle, [move(:,1) move(:,2)]')
        movetime = GetSecs;
        PsychPortAudio('Start',pahandle,repetitions,0); % plays 'move'
        disp('MOVE!') %added a display line for checking the move command worked
        %     play(moveAP);
        log_time{1,logid} = 'move';
        log_time{2,logid} = movetime;
        logid = logid+1;
        
        %schedule for beeps
        betweenBeepsTime = randsample(beepTimes, numbeeps-1); % this randomises the order of the inter-beep interval
        beeptimes = 1 + [0 cumsum(betweenBeepsTime)];
        beeptimes = beeptimes + GetSecs;
        thisbeep = 1;
        
        % so it empties the motion tracking data every time
        motiontracking = zeros(2, movelength/sampleTime);
        motionid = 1;
        maxdata = length (motiontracking);
        
        % motion recording loop
        keep_going = true;
        startTime = GetSecs; %start of recording
        nextTime = startTime;
        pistont = startTime;
        while keep_going % run until time out or keyboard is hit
            [x, y ] = WinJoystickMex(0);
            sampletiming = GetSecs;
            motiontracking(1,motionid) = x;
            motiontracking(2,motionid) = y;
            motiontracking(3,motionid) = sampletiming;
            motionid = motionid+1;
            
            if thisbeep > length(beeptimes)
                % do nothing
                
            elseif GetSecs >= beeptimes(thisbeep)
                PsychPortAudio('FillBuffer', pahandle, [myBeep; myBeep]);
                beeptime = GetSecs;
                pistont = beeptimes(thisbeep);% Stores time that piston extends for use later (line254)
%		Add code to set U3 output to logic 1 DMc
	        ljudObj.eDO(ljhandle, U3channel, U3stateOne); %moves piston to extended position

                PsychPortAudio('Start',pahandle, repetitions, startCue, waitForDeviceStart);
                %log timming
                log_time{1,logid} = 'beeps';
                log_time{2,logid} = beeptime;
                logid = logid+1;
                thisbeep = thisbeep+1;
            end
%             if KbCheck
%                 keep_going = false;
%                 fprintf('...aborted\n');
%                  fprintf(logfile,' trial aborted\n');
%                 Snd('Play',MakeBeep(200,0.5));
%                 break;
%             end
            
            if motionid > maxdata
                keep_going = false;
            end
if GetSecs >= pistont+0.5 %DMc looks to see if current time is after time piston activated plus 0.5 seconds
    
%		Add code to reset output of U3 to logic 0 DMc
		ljudObj.eDO(ljhandle, U3channel, U3stateZero);% moves piston back to start position
        % bit inefficient as sends zero out every loop until next piston
        % movement - would be more efficient to set position flag on piston
        % and only check when piston extended.
end
            nextTime = nextTime+sampleTime;  % ???? DMc sampletime is only 1/1200sec
            WaitSecs('untiltime',nextTime);
        end
        save(sprintf('%s%s_%02d_motiondata.mat',subjname,session,trial),'motiontracking')
        
        %     PsychPortAudio('FillBuffer', pahandle, wavfiles.relax');
        PsychPortAudio('FillBuffer', pahandle, [wavfiles.relax(:,1) wavfiles.relax(:,2)]'); %Dagmar edit. PsychPortAudio('FillBuffer', pahandle, [relax(:,1) relax(:,2)]');
        relaxtime = GetSecs;
        PsychPortAudio('Start',pahandle,repetitions,0); % plays 'move
        disp('RELAX!') %added a display line for checking the move command worked
        log_time{1,logid} = 'relax';
        log_time{2,logid} = relaxtime;
        logid = logid+1;
        WaitSecs('untiltime',relaxtime + relaxlength);
        
        
    end
    
    %% save logs
    allonsets = cat(2,log_time{2,:});
    allonsets = allonsets - trialtime;
    beepscommand = strcmp('beeps',log_time(1,:)); %editted on April 20th
    movecommand = strcmp('move',log_time(1,:));
    relaxcommand = strcmp('relax',log_time(1,:));
    moveonsets = allonsets(movecommand);
    relaxonsets = allonsets(relaxcommand);
    beepsonsets = allonsets(beepscommand); %editted on April 20th
    block1onsets = beepsonsets(:,1:7) - moveonsets(:,1); %editted on April 20th
    block2onsets = beepsonsets(:,8:14) - moveonsets(:,2); %editted on April 20th
    block3onsets = beepsonsets(:,15:21) - moveonsets(:,3); %editted on April 20th
    block4onsets = beepsonsets(:,22:28) - moveonsets(:,4); %editted on April 20th
    block5onsets = beepsonsets(:,29:35) - moveonsets(:,5); %editted on April 20th
    block6onsets = beepsonsets(:,36:42) - moveonsets(:,6); %editted on April 20th
    block7onsets = beepsonsets(:,43:49) - moveonsets(:,7); %editted on April 20th
    block8onsets = beepsonsets(:,50:56) - moveonsets(:,8); %editted on April 20th
    save([subjname, session, '_log.mat'],'log_time','trialtime');
    save([subjname, session, '_allonsets.mat'],'allonsets');
    save([subjname, session, '_onsets4spm.mat'],'moveonsets','relaxonsets');
    save([subjname, session, '_beepsonsets.mat'],'beepsonsets'); % editted on April 20th
    save([subjname, session, '_beeponsetbyblocks.mat'],'block1onsets','block2onsets','block3onsets','block4onsets','block5onsets','block6onsets','block7onsets','block8onsets');% editted on April 20th
    
    %% close things
    % Set the volume to half for this demo
    % PsychPortAudio('Volume', pahandle, 0.5);
    
    % Wait for stop of playback
    PsychPortAudio('Stop', pahandle, 1, 1);
    
    % Close the audio device
    PsychPortAudio('Close', pahandle);
    
    fprintf('Block finished...\n');
    sca
    
% catch
%     
%     % Wait for stop of playback
%     PsychPortAudio('Stop', pahandle, 1, 1);
%     
%     % Close the audio device
%     PsychPortAudio('Close', pahandle);
%     
%     disp('ERROR - safely removed audio')
%     
% end

