m = moku('192.168.69.241', 'oscilloscope');

mokuctl(m, 'set_timebase', -0.25, 0.25);
mokuctl(m, 'set_precision_mode', 1);
mokuctl(m, 'set_frontend', 1, 'false', 'false', 'true');
mokuctl(m, 'set_frontend', 2, 'false', 'false', 'true');

mokuctl(m, 'set_trigger', 'OSC_TRIG_CH1', 'OSC_EDGE_RISING', 0.5);
mokuctl(m, 'set_xmode', 'OSC_MODE_SWEEP');

mokuctl(m, 'commit');

try
    d = m.Frame;
    min(d.ch1)
    max(d.ch1)
catch
    disp('No data')
end

mokuctl(m, 'close');
