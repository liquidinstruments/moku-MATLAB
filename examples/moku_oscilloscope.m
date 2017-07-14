% Connect to your Moku and deploy the desired instrument
m = moku('192.168.69.224', 'oscilloscope');

% Configure the instrument
mokuctl(m, 'set_timebase', -0.001,0.001);
mokuctl(m, 'set_precision_mode', 'true');
mokuctl(m, 'set_frontend', 1, 'true', 'false', 'false');
mokuctl(m, 'set_frontend', 2, 'true', 'false', 'false');
mokuctl(m, 'gen_sinewave', 1, 0.01, 1000);
mokuctl(m, 'gen_sinewave', 2, 0.25, 2500);

% Prepare the plotting window and line-plot handlers
figure;
hold on;
f = m.Frame
linehandlers = plot(f.time,f.ch1,f.time,f.ch2)

% Plotting loop
% Retrieves new voltage data and updates the plot for
% both channels.
while(1)
    f = m.Frame;
    set(linehandlers(1),'xdata',f.time,'ydata',f.ch1);
    set(linehandlers(2),'xdata',f.time,'ydata',f.ch2);
    pause(0.01); % 10msec pause between plot updates
end
    
    
