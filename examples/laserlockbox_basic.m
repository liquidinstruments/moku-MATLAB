%% Basic Laser Lock Box Example
%
% This example demonstrates how you can configure the laser lock box
% instrument.
%
% (c) 2018 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuLaserLockBox(ip);

% set frontend
m.set_frontend(1, 'fiftyr', 'true', 'atten', 'false', 'ac', 'true');
m.set_frontend(2, 'fiftyr', 'true', 'atten', 'false', 'ac', 'true');

% set input gain
m.set_input_gain

% set local oscillator, auxiliary, and scan generators
m.set_local_oscillator('source', 'internal', 'frequency', 0, 'phase', 90, 'pll_auto_acq', false);
m.set_aux_sine('amplitude', 1.0, 'frequency', 100e3, 'phase', 0, 'sync_to_lo', false, 'output', 'none');
m.set_scan('frequency', 1e6, 'phase', 0, 'output', 'none', 'amplitude', 1.0, 'waveform', 'triangle');

% configure PIDs:
m.set_pid_by_gain(1, 'g', 1, 'kp', 1.0, 'ki', 0, 'kd', 0);
m.set_pid_by_gain(2, 'g', 1, 'kp', 1.0, 'ki', 0, 'kd', 0);

% set enables:
m.set_output_enables(1, 'en', true);
m.set_output_enables(2, 'en', true);
m.set_channel_pid_enables(1, 'en', true);
m.set_channel_pid_enables(2, 'en', true);
m.set_pid_enables(1, 'en', true);
m.set_pid_enables(2, 'en', true);

% set allowable output range
m.set_output_range(1, 1.0, -1.0);
m.set_output_range(2, 1.0, -1.0);

% set offsets
% m.set_offsets('pid_input', 0.1)
% m.set_offsets('out1', -0.1)
% m.set_offsets('out2', 0.2)

% configure second harmonic rejection low pass filter

% The following filter coefficients were generated using filter builder and implement a second order 
% butterworth lowpass filter with a 10 kHz corner frequency. 
coef_array = {{[1.0, 9.964476774385674e-05, 0.00019928953548771348, 9.964476774385674e-05, 1.9715674246898824, -0.97196600376085784], ...
			   [1.0, 1.0, 0.0, 0.0, 0.0, 0.0]}}
m.set_custom_filter(coef_array)

