%% Basic Spectrum Analyser
%
% This example demonstrates how you can use the Spectrum Analyser instrument
% to retrieve a single spectrum data frame over a set frequency span.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuSpectrumAnalyser(ip);

%% Configure the instrument
% Set the frequency span from DC - 10MHz
m.set_span(0,100e6);

%% Get data
% Get a spectrum data frame
data = m.get_data();

% Print the results out
data.frequency
data.ch1
data.ch2
