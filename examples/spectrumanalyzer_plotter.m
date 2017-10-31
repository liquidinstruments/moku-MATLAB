%% Plotting Spectrum Analyzer Example
% 
%  This example demonstrates how you can configure the Spectrum Analyzer 
%  instrument and plot its spectrum data in real-time. It also shows how
%  you can use its embedded signal generator to generate a sweep and single
%  frequency waveform on the output channels.
% 
%  (c) 2017 Liquid Instruments Pty. Ltd.
% 
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuSpectrumAnalyzer(ip);

%% Configure the instrument
% Set amplitude scale to dBm
m.set_dbmscale('dbm','true');

% Set DC - 70MHz span
m.set_span(10e6,70e6);

% Auto mode
m.set_rbw();

% Generate swept 1.0Vpp Sinewave on Channel 1
m.gen_sinewave(1,1.0,0,'sweep','true');
% Generate 0.5Vpp 20MHz Sinewave on Channel 2
m.gen_sinewave(2,0.5,20e6,'sweep','false');

% Configure the ADC inputs to be 50Ohm impedance
m.set_frontend(1,'fiftyr','true');
m.set_frontend(2,'fiftyr','true');

%% Set up plots
% Get initial data to set up plots
data = m.get_data();

% Set up the plots
figure;
lh = plot(data.frequency, data.ch1, data.frequency, data.ch2);
axis tight;
xlabel(gca,'Frequency (Hz)');
if data.dbm
    ylabel(gca,'Amplitude (dBm)');
else
    ylabel(gca,'Amplitude (V)');
end

%% Receive and plot new data frames
while 1
    data = m.get_realtime_data();
    set(lh(1),'XData',data.frequency,'YData',data.ch1);
    set(lh(2),'XData',data.frequency,'YData',data.ch2);
    pause(0.1);
end
