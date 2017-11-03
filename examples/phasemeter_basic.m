%% Phasemeter File Logging Example
%
% This example demonstrates how you can configure the Phasemeter instrument
% and log single-channel phase and [I,Q] data to a CSV file for a 10 
% second duration.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuPhasemeter(ip);

%% Configure the instrument
% Set the Channel 1 seed frequency to 10MHz and samplerate ~30Hz
m.set_initfreq(1, 10e6);
m.set_samplerate('slow');

% Restart the frequency-tracking loop on Channel 1
m.reacquire('ch',1);

%% Start data logging
% Stop an existing log, if any, then start a new one
% 10sec single channel to CSV file on SD Card
m.stop_data_log();
m.start_data_log('duration', 10, 'use_sd', 'true', 'ch1', 'true', ...
    'ch2', 'false', 'filetype', 'csv');

%% Track log progress
% Wait for data log progress to reach 100%
progress = 0;
while(progress < 100)
    pause(1);
    progress = m.progress_data_log();
    disp(['Progress ' num2str(progress) '%']);
end

% Check the filename that the log was saved under
fname = m.data_log_filename();
disp(['Log file completed: ' fname]);

%% Close the logging session
% Denote that we are done with the logging session
m.stop_data_log();