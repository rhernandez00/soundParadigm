% This script runs a sound-based HD-DOT experiment. It puts together a group 
% of sounds of different categories in a randomized order into a single sound 
% file and plays it for a participant.
% The script communicates with the Lumo computer using the usb-to-serial-to-usb cable
% Follows the standard implementation (sends an 's' at the start of the
% acquisition and an 'e' when it finishes.

clear all %#ok<CLALL>

testing = true; %set as true for testing, set as false for real experiment
%Variables for theparadigm
initialBaseLine = 10; %time in seconds
finalBaseLine = 10; %time in seconds
interStimuliRange = [5,10]; %
soundsFs = 44100; %this is the expected Fs for all the sounds

%port used for the serial cable, you have to test first if it matches with
%the cable, you can see this in windows "device manager"
port = "COM6";

extensionUsed = 'wav'; %extension used in the sound files
soundFolder = '\sounds';


% User input
participantName = input('Participant name? ', 's');
typeOfRun = input('Type of run? ', 's');


%% This block generates the audio file
%generates a list of the sound files found in the folder
fileList = dir([pwd,soundFolder,'\*.',extensionUsed]);
fileList = {fileList.name};

if isempty(fileList)
    error(['no sound files with extension ', extensionUsed, ' found in: ',...
        pwd,soundFolder,'\', ', maybe you want to switch the folder']);
end

if ~exist([pwd,'\logs'])
    mkdir([pwd,'\logs']);
    disp('log folder doesnt exist, creating one');
end

variableNames = {'soundName','type'};
variableTypes = {'string','string'};

%T is a table that contains information about all the files in the folder
T = table('Size',[numel(fileList),numel(variableNames)],'VariableNames',variableNames,'VariableTypes',variableTypes);

fileTypeList = cell(1,numel(fileList));
for nFile = 1:numel(fileList) %populates T
    fileTypeList{nFile} = fileList{nFile}(1);
    T.soundName{nFile} = fileList{nFile};
    T.type{nFile} = fileTypeList{nFile};
end

%This part generates a random order and determines the intervals between
%stimuli
newOrder = 1:size(T,1);
newOrder = newOrder(randperm(numel(newOrder)));
intervals = interStimuliRange(1) + (interStimuliRange(2)-interStimuliRange(1))*rand(1,numel(newOrder));

timeLine = initialBaseLine;
fullSound = zeros(soundsFs*initialBaseLine,2); %fullSound is the variable where the entire sound will be stored

for nSound = 1:numel(newOrder)
    soundName = T.soundName{newOrder(nSound)};
    
    [soundVector,Fs] = audioread([pwd,soundFolder,'\',soundName]); %reads the sound
    if Fs ~= soundsFs
        warning(['sound file: ', soundName,' has a different Fs (',num2str(Fs),')',' resampling to match requested (',num2str(soundsFs),')']);
        soundVector = resample(soundVector,Fs,soundsFs);
    end
    duration = size(soundVector,1)/Fs; %calculates duration
    fullSound = [fullSound;soundVector];

    
    %records details of the sound to later generate the vectors
    complete(nSound).onset = timeLine; %#ok<*SAGROW> 
    complete(nSound).duration = duration; 
    complete(nSound).type = T.type{newOrder(nSound)};
    
    
    %checking if it reached the end of the list
    if nSound < numel(newOrder) %if it is not the end, it adds silence
        timeLine = timeLine + duration + intervals(nSound);
        silenceInterval = zeros(round(intervals(nSound)*soundsFs),2); %generates silence
        fullSound = [fullSound;silenceInterval]; %adds silence to the full sound
    end
end

%adds the final baseline
silenceInterval = zeros(round(finalBaseLine*soundsFs),2); %generates silence
fullSound = [fullSound;silenceInterval]; %adds silence to the full sound
totalDuration = size(fullSound,1)/Fs;

runFinished = false; %variable to mark if the run finished or not
%% This block prepates the computer to play the sound and prepares the serial port
PsychPortAudio('Verbosity', 0);
InitializePsychSound(0); %initializes the toolbox
%handle for the sound player
MySongHandle = PsychPortAudio('Open', [], [], 0, soundsFs, 2); 
% Fill the audio playback buffer with the audio data
PsychPortAudio('FillBuffer', MySongHandle, fullSound');

%Setting up the save file
% Getting current date and time
currentDateTime = datetime('now');
% Formatting the datetime object to only show time in hh:mm:ss format
formattedTime = datestr(currentDateTime, 'HHMM');

logName = [participantName,'_run',typeOfRun,'_',date,'_',formattedTime];
save([pwd,'\logs\',logName]); %saving temporal log

disp(['The total duration of the run will be: ',num2str(totalDuration), ' seconds']);
if ~testing
    s = serialport(port,9600,"Timeout",5);
else
    warning('%%%%%%%%% Testing selected, no signal is being sent %%%%%%%%%')
    warning('%%%%%%%%% Testing selected, no signal is being sent %%%%%%%%%')
    warning('%%%%%%%%% Testing selected, no signal is being sent %%%%%%%%%')
    warning('Press a button to continue')
    pause()
end


disp('Starting now')
if ~testing
    writeline(s,"s") %signal of sound ready
    disp('starting mark sent');
end
PsychPortAudio('Start', MySongHandle, 1, 0, 1); %starts the sound
pause(totalDuration)


if ~testing
    writeline(s,"e") %signal of sound ready
    disp('ending mark sent. Acquisition finished');
else
    disp('this was a test, no mark sent');
end
runFinished = true;

clearvars -except complete T participantName typeOfRun runFinished logName
save([pwd,'\logs\',logName]);