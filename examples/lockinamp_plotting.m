%% Plotting Lock-In Amplifier Example
%
% This example demonstrates how you can configure the lock-in amplifier
% instrument and monitor the signals in real-time.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuLockInAmp(ip);

%% Configure the instrument
% Output a 1MHz sine wave but demodulate at a harmonic (2MHz)
m.set_demodulation('internal','frequency',2e6);
m.set_lo_output(1.0,1e6,0);

% Output the 'X' (I) signal and the local-oscillator sine wave on the two
% DAC channels. Configure a PID controller on the main 'X' output with a
% proportional gain of 10x, integrator cross-over of 10Hz and integrator
% saturation at 100x.
m.set_outputs('X','sine')
m.set_pid_by_frequency('main','kp',10,'i_xover',10,'si',100);

% Monitor the I and Q signals from the mixer, before filtering
m.set_monitor('A','I');
m.set_monitor('B','Q');

% Trigger on Monitor 'B' ('Q' signal), rising edge, 0V
m.set_trigger('B','rising', 0, 'hysteresis','false');

% View +-1usec, i.e. trigger in the centre
m.set_timebase(-1e-6,1e-6);

% Get initial data frame to set up the plot
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