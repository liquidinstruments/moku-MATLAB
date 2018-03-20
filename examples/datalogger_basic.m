%% Basic Datalogger Example
%
% This example demonstrates use of the Datalogger instrument to log
% time-series voltage data to a (Binary or CSV) file.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuDatalogger(ip);

%% Configure the instrument
% Set the samplerate to 100 Hz
m.set_samplerate(100);

%% Start data logging
% Stop an existing log (if any)
m.stop_data_log();
% Start a new 10-sec dual-channel CSV log to SD Card.
m.start_data_log('duration',10,'use_sd','false','ch1','true', ...
    'ch2','true','filetype','csv');

%% Track log progress
% Wait for data log progress to reach 100%
progress = 0;
while(progress < 100)
    pause(0.5);
    progress = m.progress_data_log();
    disp(['Progress ' num2str(progress) '%']);
end

% Check the filename that the log was saved under
fname = m.data_log_filename();
disp(['Log file completed: ' fname]);

%% Close the logging session
% Denote that we are done with the logging session
m.stop_data_log();
