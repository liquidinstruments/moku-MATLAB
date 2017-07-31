ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuPhasemeter(ip);

% Configure the instrument
% Set the Channel 1 seed frequency to 10MHz and samplerate ~30Hz
m.set_initfreq(1, 10e6);
m.set_samplerate('slow');

% Restart the frequency-tracking loop on Channel 1
m.reacquire(1);

% Stop an existing log, if any, then start a new one
% 10sec single channel to CSV file on SD Card
m.stop_data_log();
m.start_data_log(10, 'true', 'true', 'true', 'csv');

% Wait for data log progress to reach 100%
progress = 0;
while(progress < 100)
    pause(1);
    progress = m.progress_data_log();
    disp("Progress " + progress + "%");
end

% Check the filename that the log was saved under
fname = m.data_log_filename();
disp("Log file completed: " + fname);

% Denote that we are done with the logging session
m.stop_data_log();