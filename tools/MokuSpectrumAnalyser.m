
classdef MokuSpectrumAnalyser < moku
    % Driver class for the Moku:SpectrumAnalyser
    %
    % The following methods are available on this object:
    % commit: Apply all modified settings.
    % gen_off: Turn waveform generator output off.
    % gen_sinewave: Configure the output sinewaves on DAC channels
    % get_data: Get the latest sweep results.
    % get_frontend: Get the analog frontend configuration.
    % get_rbw: :return: The current resolution bandwidth (Hz) 
    % get_realtime_data: Get downsampled data from the instrument with low latency.
    % set_dbmscale: Configures the scale of the Spectrum Analyser amplitude data.
    % set_defaults: Reset the Spectrum Analyser to sane defaults. 
    % set_frontend: Configures gain, coupling and termination for each channel.
    % set_rbw: Set desired Resolution Bandwidth
    % set_span: Sets the frequency span to be analysed.
    % set_window: Set Window function

    methods
        function obj = MokuSpectrumAnalyser(IpAddr)
            obj@moku(IpAddr, 'spectrumanalyser');
        end

        function commit(obj)
            % Apply all modified settings.
            % 
            % .. note::
            % 
            %     If the `autocommit` feature has been turned off, this function can be used to manually apply any instrument
            %     settings to the Moku device. These instrument settings are those configured by calling all *set_* and *gen_* type
            %     functions. Manually calling this function allows you to atomically apply many instrument settings at once.

            mokuctl(obj, 'commit');
        end

        function gen_off(obj, ch)
            % Turn waveform generator output off.
            % 
            % If *ch* is specified, turn off only a single channel, otherwise turn off both.
            % 
            % :type ch: int; {1,2}
            % :param ch: Channel number to turn off (None, or leave blank, for both)firmware_is_compatible
            if nargin < 1 || isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'gen_off', ch);
        end

        function gen_sinewave(obj, ch, amp, freq)
            % Configure the output sinewaves on DAC channels
            % 
            % :type ch: int; {1,2}
            % :param ch: Output DAC channel to configure
            % 
            % :type amp: float, 0.0 - 2.0 volts
            % :param amp: Peak-to-peak output voltage
            % 
            % :type freq: float, 0 - 250e6 Hertz
            % :param freq: Frequency of output sinewave (ignored if sweep=True)
            % 
            % :type sweep: bool
            % :param sweep: Sweep current frequency span (ignores freq parameter if True). Defaults to False.
            % 
            % :raises ValueError: if the channel number is invalid
            % :raises ValueOutOfRangeException: if wave parameters are out of range
            if nargin < 3 || isempty(freq)
                freq = 'false';
            end
            if nargin < 2 || isempty(amp)
                amp = 'nil';
            end
            if nargin < 1 || isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'gen_sinewave', ch, amp, freq);
        end

        function ret = get_data(obj, timeout, wait)
            % Get the latest sweep results.
            % 
            % On SpectrumAnalyser this is an alias for :any:`get_realtime_data <pymoku.instruments.SpectrumAnalyser.get_realtime_data>` as the
            % output data is never downsampled from the sweep results.
            if nargin < 2 || isempty(wait)
                wait = 'true';
            end
            if nargin < 1 || isempty(timeout)
                timeout = 'nil';
            end

            ret = ...
            mokuctl(obj, 'get_data', timeout, wait);
        end

        function ret = get_frontend(obj)
            % Get the analog frontend configuration.
            % 
            % :type channel: int; {1,2}
            % :param channel: Channel for which the relay settings are being retrieved
            % 
            % :return: Array of bool with the front end configuration of channels
            %         - [0] 50 Ohm
            %         - [1] 10xAttenuation
            %         - [2] AC Coupling

            ret = ...
            mokuctl(obj, 'get_frontend');
        end

        function ret = get_rbw(obj)
            % :return: The current resolution bandwidth (Hz) 

            ret = ...
            mokuctl(obj, 'get_rbw');
        end

        function ret = get_realtime_data(obj, timeout, wait)
            % Get downsampled data from the instrument with low latency.
            % 
            % Returns a new :any:`InstrumentData` subclass (instrument-specific), containing
            % a version of the data that may have been downsampled from the original in order to
            % be transferred quickly.
            % 
            % This function always returns a new object at `framerate` (10Hz by default), whether
            % or not there is new data in that object. This can be verified by checking the return
            % object's *waveformid* parameter, which increments each time a new waveform is captured
            % internally.
            % 
            % The downsampled, low-latency nature of this data makes it particularly suitable for
            % plotting in real time. If you require high-accuracy, high-resolution data for analysis,
            % see `get_data`.
            % 
            % If the *wait* parameter is true (the default), this function will wait for any new
            % settings to be applied before returning. That is, if you have set a new timebase (for example),
            % calling this with *wait=True* will guarantee that the data returned has this new timebase. 
            % 
            % Note that if instrument configuration is changed, a trigger event must occur before data 
            % captured with that configuration set can become available. This can take an arbitrary amount 
            % of time. For this reason the *timeout* should be set appropriately.
            % 
            % :type timeout: float
            % :param timeout: Maximum time to wait for new data, or *None* for indefinite.
            % 
            % :type wait: bool
            % :param wait: If *true* (default), waits for a new waveform to be captured with the most
            %         recently-applied settings, otherwise just return the most recently captured valid data.
            % 
            % :return: :any:`InstrumentData` subclass, specific to the instrument.
            if nargin < 2 || isempty(wait)
                wait = 'true';
            end
            if nargin < 1 || isempty(timeout)
                timeout = 'nil';
            end

            ret = ...
            mokuctl(obj, 'get_realtime_data', timeout, wait);
        end

        function set_dbmscale(obj, dbm)
            % Configures the scale of the Spectrum Analyser amplitude data.
            % This can be either power in dBm, or RMS Voltage.
            % 
            % :type dbm: bool
            % :param dbm: Enable dBm scale
            if nargin < 1 || isempty(dbm)
                dbm = 'true';
            end

            mokuctl(obj, 'set_dbmscale', dbm);
        end

        function set_defaults(obj)
            % Reset the Spectrum Analyser to sane defaults. 

            mokuctl(obj, 'set_defaults');
        end

        function ret = set_frontend(obj, channel, fiftyr, atten)
            % Configures gain, coupling and termination for each channel.
            % 
            % :type channel: int; {1,2}
            % :param channel: Channel to which the settings should be applied
            % 
            % :type fiftyr: bool
            % :param fiftyr: 50Ohm termination; default is 1MOhm.
            % 
            % :type atten: bool
            % :param atten: Turn on 10x attenuation. Changes the dynamic range between 1Vpp and 10Vpp.
            % 
            % :type ac: bool
            % :param ac: AC-couple; default DC.
            if nargin < 3 || isempty(atten)
                atten = 'false';
            end
            if nargin < 2 || isempty(fiftyr)
                fiftyr = 'false';
            end
            if nargin < 1 || isempty(channel)
                channel = 'true';
            end

            ret = ...
            mokuctl(obj, 'set_frontend', channel, fiftyr, atten);
        end

        function set_rbw(obj, rbw)
            % Set desired Resolution Bandwidth
            % 
            % Actual resolution bandwidth will be rounded to the nearest allowable unit
            % when settings are applied to the device.
            % 
            % :type rbw: float
            % :param rbw: Desired resolution bandwidth (Hz), or ``None`` for auto-mode
            % 
            % :raises ValueError: if the RBW is not positive-definite or *None*
            if nargin < 1 || isempty(rbw)
                rbw = 'nil';
            end

            mokuctl(obj, 'set_rbw', rbw);
        end

        function set_span(obj, f1)
            % Sets the frequency span to be analysed.
            % 
            % Rounding and quantization in the instrument limits the range of spans for which a full set of 1024
            % data points can be calculated. This means that the resultant number of data points in
            % :any:`SpectrumData` frames will vary with the set span. Note however that the associated frequencies are 
            % given with the frame containing the data.
            % 
            % :type f1: float
            % :param f1: Left-most frequency (Hz)
            % :type f2: float
            % :param f2: Right-most frequency (Hz)
            % 
            % :raises InvalidConfigurationException: if the span is not positive-definite.
            if nargin < 1 || isempty(f1)
                f1 = 'nil';
            end

            mokuctl(obj, 'set_span', f1);
        end

        function set_window(obj)
            % Set Window function
            % 
            % :type window: string, {'blackman-harris','flattop','hanning','none'}
            % :param window: Window Function

            mokuctl(obj, 'set_window');
        end

    end
end
