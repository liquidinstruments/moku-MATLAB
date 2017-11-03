%% Arbitrary Waveform Generator Basic Example
%
% This example demonstrates how you can generate and output arbitrary
% waveforms using the Arbitrary Waveform Generator instrument.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Prepare the waveforms
% Prepare a square waveform to be generated
t = linspace(0,1,100);
square_wave = sign(sin(2*pi*t));

% Prepare a more interesting waveform to be generated (note that the points
% must be normalized to range [-1,1])
not_square_wave = zeros(1,length(t));
for h=1:2:15
    not_square_wave = not_square_wave + (4/pi*h)*cos(2*pi*h*t);
end
not_square_wave = not_square_wave / max(not_square_wave);

%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuArbitraryWaveGen(ip);

%% Configure the instrument
% Load the waveforms to the device. This doesn't yet generate an output as
% we haven't set the amplitude, frequency etc; this only defines the shape.
m.write_lut(1, not_square_wave);
m.write_lut(2, square_wave);

% Generate the waveforms
% We have configurable on-device linear interpolation between LUT points.
% Normally interpolation is a good idea, but for sharp edges like square
% waves it will improve jitter but reduce rise-time. Configure whatever's
% suitable for your application.
m.gen_waveform(1, 1e-6, 1.0, 'interpolation','true');
m.gen_waveform(2, 1e-6, 1.0, 'interpolation','true');