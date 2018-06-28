%% Plotting PID Controller Example
% This script demonstrates how to configure a single PID Controller in the
% PID Controller instrument by specifying its frequency response 
% characteristics. The input and output and output signal of this PID are 
% also plotted in real time.
%
% (c) 2018 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuPIDController(ip);

%% Configure the instrument
% Set the Channel 1 PID using frequency response characteristics
kp_dB = 10^(-10/20); % P = -10dB
i_xover = 100;       % I Crossover  = 100Hz
si_dB = 10^(10/20);  % I Saturation = 10dB
d_xover = 10000;     % D Crossover  = 10kHz
sd_dB = 10^(10/20);  % D Saturation = 10dB
m.set_by_frequency(1, 'kp', kp_dB,'i_xover',i_xover,'d_xover',d_xover, ...
    'si',si_dB,'sd',sd_dB);

% Set the embedded Oscilloscope timebase to +-1ms
m.set_timebase(-1e-3,1e-3);

% Set the monitored signals to PID 1 Input/Output
m.set_monitor('a', 'in1');
m.set_monitor('b', 'out1');

%% Set up plots
% Get initial data to set up plots
data = m.get_realtime_data();

% Set up the plots
figure

monitor_plot = subplot(1,1,1);
ms = plot(monitor_plot, data.time, data.ch1, data.time, data.ch2);
xlabel(monitor_plot,'Time (s)');
ylabel(monitor_plot,'Amplitude (V)');
ylim([-1,1]);

%% Receive and plot new data frames
while 1
    data = m.get_realtime_data();
    set(ms(1),'XData',data.time,'YData',data.ch1);
    set(ms(2),'XData',data.time,'YData',data.ch2);
    pause(0.1)
end