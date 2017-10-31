%% Basic Waveform Generator Example
%
% This example demonstrates how you can use the Waveform Generator
% instrument to generate an amplitude modulated sinewave on Channel 1, and
% un-modulated squarewave on Channel 2.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuWaveformGenerator(ip);

%% Configure the instrument
% Generate an output 1.0Vpp 1MHz Sinewave on Channel 1
m.gen_sinewave(1, 1.0, 1e6);

% Generate a 1.0Vpp 2MHz Squarewave on Channel 2
% 30% Duty cycle, 10% Rise time, 10% Fall time
m.gen_squarewave(2, 1.0, 2e6,'duty', 0.3,'risetime', 0.1,'falltime',0.1);

% Amplitude modulate the Channel 1 Sinewave with another internally-
% generated sinewave. 100% modulation depth at 10Hz.
m.gen_modulate(1, 'amplitude', 'internal', 1.0, 'frequency', 10);