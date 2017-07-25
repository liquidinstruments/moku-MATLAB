
classdef MokuBodeAnalyser < moku
    % Driver class for the Moku:BodeAnalyser
    %
    % The following methods are available on this object:
    % commit: Apply all modified settings.
    % gen_off: Turn off the output sweep.
    % get_data: Get current sweep data.
    % get_frontend: Get the analog frontend configuration.
    % get_realtime_data: Get downsampled data from the instrument with low latency.
    % set_defaults: Reset the Bode Analyser to sane defaults 
    % set_frontend: Configures gain, coupling and termination for each channel.
    % set_output: Set the output sweep amplitude.
    % set_sweep: Set the output sweep parameters
    % start_sweep: Start sweeping
    % stop_sweep: Stop sweeping. 

    methods
        function obj = MokuBodeAnalyser(IpAddr)
            obj@moku(IpAddr, 'bodeanalyser');
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
            % Turn off the output sweep.
            % 
            % If *ch* is specified, turn off only a single channel, otherwise turn off both.
            % 
            % :type ch: int; {1,2}
            % :param ch: Channel number to turn off (None, or leave blank, for both)
            if isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'gen_off', ch);
        end

        function get_data(obj, timeout, wait)
            % Get current sweep data.
            % In the BodeAnalyser this is an alias for ``get_realtime_data`` as the data
            % is never downsampled. 
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

        function set_defaults(obj)
            % Reset the Bode Analyser to sane defaults 

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

        function set_output(obj, ch)
            % Set the output sweep amplitude.
            % 
            % .. note::
            %         Ensure that the output amplitude is set so as to not saturate the inputs.
            %         Inputs are limited to 1.0Vpp with attenuation turned off.
            % 
            % :param ch: int; {1,2}
            % :type ch: Output channel
            % 
            % :param amplitude: float; [0.0,2.0] Vpp
            % :type amplitude: Sweep amplitude

            mokuctl(obj, 'set_output', ch);
        end

        function set_sweep(obj, f_start, f_end, sweep_points, sweep_log, averaging_time, settling_time, averaging_cycles, settling_cycles)
            % Set the output sweep parameters
            % 
            % :type f_start: int; 1 <= f_start <= 125e6 Hz
            % :param f_start: Sweep start frequency
            % 
            % :type f_end: int; 1 <= f_end <= 125e6 Hz
            % :param f_end: Sweep end frequency
            % 
            % :type sweep_points: int; 32 <= sweep_points <= 512
            % :param sweep_points: Number of points in the sweep (rounded to nearest power of 2).
            % 
            % :type sweep_log: bool
            % :param sweep_log: Enable logarithmic frequency sweep scale.
            % 
            % :type averaging_time: float; sec
            % :param averaging_time: Minimum averaging time per sweep point.
            % 
            % :type settling_time: float; sec
            % :param settling_time: Minimum setting time per sweep point.
            % 
            % :type averaging_cycles: int; cycles
            % :param averaging_cycles: Minimum averaging cycles per sweep point.
            % 
            % :type settling_cycles: int; cycles
            % :param settling_cycles: Minimum settling cycles per sweep point.
            if isempty(f_start)
                f_start = 100;
            end
            if isempty(f_end)
                f_end = 125000000.0;
            end
            if isempty(sweep_points)
                sweep_points = 512;
            end
            if isempty(sweep_log)
                sweep_log = 'false';
            end
            if isempty(averaging_time)
                averaging_time = 0.001;
            end
            if isempty(settling_time)
                settling_time = 0.001;
            end
            if isempty(averaging_cycles)
                averaging_cycles = 1;
            end
            if isempty(settling_cycles)
                settling_cycles = 1;
            end

            mokuctl(obj, 'set_sweep', f_start, f_end, sweep_points, sweep_log, averaging_time, settling_time, averaging_cycles, settling_cycles);
        end

        function start_sweep(obj, single)
            % Start sweeping
            % 
            % :type single: bool
            % :param single: Enable single sweep (otherwise loop)
            if isempty(single)
                single = 'false';
            end

            mokuctl(obj, 'start_sweep', single);
        end

        function stop_sweep(obj)
            % Stop sweeping. 
            % 
            % This will stop new data frames from being received, so ensure you implement a timeout
            % on :any:`get_data<pymoku.instruments.BodeAnalyser.get_data>` calls. 

            mokuctl(obj, 'stop_sweep');
        end

    end
end
