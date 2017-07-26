% Connect to your Moku and deploy the desired instrument
m = moku('192.168.69.229', 'bodeanalyser');

% Configure the instrument
% Set the output sweep parameters and amplitudes
mokuctl(m, 'set_sweep',{'f_start',1e6,'f_end',120e6,'sweep_log','true'});
mokuctl(m, 'set_output', 1, 0.1); % Channel 1, 0.1Vpp
mokuctl(m, 'set_output', 2, 0.1); % Channel 2, 0.1Vpp

% Start a single sweep
mokuctl(m, 'start_sweep', {'single', 'true'});

% Wait a couple of seconds for the sweep to complete
pause(2);

% Get the sweep data
data = mokuctl(m, 'get_data');

% Plot the magnitude data for Channel 1
figure
plot(data.frequency,data.ch1.magnitude_dB);