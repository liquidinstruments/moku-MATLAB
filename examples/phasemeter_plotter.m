ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuPhasemeter(ip);

% Configure the instrument
% Set the samplerate to ~30Hz
m.set_samplerate('slow');

% Set up signal generator outputs
% Channel 1 - 5MHz, 0.5Vpp Sinewave
% Channel 2 - 10MHz, 1.0Vpp Sinewave
m.gen_sinewave(1, 0.5, 5e6);
m.gen_sinewave(2, 1.0, 10e6);

% Restart the phase-lock loop for both channels, and automatically
% resolve the starting frequency (as opposed to manually setting a seed
% frequency)
m.auto_acquire()

% Stop any previous streaming sessions
m.stop_stream_data();
% Start a 30sec dual-channel streaming session
m.start_stream_data('duration',30,'use_sd','true','ch1','true',...
    'ch2','true');

% Set up the plots
n_plot_points = 500


data = m.get_stream_data('n',10)

% figure
% ch1 = NaN(1,n_plot_points);
% ch2 = NaN(1,n_plot_points);
% lh = plot(1:n_plot_points, ch1, 1:n_plot_points, ch2);
% ylabel(gca,'Amplitude (V)')
% 
% 
% while 1   
%     % Get 10 samples off the network at a time
%     samples = m.get_stream_data(10);
%     
%     % Break out of the loop if we receive an empty cell array
%     % This denotes the session has completed
%     if iscell(samples)
%         disp("Stream complete");
%         break
%     end
% 
%     disp(sprintf("Received: Channel 1 (%d smps), Channel 2 (%d smps)", ...
%         length(samples(1,:)), length(samples(2,:))));
%     % A short pause ensures this message will print with each loop
%     pause(0.1);
% end
% 
% % Denote that we are done with the data streaming session to clean up 
% % device and network resources.
% m.stop_stream_data();