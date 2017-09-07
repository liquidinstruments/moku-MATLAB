%% Livestream Datalogger Example
% 
% This example demonstrates how you can use the Datalogger to live-stream
% dual-channel voltage data over the network.
% 
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuDatalogger(ip);

%% Configure the instrument
% Set the samplerate to 10 Hz
m.set_samplerate(10);

%% Start network-streaming data
% Stop any previous sessions
m.stop_stream_data();
% Start a 10sec dual-channel streaming session
m.start_stream_data('duration',10,'ch1','true','ch2','true');

%% Receive samples
while 1   
    % Get 10 samples off the network at a time
    samples = m.get_stream_data('n',10);
    
    % Break out of the loop if we receive an empty cell array
    % This denotes the session has completed (works for dual-channel only)
    if iscell(samples)
        disp("Stream complete");
        break
    end

    disp(sprintf("Received: Channel 1 (%d smps), Channel 2 (%d smps)", ...
        length(samples(1,:)), length(samples(2,:))));
    % A short pause ensures this message will print with each loop
    pause(0.1);
end

%% Close the network-streaming session
% Denote that we are done with the data streaming session to clean up 
% device and network resources.
m.stop_stream_data();