%% Basic Lock-in Amplifier Example
%
% This example demonstrates how you can configure the lock-in amplifier
% instrument.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuLockInAmp(ip);

%% Configure the instrument
% Configure the two DAC outputs to provide the R (magnitude) and
% demodulation (local-oscillator in this case, see below) outputs. 
% Give the main ('R') channel 100x gain
m.set_outputs('R','demod');
m.set_gain('main',100);

% Demodulate at 1MHz (internally-generated) with a 100Hz, 2nd-order
% (6dB/octave) LPF.
m.set_demodulation('internal','frequency',1e6);
m.set_filter(100,2);