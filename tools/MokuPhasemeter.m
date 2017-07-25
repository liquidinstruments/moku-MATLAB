
classdef MokuPhasemeter < moku
    % Driver class for the Moku:Phasemeter
    %
    % The following methods are available on this object:
    % auto_acquire: Restarts the frequency tracking loop and phase counter for the specified channel,
    % commit: Apply all modified settings.
    % data_log_filename: Returns the current base filename of the logging session.
    % gen_off: Turn Waveform Generator output(s) off.
    % gen_sinewave: Generate a sinewave signal on the specified output channel
    % get_bandwidth: Get the bandwidth of the analog input channel
    % get_frontend: Get the analog frontend configuration.
    % get_initfreq: Reads the seed frequency register of the phase tracking loop
    % get_samplerate: Get the samplerate of the Phasemeter
    % get_stream_data: Get any new instrument samples that have arrived on the network.
    % get_timestep: Returns the expected time between streamed samples.
    % progress_data_log: Estimates progress of a logging session started by a `start_data_log` call.
    % reacquire: Restarts the frequency tracking loop and phase counter for the specified channel,
    % set_bandwidth: Set the bandwidth of the analog input channel
    % set_defaults: Can be extended in implementations to set initial state 
    % set_frontend: Configures gain, coupling and termination for each channel.
    % set_initfreq: Manually set the initial frequency of the designated channel
    % set_samplerate: Set the sample rate of the Phasemeter.
    % start_data_log: Start logging instrument data to a file.
    % start_stream_data: Start streaming instrument data over the network.
    % stop_data_log: Stops the current instrument data logging session.
    % stop_stream_data: Stops instrument data being streamed over the network.
    % upload_data_log: Load most recently recorded data file from the Moku to the local PC.

    methods
        function obj = MokuPhasemeter(IpAddr)
            obj@moku(IpAddr, 'phasemeter');
        end

        function auto_acquire(obj, ch)
            % Restarts the frequency tracking loop and phase counter for the specified channel,
            % or both if no channel is specified. The starting frequency of the channel's tracking loop is
            % automatically acquired, ignoring the currently set seed frequency by :any:`set_initfreq`.
            % 
            % To acquire using the set seed frequency, see :any:`reacquire`.
            % 
            % :type ch: int; *{1,2}*
            % :param ch: Channel number, or ``None`` for both
            % 
            % :raises ValueError: If the channel number is invalid.
            if nargin < 1 || isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'auto_acquire', ch);
        end

        function ret = commit(obj)
            % Apply all modified settings.
            % 
            % .. note::
            % 
            %     If the `autocommit` feature has been turned off, this function can be used to manually apply any instrument
            %     settings to the Moku device. These instrument settings are those configured by calling all *set_* and *gen_* type
            %     functions. Manually calling this function allows you to atomically apply many instrument settings at once.

            ret = ...
            mokuctl(obj, 'commit');
        end

        function ret = data_log_filename(obj)
            % Returns the current base filename of the logging session.
            % 
            % The base filename doesn't include the file extension as multiple files might be
            % recorded simultaneously with different extensions.
            % 
            % :rtype: str
            % :returns: The file name of the current, or most recent, log file.

            ret = ...
            mokuctl(obj, 'data_log_filename');
        end

        function gen_off(obj, ch)
            % Turn Waveform Generator output(s) off.
            % 
            % The channel will be turned on when configuring the waveform type but can be turned off
            % using this function. If *ch* is None (the default), both channels will be turned off,
            % otherwise just the one specified by the argument.
            % 
            % :type ch: int; {1,2} or *None*
            % :param ch: Channel to turn off or *None* for all channels
            % 
            % :raises ValueOutOfRangeException: if the channel number is invalid
            if nargin < 1 || isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'gen_off', ch);
        end

        function gen_sinewave(obj, ch, amplitude, frequency)
            % Generate a sinewave signal on the specified output channel
            % 
            % :type ch: int; {1,2}
            % :param ch: Channel number
            % :type amplitude: float; V
            % :param amplitude: Signal peak-to-peak amplitude
            % :type frequency: float; Hz
            % :param frequency: Frequency
            % :type phase: float; degrees
            % :param phase: Phase
            % 
            % :raises ValueError: if the channel number is invalid
            % :raises ValueOutOfRangeException: if wave parameters are out of range
            if nargin < 3 || isempty(frequency)
                frequency = 0.0;
            end
            if nargin < 2 || isempty(amplitude)
                amplitude = 'nil';
            end
            if nargin < 1 || isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'gen_sinewave', ch, amplitude, frequency);
        end

        function ret = get_bandwidth(obj)
            % Get the bandwidth of the analog input channel
            % 
            % :type ch: int; *{1,2}*
            % :param ch: Analog channel number to get bandwidth of.
            % 
            % :rtype: float; Hz
            % :return: Bandwidth
            % 
            % :raises ValueError: If the channel number is invalid.

            ret = ...
            mokuctl(obj, 'get_bandwidth');
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

        function ret = get_initfreq(obj)
            % Reads the seed frequency register of the phase tracking loop
            % Valid if auto acquire has not been used.
            % 
            % :type ch: int; *{1,2}*
            % :param ch: Channel number to read the initial frequency of.
            % :rtype: float; Hz
            % :return: Seed frequency
            % 
            % :raises ValueError: If the channel number is invalid.

            ret = ...
            mokuctl(obj, 'get_initfreq');
        end

        function ret = get_samplerate(obj)
            % Get the samplerate of the Phasemeter
            % 
            % :rtype: float; smp/s
            % :return: Samplerate

            ret = ...
            mokuctl(obj, 'get_samplerate');
        end

        function ret = get_stream_data(obj, n, timeout)
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
            if nargin < 2 || isempty(timeout)
                timeout = 'nil';
            end
            if nargin < 1 || isempty(n)
                n = 0;
            end

            ret = ...
            mokuctl(obj, 'get_stream_data', n, timeout);
        end

        function ret = get_timestep(obj)
            % Returns the expected time between streamed samples.
            % 
            % This returns the inverse figure to `get_samplerate`. This form is more useful
            % for constructing time axes to support, for example, `get_stream_data`.
            % 
            % :rtype: float
            % :returns: Time between data samples in seconds.

            ret = ...
            mokuctl(obj, 'get_timestep');
        end

        function ret = progress_data_log(obj)
            % Estimates progress of a logging session started by a `start_data_log` call.
            % 
            % :rtype: float
            % :returns: [0.0-100.0] representing 0 - 100% completion of the current logging session.
            % Note that 100% is only returned when the session has completed, the progress may pause at 99% for a time
            % as internal buffers are flushed.
            % :raises: StreamException: if an error occurred with the current logging session.

            ret = ...
            mokuctl(obj, 'progress_data_log');
        end

        function reacquire(obj, ch)
            % Restarts the frequency tracking loop and phase counter for the specified channel,
            % or both if no channel is specified. The starting frequency of the channel's tracking loop is
            % set to the seed frequency as set by calling :any:`set_initfreq`.
            % 
            % To automatically acquire a seed frequency, see :any:`auto_acquire`.
            % 
            % :type ch: int; *{1,2}*
            % :param ch: Channel number, or ``None`` for both
            % 
            % :raises ValueError: If the channel number is invalid.
            if nargin < 1 || isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'reacquire', ch);
        end

        function set_bandwidth(obj, ch)
            % Set the bandwidth of the analog input channel
            % 
            % :type ch: int; *{1,2}*
            % :param ch: Analog channel number to set bandwidth of.
            % 
            % :type bw: float; Hz
            % :param n: Desired bandwidth (will be rounded up to to the nearest multiple 10kHz * 2^N with N = [-6,0])
            % 
            % :raises ValueError: If the channel number is invalid.
            % :raises ValueOutOfRangeException: if the bandwidth is not positive-definite or the channel number is invalid
            if nargin < 1 || isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'set_bandwidth', ch);
        end

        function set_defaults(obj)
            % Can be extended in implementations to set initial state 

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

        function set_initfreq(obj, ch)
            % Manually set the initial frequency of the designated channel
            % 
            % :type ch: int; *{1,2}*
            % :param ch: Channel number to set the initial frequency of.
            % 
            % :type f: int; *2e6 < f < 200e6*
            % :param f: Initial locking frequency of the designated channel
            % 
            % :raises ValueError: If the channel number is invalid.
            % :raises ValueOutOfRangeException: If the frequency parameter is out of range.
            if nargin < 1 || isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'set_initfreq', ch);
        end

        function set_samplerate(obj)
            % Set the sample rate of the Phasemeter.
            % 
            % Options are {'slow','medium','fast'} corresponding to ~30smp/s, ~120smp/s and ~1.9kSmp/s.
            % 
            % :type samplerate: string, {'slow','medium','fast'}
            % :param samplerate: Desired sample rate
            % 
            % :raises ValueError: If samplerate parameter is invalid.

            mokuctl(obj, 'set_samplerate');
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
            if nargin < 5 || isempty(filetype)
                filetype = 'csv';
            end
            if nargin < 4 || isempty(use_sd)
                use_sd = 'true';
            end
            if nargin < 3 || isempty(ch2)
                ch2 = 'true';
            end
            if nargin < 2 || isempty(ch1)
                ch1 = 'true';
            end
            if nargin < 1 || isempty(duration)
                duration = 10;
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
            if nargin < 3 || isempty(ch2)
                ch2 = 'true';
            end
            if nargin < 2 || isempty(ch1)
                ch1 = 'true';
            end
            if nargin < 1 || isempty(duration)
                duration = 10;
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
