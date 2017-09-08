%% Plotting Phasemeter Example
%
%  This example demonstrates how you can configure the Phasemeter instrument
%  and stream dual-channel samples of the form [fs, f, count, phase, I, Q]. 
%  The signal amplitude is calculated using these samples, and plotted for 
%  real-time viewing.
% 
%  (c) 2017 Liquid Instruments Pty. Ltd.
% 
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuPhasemeter(ip);

%% Configure the instrument
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

%% Start network-streaming data
% Stop any previous streaming sessions
m.stop_stream_data();
% Start a 30sec dual-channel streaming session
m.start_stream_data('duration',30,'ch1','true','ch2','true');

%% Set up the plots
% Set up a phase and amplitude line plot per channel
% Plot up to 500 samples at a time
n_plot_points = 500;
ts = (-(n_plot_points-1):1:0)/m.get_samplerate();

% No samples as yet
phase_ch1 = NaN(1,n_plot_points);
phase_ch2 = NaN(1,n_plot_points);
amp_ch1 = NaN(1,n_plot_points);
amp_ch2 = NaN(1,n_plot_points);

figure;

subplot(2,1,1);
alh = plot(ts, amp_ch1, ts, amp_ch2);
ylabel(gca,'Amplitude (V)')
xlabel('Time (s)');
xlim([ts(1),ts(end)])

subplot(2,1,2);
plh = plot(ts, phase_ch1, ts, phase_ch2);
ylabel(gca,'Phase (cyc)');
xlabel('Time (s)');
xlim([ts(1),ts(end)]);


%% Receive and plot new samples
% Number of samples to retrieve at a time
n_samples = 10;

while 1   
    % Receive up to 'n' samples of data per channel
    samples = m.get_stream_data('n',n_samples);
     
    % This moulds the samples matrix into a readable format
    % for each channel.
    samples_ch1 = samples{1};
    samples_ch2 = samples{2};
    
    % Break out of the loop if we receive empty arrays
    % This denotes the session has completed
    if isempty(samples_ch1) || isempty(samples_ch2)
        disp('Stream complete')
        break
    end
    
    % Append phase data to the plot
    phase_ch1_new = samples_ch1(:,4)';
    phase_ch2_new = samples_ch2(:,4)';   
    phase_ch1 = [phase_ch1(length(phase_ch1_new)+1:end), phase_ch1_new];
    phase_ch2 = [phase_ch2(length(phase_ch2_new)+1:end), phase_ch2_new];
    
    % Append amplitude data to the plot
    % Amplitude is calculated as sqrt(I^2 + Q^2)
    amp_ch1_new = sqrt(samples_ch1(:,5).^2 + samples_ch1(:,6).^2)';
    amp_ch2_new = sqrt(samples_ch2(:,5).^2 + samples_ch2(:,6).^2)';
   	amp_ch1 = [amp_ch1(length(amp_ch1_new)+1:end), amp_ch1_new];
    amp_ch2 = [amp_ch2(length(amp_ch2_new)+1:end), amp_ch2_new];
    
    % Plot the updated phase for each channel
    set(plh(1),'YData',phase_ch1);
    set(plh(2),'YData',phase_ch2);
    set(alh(1),'YData',amp_ch1);
    set(alh(2),'YData',amp_ch2);
    pause(0.1)
end

%% Close the network-streaming session
% Denote that we are done with the data streaming session to clean up 
% device and network resources.
m.stop_stream_data();