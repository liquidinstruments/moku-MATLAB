% Connect to your Moku and deploy the desired instrument
m = moku('192.168.69.229', 'oscilloscope');

% Configure the instrument
% Set the timebase to be +-1sec
mokuctl(m, 'set_timebase', -0.001,0.001);

% Get a single frame of hi-res data with a 10 sec timeout period
data = mokuctl(m, 'get_realtime_data', {'timeout',10});

% Print the time-voltage data for both channels
data.time
data.ch1
data.ch2