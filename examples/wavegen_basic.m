ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuWaveformGenerator(ip);

% Configure the instrument
% Generate an output 1.0Vpp 1MHz Sinewave on Channel 1
m.gen_sinewave(1, 1.0, 1e6);

% Generate a 1.0Vpp 2MHz Squarewave on Channel 2
% 0V offset, 30% Duty cycle, 10% Rise time, 10% Fall time, 0deg Phase
m.gen_squarewave(2, 1.0, 2e6, 0.0, 0.3, 0.1, 0.1, 0.0)

% Amplitude modulate the Channel 1 Sinewave with another internally-
% generated sinewave. 100% modulation depth at 10Hz.
m.gen_modulate(1, 'amplitude', 'internal', 1, 10)