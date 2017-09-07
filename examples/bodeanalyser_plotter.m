%% Plotting Bode Analyser Example
%
% This example demonstrates how you can generate output sweeps using the
% Bode Analyser instrument, and view transfer function data in real-time.
%
% (c) 2017 Liquid Instruments Pty. Ltd.
%
%% Connect to your Moku
ip = input('Please enter your Moku:Lab IP address: ', 's');

% Connect to your Moku and deploy the desired instrument
m = MokuBodeAnalyser(ip);

%% Configure the instrument
% Set output sweep amplitudes
m.set_output(1,0.5); % Channel 1, 0.5Vpp
m.set_output(2,0.5); % Channel 2, 0.5Vpp

% Set output sweep configuration
% 1MHz - 100MHz, 512 sweep points
% Logarithmic sweep ON
% 1msec averaging time, 1msec settling time
% 1 averaging cycle, 1 settling cycle
m.set_sweep('f_start', 1e6, 'f_end', 100e6, 'sweep_points', 512, ...
    'sweep_log', 'true', 'averaging_time', 1e-3, 'settling_time', 1e-3, ...
    'averaging_cycles', 1, 'settling_cycles', 1);

% Start continuous sweeping (single sweep OFF)
m.start_sweep('single','false');

%% Set up plots
% Get initial data to set up plots
data = m.get_data();

% Set up the plots
figure

magnitude_graph = subplot(2,1,1);
ms = semilogx(magnitude_graph, data.frequency,data.ch1.magnitude_dB, data.frequency, data.ch2.magnitude_dB);
xlabel(magnitude_graph,'Frequency (Hz)')
ylabel(magnitude_graph,'Magnitude (dB)')

phase_graph = subplot(2,1,2);
ps = semilogx(phase_graph, data.frequency, data.ch1.phase, data.frequency, data.ch2.phase);
xlabel(phase_graph,'Frequency (Hz)')
ylabel(phase_graph,'Phase (cyc)')

%% Receive and plot new data frames
while 1
    data = m.get_data();
    set(ms(1),'XData',data.frequency,'YData',data.ch1.magnitude_dB);
    set(ms(2),'XData',data.frequency,'YData',data.ch2.magnitude_dB);
    set(ps(1),'XData',data.frequency,'YData',data.ch1.phase);
    set(ps(2),'XData',data.frequency,'YData',data.ch2.phase);
    axis(magnitude_graph,'tight');
    axis(phase_graph,'tight');
    pause(0.1)
end
