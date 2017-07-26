% Connect to your Moku and deploy the desired instrument
m = moku('192.168.69.227', 'phasemeter');

% Configure the instrument
% Set the Channel 1 seed frequency to 10MHz and samplerate ~30Hz
mokuctl(m, 'set_initfreq', 1, 10e6);
mokuctl(m, 'set_samplerate', 'slow');

% Restart the frequency-tracking loop on Channel 1
mokuctl(m, 'reacquire', 1);

% Stop an existing log, if any, then start a new one
% 10sec single channel to CSV file on SD Card
mokuctl(m, 'stop_data_log');
mokuctl(m, 'start_data_log',{'duration',10,'use_sd','true','ch1','true', ...
    'ch2','false','filetype','csv'});


% Wait for data log progress to reach 100%
progress = 0;
while(progress < 100)
    pause(1);
    progress = mokuctl(m, 'progress_data_log');
    disp("Progress " + progress + "%");
end

% Check the filename that the log was saved under
fname = mokuctl(m, 'data_log_filename');
disp("Log file completed: " + fname);

% Denote that we are done with the logging session
mokuctl(m, 'stop_data_log');