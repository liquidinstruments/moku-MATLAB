
classdef MokuWaveformGenerator < moku
    % Driver class for the Moku:WaveformGenerator
    %
    % The following methods are available on this object:
    % commit: Apply all modified settings.
    % gen_modulate: Set up modulation on an output channel.
    % gen_modulate_off: Turn off modulation for the specified output channel.
    % gen_off: Turn Waveform Generator output(s) off.
    % gen_rampwave: Generate a Ramp with the given parameters on the given channel.
    % gen_sinewave: Generate a Sine Wave with the given parameters on the given channel.
    % gen_squarewave: Generate a Square Wave with given parameters on the given channel.
    % set_defaults: Set sane defaults.

    methods
        function obj = MokuWaveformGenerator(IpAddr)
            obj@moku(IpAddr, 'waveformgenerator');
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

        function gen_modulate(obj, ch, mtype, source, depth)
            % Set up modulation on an output channel.
            % 
            % :type ch: int; {1,2}
            % :param ch: Channel to modulate
            % 
            % :type mtype: string, {amplitude', 'frequency', 'phase'}
            % :param mtype:  Modulation type. Respectively Off, Amplitude, Frequency and Phase modulation.
            % 
            % :type source: string, {'internal', 'in', 'out'}
            % :param source: Modulation source. Respectively Internal Sinewave, associated input channel or opposite output channel.
            % 
            % :type depth: float 0-1, 0-125MHz or 0 - 360 deg
            % :param depth: Modulation depth (depends on modulation type): Fractional modulation depth, Frequency Deviation/Volt or Phase shift
            % 
            % :type frequency: float
            % :param frequency: Frequency of internally-generated sine wave modulation. This parameter is ignored if the source is set to ADC or DAC.
            % 
            % :raises ValueOutOfRangeException: if the channel number is invalid or modulation parameters can't be achieved
            if isempty(depth)
                depth = 0.0;
            end

            mokuctl(obj, 'gen_modulate', ch, mtype, source, depth);
        end

        function gen_modulate_off(obj, ch)
            % Turn off modulation for the specified output channel.
            % 
            % If *ch* is None (the default), both channels will be turned off,
            % otherwise just the one specified by the argument.
            % 
            % :type ch: int; {1,2} or None
            % :param ch: Output channel to turn modulation off.
            if isempty(ch)
                ch = 'nil';
            end

            mokuctl(obj, 'gen_modulate_off', ch);
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

        function set_defaults(obj)
            % Set sane defaults.
            % Defaults are outputs off, amplitudes and frequencies zero.

            mokuctl(obj, 'set_defaults');
        end

    end
end
