
classdef MokuDatalogger < moku
    % Driver class for the Moku:Datalogger
    %
    % The following methods are available on this object:
    % commit: Apply all modified settings.
    % data_log_filename: Returns the current base filename of the logging session.
    % gen_off: Turn Waveform Generator output(s) off.
    % gen_rampwave: Generate a Ramp with the given parameters on the given channel.
    % gen_sinewave: Generate a Sine Wave with the given parameters on the given channel.
    % gen_squarewave: Generate a Square Wave with given parameters on the given channel.
    % get_frontend: Get the analog frontend configuration.
    % get_samplerate: :return: The current instrument sample rate 
    % get_stream_data: Get any new instrument samples that have arrived on the network.
    % get_timestep: Returns the expected time between streamed samples.
    % progress_data_log: Estimates progress of a logging session started by a `start_data_log` call.
    % set_defaults: Can be extended in implementations to set initial state 
    % set_frontend: Configures gain, coupling and termination for each channel.
    % set_precision_mode: Change aquisition mode between downsampling and decimation.
    % set_samplerate: Manually set the sample rate of the instrument.
    % set_source: Sets the source of the channel data to either the analog input or internally looped-back digital output.
    % start_data_log: Start logging instrument data to a file.
    % start_stream_data: Start streaming instrument data over the network.
    % stop_data_log: Stops the current instrument data logging session.
    % stop_stream_data: Stops instrument data being streamed over the network.
    % upload_data_log: Load most recently recorded data file from the Moku to the local PC.

    methods
        function obj = MokuDatalogger(IpAddr)
            obj@moku(IpAddr, 'datalogger');
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

        function data_log_filename(obj)
            % Returns the current base filename of the logging session.
            % 
            % The base filename doesn't include the file extension as multiple files might be
            % recorded simultaneously with different extensions.
            % 
            % :rtype: str
            % :returns: The file name of the current, or most recent, log file.
            mokuctl(obj, 'data_log_filename');
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

        function get_samplerate(obj)
            % :return: The current instrument sample rate 
            mokuctl(obj, 'get_samplerate');
        end

        function get_stream_data(obj, n, timeout)
            % Get any new instrument samples that have arrived on the network.
            % 
            % This returns a tuple containing two arrays (one per channel) of up to 'n' samples of instrument data.
            % If a channel is disabled, the corresponding array is empty. If there were less than 'n' samples
            % remaining for the session, then the arrays will contain this remaining amount of samples.
            % 
            % :type n: int
            % :param n: Number of samples to get off the network. Set this to '0' to get
            %         all currently available samples, or '-1' to wait on all samples of the currently
            %         running streaming session to be received.
            % :type timeout: float
            % :param timeout: Timeout in seconds
            % 
            % :rtype: tuple
            % :returns: ([CH1_DATA], [CH2_DATA])
            % 
            % :raises NoDataException: if the logging session has stopped
            % :raises FrameTimeout: if the timeout expired
            % :raises InvalidOperationException: if there is no streaming session running
            % :raises ValueOutOfRangeException: invalid input parameters
            if isempty(n)
                n = 0;
            end
            mokuctl(obj, 'get_stream_data', n, timeout);
        end

        function get_timestep(obj)
            % Returns the expected time between streamed samples.
            % 
            % This returns the inverse figure to `get_samplerate`. This form is more useful
            % for constructing time axes to support, for example, `get_stream_data`.
            % 
            % :rtype: float
            % :returns: Time between data samples in seconds.
            mokuctl(obj, 'get_timestep');
        end

        function progress_data_log(obj)
            % Estimates progress of a logging session started by a `start_data_log` call.
            % 
            % :rtype: float
            % :returns: [0.0-100.0] representing 0 - 100% completion of the current logging session.
            % Note that 100% is only returned when the session has completed, the progress may pause at 99% for a time
            % as internal buffers are flushed.
            % :raises: StreamException: if an error occurred with the current logging session.
            mokuctl(obj, 'progress_data_log');
        end

        function set_defaults(obj)
            % Can be extended in implementations to set initial state 
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
                channel = True;
            end
            if isempty(fiftyr)
                fiftyr = False;
            end
            if isempty(atten)
                atten = False;
            end
            mokuctl(obj, 'set_frontend', channel, fiftyr, atten);
        end

        function set_precision_mode(obj)
            % Change aquisition mode between downsampling and decimation.
            % Precision mode, a.k.a Decimation, samples at full rate and applies a low-pass filter to the data. This improves
            % precision. Normal mode works by direct downsampling, throwing away points it doesn't need.
            % 
            % :param state: Select Precision Mode
            % :type state: bool
            % 
            % :raises ValueError: if input parameter is invalid
            mokuctl(obj, 'set_precision_mode');
        end

        function set_samplerate(obj)
            % Manually set the sample rate of the instrument.
            % 
            % This interface allows you to specify the rate at which data is sampled.
            % 
            % .. note::
            %         The samplerate must be set to within the allowed range for your datalogging session type.
            %         See the Datalogger instrument tutorial for more details.
            % 
            % :type samplerate: float; *0 < samplerate < 500Msmp/s*
            % :param samplerate: Target samples per second. Will get rounded to the nearest unit.
            % 
            % :raises ValueOutOfRangeException: if samplerate is out of range.
            mokuctl(obj, 'set_samplerate');
        end

        function set_source(obj, ch, source)
            % Sets the source of the channel data to either the analog input or internally looped-back digital output.
            % 
            % This feature allows the user to capture the Waveform Generator outputs.
            % 
            % :type ch:  int; {1,2}
            % :param ch: Channel Number
            % 
            % :type source: string, {'in','out'}
            % :param source: Where the specified channel should source data from (either the input or internally looped back output)
            % 
            % :type lmode: string, {'clip','round'}
            % :param lmode: DAC Loopback mode (ignored 'in' sources)
            % 
            % :raises ValueOutOfRangeException: if the channel number is incorrect
            % :raises ValueError: if any of the string parameters are incorrect
            if isempty(source)
                source = round;
            end
            mokuctl(obj, 'set_source', ch, source);
        end

        function start_data_log(obj, duration, ch1, ch2, use_sd, filetype)
            % Start logging instrument data to a file.
            % 
            % Progress of the data log may be checked calling `progress_data_log`.
            % 
            % All outstanding settings must have been committed before starting the data log. This
            % will always be true if *pymoku.autocommit=True*, the default.
            % 
            % .. note:: The Moku's internal filesystem is volatile and will be wiped when the Moku is turned off.
            %         If you want your data logs to persist either save to SD card or move them to a permanent
            %         storage location prior to powering your Moku off. 
            % 
            % :type duration: float
            % :param duration: Log duration in seconds
            % :type ch1: bool
            % :param ch1: Enable streaming on Channel 1
            % :type ch2: bool
            % :param ch2: Enable streaming on Channel 2
            % :type use_sd: bool
            % :param use_sd: Whether to log to the SD card, else the internal Moku filesystem.
            % :type filetype: string
            % :param filetype: Log file type, one of {'csv','bin'} for CSV or Binary respectively.
            % 
            % :raises ValueError: if invalid channel enable parameter
            % :raises ValueOutOfRangeException: if duration is invalid
            if isempty(duration)
                duration = 10;
            end
            if isempty(ch1)
                ch1 = True;
            end
            if isempty(ch2)
                ch2 = True;
            end
            if isempty(use_sd)
                use_sd = True;
            end
            if isempty(filetype)
                filetype = csv;
            end
            mokuctl(obj, 'start_data_log', duration, ch1, ch2, use_sd, filetype);
        end

        function start_stream_data(obj, duration, ch1, ch2)
            % Start streaming instrument data over the network.
            % 
            % Samples being streamed can be retrieved by calls to `get_stream_data`.
            % 
            % All outstanding settings must have been committed before starting the stream. This
            % will always be true if *pymoku.autocommit=True*, the default.
            % 
            % :type duration: float
            % :param duration: Log duration in seconds
            % :type use_sd: bool
            % :type ch1: bool
            % :param ch1: Enable streaming on Channel 1
            % :type ch2: bool
            % :param ch2: Enable streaming on Channel 2
            % 
            % :raises ValueError: if invalid channel enable parameter
            % :raises ValueOutOfRangeException: if duration is invalid
            if isempty(duration)
                duration = 10;
            end
            if isempty(ch1)
                ch1 = True;
            end
            if isempty(ch2)
                ch2 = True;
            end
            mokuctl(obj, 'start_stream_data', duration, ch1, ch2);
        end

        function stop_data_log(obj)
            % Stops the current instrument data logging session.
            % 
            % This must be called exactly once for every `start_data_log` call, even if the log terminated itself
            % due to timeout. Calling this function doesn't just stop the session (if it isn't already stopped),
            % but also resets error and transfer state, ready to start a new logging session.
            mokuctl(obj, 'stop_data_log');
        end

        function stop_stream_data(obj)
            % Stops instrument data being streamed over the network.
            % 
            % Should be called exactly once for every `start_stream_data` call, even if the streaming session
            % stopped itself due to timeout. Calling this function not only causes the stream to stop, but
            % also resets error and transfer state, ready to start a new streaming session.
            mokuctl(obj, 'stop_stream_data');
        end

        function upload_data_log(obj)
            % Load most recently recorded data file from the Moku to the local PC.
            % 
            % :raises NotDeployedException: if the instrument is not yet operational.
            % :raises InvalidOperationException: if no files are present.
            mokuctl(obj, 'upload_data_log');
        end

    end
end
