%% Basic IIR Filter Box
%
% This example demonstrates how you can generate Chebyshev filter
% coefficients to configure the IIR Filter Box. It also shows how to
% retrieve signal monitor data.
%
% NOTE: This example requires installation of the MATLAB Signal Processing 
%       Toolbox to generate filter coefficients. The MokuIIRFilterBox can 
%       be used directly with pre-defined coefficients.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Prepare the SOS filter coefficients
% Generate a Chebyshev filter transfer function
N = 4;      % Order
R = 0.5;    % Passband peak-to-peak ripple (dB)
Wp = 0.1;   % Passband-edge frequency (% Nyquist sample rate)
[B,A] = cheby1(N,R,Wp);

% Moku:Lab implements a Second-Order-Stage (SOS) filter, so we need to
% transform the filter transfer function coefficients to SOS format.
[sos,g] = tf2sos(B,A);

% Mould the coefficients into the Moku:Lab "matrix" format. 
% Ensure "g" is a cell (not a single-element array). The remaining elements
% are 1x6 numeric arrays. 
filt_coeff = { {g},                 ... % Overall gain
                sos(1,[4,1:3,5,6]), ... % [s_1, b_01, b_11, b_21, a_11, a_21]
                sos(2,[4,1:3,5,6]), ... % [s_2, b_02, b_12, b_22, a_12, a_22]
                [1,1,0,0,0,0],      ... % Ignore this stage (all-pass)
                [1,1,0,0,0,0]       }; % Ignore this stage (all-pass)

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
m.set_filter(1, 'high', 'filter_coefficients', filt_coeff); % ~15.625 Smp/s
m.set_filter(2, 'low', 'filter_coefficients', filt_coeff);  % ~122 Smp/s

% 0.1V Offset for Channel 1
% Channel 2 acts on the sum of Input 1 and Input 2
m.set_offset_gain(1, 'input_offset', 0.1);
m.set_offset_gain(2, 'matrix_scalar_ch1', 0.5, 'matrix_scalar_ch2', 0.5);

% Set up monitoring of the input and output of the second filter channel.
m.set_monitor('a','in1');
m.set_monitor('b','out1');

% Set up the monitor timebase to be +-1usec
m.set_timebase(-1e-6,1e-6);

% Capture and print the time-domain signals being monitored
data = m.get_data();
data.time
data.ch1
data.ch2
