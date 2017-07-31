% Connect to your Moku and deploy the desired instrument
m = MokuSpectrumAnalyser('192.168.69.230');

% Configure the instrument
% Set the frequency span from DC - 10MHz
m.set_span(0,100e6);

% Get the scan results
data = m.get_data();

% Print the results out
data.frequency
data.ch1
data.ch2
