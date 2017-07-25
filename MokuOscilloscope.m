
classdef MokuOscilloscope < moku
    % Driver class for the Moku:Oscilloscope
    %
    % The following methods are available on this object:
    % commit: Apply all modified settings.
    % gen_off: Turn Waveform Generator output(s) off.
    % gen_rampwave: Generate a Ramp with the given parameters on the given channel.
    % gen_sinewave: Generate a Sine Wave with the given parameters on the given channel.
    % gen_squarewave: Generate a Square Wave with given parameters on the given channel.
    % get_data: Get full-resolution data from the instrument.
    % get_frontend: Get the analog frontend configuration.
    % get_realtime_data: Get downsampled data from the instrument with low latency.
    % get_samplerate: :return: The current instrument sample rate (Hz) 
    % set_defaults: Reset the Oscilloscope to sane defaults. 
    % set_frontend: Configures gain, coupling and termination for each channel.
    % set_precision_mode: Change aquisition mode between downsampling and decimation.
    % set_samplerate: Manually set the sample rate of the instrument.
    % set_source: Sets the source of the channel data to either the analog input or internally looped-back digital output.
    % set_timebase: Set the left- and right-hand span for the time axis.
    % set_trigger: Sets trigger source and parameters.
    % set_xmode: Set rendering mode for the horizontal axis.

    methods
        function obj = MokuOscilloscope(IpAddr)
            obj@moku(IpAddr, 'oscilloscope');
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
            % Turn Waveform Generator output(s) off.
            % 
            % The channel will be turned on when configuring the waveform type but can be turned off
            % using this function. If *ch* is None (the default), both channels will be turned off,
            % otherwise just the one specified by the argument.
            % 
            % :type ch: int; {1,2} or None
            % :param ch: Channel to turn off, or both.
            % 
            % :raises ValueError: invalid channel number
            % :raises ValueOutOfRangeException: if the channel number is invalid
            if isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'gen_off', ch);
        end

        function gen_rampwave(obj, ch, amplitude, frequency, offset, symmetry)
            % Generate a Ramp with the given parameters on the given channel.
            % 
            % This is a wrapper around the Square Wave generator, using the *riserate* and *fallrate*
            % parameters to form the ramp.
            % 
            % :type ch: int; {1,2}
            % :param ch: Channel on which to generate the wave
            % 
            % :type amplitude: float, volts
            % :param amplitude: Waveform peak-to-peak amplitude
            % 
            % :type frequency: float, hertz
            % :param frequency: Frequency of the wave
            % 
            % :type offset: float, volts
            % :param offset: DC offset applied to the waveform
            % 
            % :type symmetry: float, 0-1
            % :param symmetry: Fraction of the cycle rising.
            % 
            % :type phase: float, degrees 0-360
            % :param phase: Phase offset of the wave
            % 
            % :raises ValueError: invalid channel number
            % :raises ValueOutOfRangeException: invalid waveform parameters
            if isempty(frequency)
                frequency = 0;
            end
            if isempty(offset)
                offset = 0.5;
            end
            if isempty(symmetry)
                symmetry = 0.0;
            end

            mokuctl(obj, 'gen_rampwave', ch, amplitude, frequency, offset, symmetry);
        end

        function gen_sinewave(obj, ch, amplitude, frequency, offset)
            % Generate a Sine Wave with the given parameters on the given channel.
            % 
            % :type ch: int; {1,2}
            % :param ch: Channel on which to generate the wave
            % 
            % :type amplitude: float, [0.0,2.0] Vpp
            % :param amplitude: Waveform peak-to-peak amplitude
            % 
            % :type frequency: float, [0,250e6] Hz
            % :param frequency: Frequency of the wave
            % 
            % :type offset: float, [-1.0,1.0] Volts
            % :param offset: DC offset applied to the waveform
            % 
            % :type phase: float, [0-360] degrees
            % :param phase: Phase offset of the wave
            % 
            % :raises ValueError: if the channel number is invalid
            % :raises ValueOutOfRangeException: if wave parameters are out of range
            if isempty(frequency)
                frequency = 0;
            end
            if isempty(offset)
                offset = 0.0;
            end

            mokuctl(obj, 'gen_sinewave', ch, amplitude, frequency, offset);
        end

        function gen_squarewave(obj, ch, amplitude, frequency, offset, duty, risetime, falltime)
            % Generate a Square Wave with given parameters on the given channel.
            % 
            % :type ch: int; {1,2}
            % :param ch: Channel on which to generate the wave
            % 
            % :type amplitude: float, volts
            % :param amplitude: Waveform peak-to-peak amplitude
            % 
            % :type frequency: float, hertz
            % :param frequency: Frequency of the wave
            % 
            % :type offset: float, volts
            % :param offset: DC offset applied to the waveform
            % 
            % :type duty: float, 0-1
            % :param duty: Fractional duty cycle
            % 
            % :type risetime: float, 0-1
            % :param risetime: Fraction of a cycle taken for the waveform to rise
            % 
            % :type falltime: float 0-1
            % :param falltime: Fraction of a cycle taken for the waveform to fall
            % 
            % :type phase: float, degrees 0-360
            % :param phase: Phase offset of the wave
            % 
            % :raises ValueError: invalid channel number
            % :raises ValueOutOfRangeException: input parameters out of range or incompatible with one another
            if isempty(frequency)
                frequency = 0;
            end
            if isempty(offset)
                offset = 0.5;
            end
            if isempty(duty)
                duty = 0;
            end
            if isempty(risetime)
                risetime = 0;
            end
            if isempty(falltime)
                falltime = 0.0;
            end

            mokuctl(obj, 'gen_squarewave', ch, amplitude, frequency, offset, duty, risetime, falltime);
        end

        function get_data(obj, timeout, wait)
            % Get full-resolution data from the instrument.
            % 
            % This will pause the instrument and download the entire contents of the instrument's 
            % internal memory. This may include slightly more data than the instrument is set up 
            % to record due to rounding of some parameters in the instrument.
            % 
            % All settings must be committed before you call this function. If *pymoku.autocommit=True*
            % (the default) then this will always be true, otherwise you will need to have called
            % :any:`commit` first.
            % 
            % The download process may take a second or so to complete. If you require high rate
            % data, e.g. for rendering a plot, see `get_realtime_data`.
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
            if isempty(timeout)
                timeout = 'nil';
            end
            if isempty(wait)
                wait = 'true';
            end

            mokuctl(obj, 'get_data', timeout, wait);
        end

        function get_frontend(obj)
            % Get the analog frontend configuration.
            % 
            % :type channel: int; {1,2}
            % :param channel: Channel for which the relay settings are being retrieved
            % 
            % :return: Array of bool with the front end configuration of channels
            %         - [0] 50 Ohm
            %         - [1] 10xAttenuation
            %         - [2] AC Coupling

            mokuctl(obj, 'get_frontend');
        end

        function get_realtime_data(obj, timeout, wait)
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
            if isempty(timeout)
                timeout = 'nil';
            end
            if isempty(wait)
                wait = 'true';
            end

            mokuctl(obj, 'get_realtime_data', timeout, wait);
        end

        function get_samplerate(obj)
            % :return: The current instrument sample rate (Hz) 

            mokuctl(obj, 'get_samplerate');
        end

        function set_defaults(obj)
            % Reset the Oscilloscope to sane defaults. 

            mokuctl(obj, 'set_defaults');
        end

        function set_frontend(obj, channel, fiftyr, atten)
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
            if isempty(channel)
                channel = 'true';
            end
            if isempty(fiftyr)
                fiftyr = 'false';
            end
            if isempty(atten)
                atten = 'false';
            end

            mokuctl(obj, 'set_frontend', channel, fiftyr, atten);
        end

        function set_precision_mode(obj)
            % Change aquisition mode between downsampling and decimation.
            % Precision mode, a.k.a Decimation, samples at full rate and applies a low-pass filter to the data. This improves
            % precision. Normal mode works by direct downsampling, throwing away points it doesn't need.
            % 
            % Precision mode canot be enabled if the trigger hysteresis has been explicitly set to an explicit, non-zero voltage.
            % See :any:`set_trigger <pymoku.instruments.Oscilloscope.set_trigger`.
            % 
            % :param state: Select Precision Mode
            % :type state: bool

            mokuctl(obj, 'set_precision_mode');
        end

        function set_samplerate(obj, samplerate)
            % Manually set the sample rate of the instrument.
            % 
            % The sample rate is automatically calculated and set in :any:`set_timebase`.
            % 
            % This interface allows you to specify the rate at which data is sampled, and set
            % a trigger offset in number of samples. This interface is useful for datalogging and capturing
            % of data frames.
            % 
            % :type samplerate: float; *0 < samplerate <= 500 Msmp/s*
            % :param samplerate: Target samples per second. Will get rounded to the nearest allowable unit.
            % 
            % :type trigger_offset: int; *-2^16 < trigger_offset < 2^31 *
            % :param trigger_offset: Number of samples before (-) or after (+) the trigger point to start capturing.
            % 
            % :raises ValueOutOfRangeException: if either parameter is out of range.
            if isempty(samplerate)
                samplerate = 0;
            end

            mokuctl(obj, 'set_samplerate', samplerate);
        end

        function set_source(obj, ch, source)
            % Sets the source of the channel data to either the analog input or internally looped-back digital output.
            % 
            % This feature allows the user to preview the Waveform Generator outputs.
            % 
            % :type ch: int; {1,2}
            % :param ch: Channel Number
            % 
            % :type source: string, {'in','out'}
            % :param source: Where the specified channel should source data from (either the input or internally looped back output)
            % 
            % :type lmode: string, {'clip','round'}
            % :param lmode: DAC Loopback mode (ignored 'in' sources)
            if isempty(source)
                source = 'round';
            end

            mokuctl(obj, 'set_source', ch, source);
        end

        function set_timebase(obj, t1)
            % Set the left- and right-hand span for the time axis.
            % Units are seconds relative to the trigger point.
            % 
            % :type t1: float
            % :param t1:
            %         Time, in seconds, from the trigger point to the left of screen. This may be negative (trigger on-screen)
            %         or positive (trigger off the left of screen).
            % 
            % :type t2: float
            % :param t2: As *t1* but to the right of screen.
            % 
            % :raises InvalidConfigurationException: if the timebase is backwards or zero.

            mokuctl(obj, 'set_timebase', t1);
        end

        function set_trigger(obj, source, edge, level, hysteresis, hf_reject)
            % Sets trigger source and parameters.
            % 
            % The hysteresis value changes behaviour based on aquisition mode, due to hardware limitations.  If the
            % Oscilloscope is in precision mode, hysteresis must be 0 or one of the strings 'auto' or 'noise'; an explicit,
            % non-zero value in volts can only be specified for normal aquisition (see
            % :any:`set_precision_mode <pymoku.instruments.Oscilloscope.set_precision_mode>`).  If hysteresis is 'auto' or
            % 'noise', a small value will be automatically calulated based on decimation. Values 'auto' and 'noise' are suitable
            % for high- and low-SNR signals respectively.
            % 
            % :type source: string, {'in1','in2','out1','out2'}
            % :param source: Trigger Source. May be either an input or output channel,
            %                                 allowing one to trigger off a synthesised waveform.
            % 
            % :type edge: string, {'rising','falling','both'}
            % :param edge: Which edge to trigger on.
            % 
            % :type level: float, [-10.0, 10.0] volts
            % :param level: Trigger level
            % 
            % :type hysteresis: bool
            % :param hysteresis: Enable Hysteresis around trigger point.
            % 
            % :type hf_reject: bool
            % :param hf_reject: Enable high-frequency noise rejection
            % 
            % :type mode: string, {'auto', 'normal'}
            % :param mode: Trigger mode.
            % 
            % .. note::
            %         Traditional Oscilloscopes have a "Single Trigger" mode that captures an event then
            %         pauses the instrument. In pymoku, there is no need to pause the instrument as you
            %         can simply choose to continue using the last captured frame.  That is, set trigger
            %         ``mode='normal'`` then retrieve a single frame using :any:`get_data <pymoku.instruments.Oscilloscope.get_data>`
            %         or :any:`get_realtime_data <pymoku.instruments.Oscilloscope.get_realtime_data>`
            %         with ``wait=True``.
            if isempty(level)
                level = 'false';
            end
            if isempty(hysteresis)
                hysteresis = 'false';
            end
            if isempty(hf_reject)
                hf_reject = 'auto';
            end

            mokuctl(obj, 'set_trigger', source, edge, level, hysteresis, hf_reject);
        end

        function set_xmode(obj)
            % Set rendering mode for the horizontal axis.
            % 
            % :type xmode: string, {'roll','sweep','fullframe'}
            % :param xmode:
            %         Respectively; Roll Mode (scrolling), Sweep Mode (normal oscilloscope trace sweeping across the screen)
            %         or Full Frame (like sweep, but waits for the frame to be completed).

            mokuctl(obj, 'set_xmode');
        end

    end
end
