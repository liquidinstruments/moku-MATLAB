ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuOscilloscope(ip);

% Configure the instrument
% Set the timebase to be +-1sec
m.set_timebase(-0.001,0.001);

% Get a single frame of hi-res data with a 10 sec timeout period
data = m.get_realtime_data('timeout',10);

% Print the time-voltage data for both channels
data.time
data.ch1
data.ch2