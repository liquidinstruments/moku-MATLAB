ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuSpectrumAnalyser(ip);

% Configure the instrument
% Set amplitude scale to dBm
m.set_dbmscale('true');

% Set DC - 70MHz span
m.set_span(0,70e6);

% Auto mode
m.set_rbw('');

% Generate swept 1.0Vpp Sinewave on Channel 1
m.gen_sinewave(1,1.0,0,'true');
% Generate 0.5Vpp 20MHz Sinewave on Channel 2
m.gen_sinewave(2,0.5,20e6,'false');

% Configure the ADC inputs to be 50Ohm impedance
m.set_frontend(1, 'true');
m.set_frontend(2, 'true');

% Get initial data to set up plots
data = m.get_data();

% Set up the plots
figure
lh = plot(data.frequency, data.ch1, data.frequency, data.ch2);
xlabel(gca,'Time (sec)')
if data.dbm
    ylabel(gca,'Amplitude (dBm)')
else
    ylabel(gca,'Amplitude (V)')
end

% Continuously update plotted data
while 1
    data = m.get_realtime_data();
    set(lh(1),'XData',data.frequency,'YData',data.ch1);
    set(lh(2),'XData',data.frequency,'YData',data.ch2);
    axis tight
    pause(0.1)
end
