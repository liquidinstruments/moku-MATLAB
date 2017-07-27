% Connect to your Moku and deploy the desired instrument
m = MokuDatalogger('192.168.69.230');

% Configure the instrument
% Set the samplerate to 10 Hz
m.set_samplerate(10);

% Stop any previous sessions
m.stop_stream_data();
% Start a 10sec dual-channel streaming session
m.start_stream_data(10,'true','true');

while 1   
    % Get 10 samples off the network at a time
    samples = m.get_stream_data(10);
    
    % Break out of the loop if we receive an empty cell array
    % This denotes the session has completed
    if iscell(samples)
        disp("Stream complete");
        break
    end

    disp(sprintf("Received: Channel 1 (%d smps), Channel 2 (%d smps)", ...
        length(samples(1,:)), length(samples(2,:))));
    % A short pause ensures this message will print with each loop
    pause(0.1);
end

% Denote that we are done with the data streaming session to clean up 
% device and network resources.
m.stop_stream_data();