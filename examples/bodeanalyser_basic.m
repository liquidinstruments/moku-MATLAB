ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuBodeAnalyser(ip);

% Configure the instrument
% Set the output sweep parameters and amplitudes
% 1MHz - 120MHz, Logarithmic sweep ON
m.set_sweep('f_start', 1e6, 'f_end', 120e6, 'sweep_log', 'true'); 
m.set_output(1,0.1); % Channel 1, 0.1Vpp
m.set_output(2,0.1); % Channel 2, 0.1Vpp

% Start a single sweep
m.start_sweep('single','true');

% Get the sweep data
data = m.get_data();

% Print the frequency, phase and magnitude data for Channel 1
data.frequency
data.ch1.magnitude_dB
data.ch1.phase