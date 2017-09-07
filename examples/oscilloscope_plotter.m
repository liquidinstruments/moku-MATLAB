%% Plotting Oscilloscope Example
% 
%  This example demonstrates how you can configure the Oscilloscope instrument,
%  and view triggered time-voltage data frames in real-time. 
% 
%  (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuOscilloscope(ip);

%% Configure the instrument
% Trigger on input Channel 1, rising edge, 0V with hysteresis ON
m.set_trigger('in1','rising',0.0,'hysteresis','true')

% View +- 1 second i.e. trigger in the centre
m.set_timebase(-0.001,0.001);

% Generate an output sinewave on Channel 2
% 0.5Vpp, 10Hz, 0V offset
m.gen_sinewave(2, 0.5, 1e3, 'offset', 0);

% Set the data source of Channel 1 to be Input 1
m.set_source(1,'in');

% Set the data source of Channel 2 to the generated output sinewave
m.set_source(2,'out');

%% Set up plots
% Get initial data to set up plots
data = m.get_realtime_data();

% Set up the plots
figure
lh = plot(data.time, data.ch1, data.time, data.ch2);
xlabel(gca,'Time (sec)')
ylabel(gca,'Amplitude (V)')

%% Receive and plot new data frames
while 1
    data = m.get_realtime_data();
    set(lh(1),'XData',data.time,'YData',data.ch1);
    set(lh(2),'XData',data.time,'YData',data.ch2);
    axis tight
    pause(0.1)
end
