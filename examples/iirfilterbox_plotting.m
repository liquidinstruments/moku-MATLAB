%% IIR Filter Box plotting example
%
% This example demonstrates how you can configure the IIR Filter Box
% with custom generated filter coefficients, and set up real-time 
% monitoring of the input and output signals.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Prepare the SOS filter coefficients
% Generate a high-pass Butterworth filter transfer function
N = 4;    % Order
Wp = 0.5; % Cutoff frequency (% Nyquist sample rate)
[B,A] = butter(N,Wp,'high');

% Moku:Lab implements a Second-Order-Stage (SOS) filter, so we need to
% transform the filter transfer function coefficients to SOS format.
[sos,g] = tf2sos(B,A);

% Mould the coefficients into the Moku:Lab "matrix" format. This is
% required to be a cell array with a single cell containing the "matrix". 
% Ensure "g" is a cell (not a single-element array). The remaining elements
% are 1x6 numeric arrays. 
filt_coeff = {{ {g},                ... % Overall gain
                sos(1,[4,1:3,5,6]), ... % [s_1, b_01, b_11, b_21, a_11, a_21]
                sos(2,[4,1:3,5,6]), ... % [s_2, b_02, b_12, b_22, a_12, a_22]
                [1,1,0,0,0,0],      ... % Ignore this stage (all-pass)
                [1,1,0,0,0,0]       }}; % Ignore this stage (all-pass)

%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuIIRFilterBox(ip);

%% Configure the instrument
m.set_frontend(1, 'fiftyr', 'true', 'atten', 'false', 'ac', 'false');
m.set_frontend(2, 'fiftyr', 'true', 'atten', 'false', 'ac', 'false');

% Both filters have the same coefficients, but the different sampling rates
% mean the resultant transfer functions will be different by a factor of
% 128 (the ratio of sampling rates).
m.set_filter(1, 'high', filt_coeff); % ~15.625 Smp/s
m.set_filter(2, 'low', filt_coeff);  % ~122 Smp/s

% Channel 1 solely filters Input 1
% Channel 2 solely filters Input 2
m.set_offset_gain(1, 'matrix_scalar_ch1', 1.0, 'matrix_scalar_ch2', 0.0);
m.set_offset_gain(2, 'matrix_scalar_ch1', 0.0, 'matrix_scalar_ch2', 1.0);

% Set up monitoring of the input and output of the second filter channel.
m.set_monitor('a','in1');
m.set_monitor('b','out1');

% Trigger on monitor channel 'a', rising edge, 0V
m.set_trigger('a','rising', 0);

% Set up the monitor timebase to be +-1usec
m.set_timebase(-1e-6,1e-6);

%% Set up plots
% Get initial data to set up plots
data = m.get_realtime_data();

% Set up the plots
figure
lh = plot(data.time, data.ch1, data.time, data.ch2);
xlabel(gca,'Time (sec)')
ylabel(gca,'Amplitude (V)')

%% Receive and plot new data frames
while 1
    data = m.get_realtime_data();
    set(lh(1),'XData',data.time,'YData',data.ch1);
    set(lh(2),'XData',data.time,'YData',data.ch2);
    axis tight
    pause(0.1)
end