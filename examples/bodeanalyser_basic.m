% Connect to your Moku and deploy the desired instrument
m = MokuBodeAnalyser('192.168.69.230');

% Configure the instrument
% Set the output sweep parameters and amplitudes
m.set_sweep(1e6,120e6,'','true'); % 1MHz - 120MHz, Logarithmic sweep ON
m.set_output(1,0.1); % Channel 1, 0.1Vpp
m.set_output(2,0.1); % Channel 2, 0.1Vpp

% Start a single sweep
m.start_sweep('true');

% Get the sweep data
data = m.get_data();

% Print the frequency, phase and magnitude data for Channel 1
data.frequency
data.ch1.magnitude_dB
data.ch1.phase