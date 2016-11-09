import itertools
import pytest, time
from pymoku import Moku, FrameTimeout
from pymoku.instruments import *
from pymoku._oscilloscope import _OSC_SCREEN_WIDTH, _OSC_ADC_SMPS, OSC_TRIG_NORMAL, OSC_TRIG_SINGLE, OSC_TRIG_AUTO
from pymoku._siggen import SG_MOD_NONE, SG_MOD_AMPL, SG_MOD_PHASE, SG_MOD_FREQ, SG_MODSOURCE_INT, SG_MODSOURCE_ADC, SG_MODSOURCE_DAC, SG_WAVE_SINE, SG_WAVE_SQUARE, SG_WAVE_TRIANGLE, SG_WAVE_DC
import conftest
import numpy, math
from scipy.optimize import curve_fit
import scipy.signal
import matplotlib.pyplot as plt

OSC_MAX_TRIGRATE = 8e3 #Approximately 8kHz
OSC_AUTO_TRIGRATE = 20

# WAVEFORM TOLERANCES
# _P - Percentage
# _R - Relative
ADC_OFF_TOL_R = 0.100 # Volts
ADC_AMP_TOL_P = 0.1 # 10%
DAC_DUTY_TOL_R = 0.05 # 5% Duty cycle error

AC_COUPLE_CORNER_FREQ_1MO = 10*50
AC_COUPLE_CORNER_FREQ_50O = 5e6

# Assertion helpers
def in_bounds(v, center, err):
	if (v is None) or (center is None):
		return True
	print abs(v-center)
	return abs(v - center) <= abs(err)

def _is_rising(p1,p2):
	print p1, p2
	if (p1 is None) or (p2 is None):
		return True
	if (p2-p1) > 0:
		return True
	else:
		return False

def _is_falling(p1,p2):
	if (p1 is None) or (p2 is None):
		return True
	if (p2-p1) < 0:
		return True
	else:
		return False

def _sinewave(t,ampl,ph,off,freq):
	# Taken from commissioning/calibration.py
	return off+ampl*numpy.sin(2*numpy.pi*freq*t+ph)
	#return numpy.array([off+ampl*math.sin(2*math.pi*freq*x+ph) for x in t])

def _sawtooth(t, ampl, phase, offset, freq, width):
	return scipy.signal.sawtooth(freq*t + phase/freq, width=width)*ampl + offset

def _squarewave(t, ampl, phase, offset, freq, duty):
	return scipy.signal.square(freq*t + phase/freq, duty=duty)*ampl + offset

# Helper function to compute the timestep per sample of a frame
def _get_frame_timestep(moku):
	startt, endt = moku._get_timebase(moku.decimation_rate, moku.pretrigger, moku.render_deci, moku.offset)
	ts = (endt - startt) / _OSC_SCREEN_WIDTH
	return ts

def _crop_frame_of_nones(frame):
	if None in frame:
		return frame[0:frame.index(None)]
	return frame


@pytest.fixture(scope="function")
def base_instrs(conn_mokus):
	m1 = conn_mokus[0]
	m2 = conn_mokus[1]
	print("Attaching instruments")

	i1 = Oscilloscope()
	i2 = Oscilloscope()

	m1.attach_instrument(i1)
	m2.attach_instrument(i2)

	i1.set_defaults()
	i2.set_defaults()

	# Set precision mode
	i1.set_precision_mode(True)
	i2.set_precision_mode(True)

	i1.commit()
	i2.commit()

	return (i1,i2)

class Test_Siggen:
	'''
		This class tests the correctness of the embedded signal generator 
	'''
	@pytest.mark.parametrize("ch, vpp, freq, offset, duty, waveform", 
		itertools.product(
			[1,2],
			[1.0], #, 1.0],
			[1e3], #, 1e6], 
			[0], #0.3, 0.5], 
			[0.1], #, 0.3, 0.7, 0.9, 1.0],
			[SG_WAVE_SINE] #, SG_WAVE_SQUARE, SG_WAVE_TRIANGLE]
			))
	def test_output_waveform(self, base_instrs, ch, vpp, freq, offset, duty, waveform):
		master = base_instrs[0]
		slave = base_instrs[1]

		# Set the timebase to allow for ~5 cycles
		slave.set_timebase(0, 5.0/freq)
		slave.set_source(ch, OSC_SOURCE_ADC)
		slave.set_frontend(1, fiftyr=True, atten=False, ac=False)

		if ch == 1:
			slave.set_trigger(OSC_TRIG_CH1, OSC_EDGE_RISING, offset, mode = OSC_TRIG_NORMAL)
		else:
			slave.set_trigger(OSC_TRIG_CH2, OSC_EDGE_RISING, offset, mode = OSC_TRIG_NORMAL)

		slave.commit()

		if waveform == SG_WAVE_SINE:
			master.synth_sinewave(ch, vpp, freq, offset)
			p0 = [vpp/2.0, 0.0, offset, freq]
		elif waveform == SG_WAVE_SQUARE:
			p0 = [vpp/2.0, 0.0, offset, freq, duty]
			master.synth_squarewave(ch, vpp, freq,offset=offset, duty = duty)
		elif waveform == SG_WAVE_TRIANGLE:
			p0 = [vpp/2.0, 0.0, offset, freq, duty]
			master.synth_rampwave(ch, vpp, freq, offset=offset, symmetry = duty)
		else:
			print "Invalid waveform type."
			assert False

		master.commit()
		slave.get_frame(timeout = 5) # Throwaway
		if ch == 1:
			frame = slave.get_frame(timeout = 5).ch1
		else:
			frame = slave.get_frame(timeout = 5).ch2
		frame = _crop_frame_of_nones(frame)

		ts = numpy.cumsum([_get_frame_timestep(slave)]*len(frame))
		params, cov = curve_fit(_sinewave if (waveform == SG_WAVE_SINE) else (_squarewave if (waveform == SG_WAVE_SQUARE) else _sawtooth), ts, frame, p0 = p0)
		
		print params 

		measured_amp = params[0]
		measured_offset = params[2]
		measured_freq = params[3]

		if waveform == SG_WAVE_SINE:
			plt.plot(ts, [_sinewave(t, measured_amp, params[1], measured_offset, measured_freq) for t in ts])
		elif waveform == SG_WAVE_SQUARE:
			plt.plot(ts, [_squarewave(t, measured_amp, params[1], measured_offset, measured_freq, params[4]) for t in ts])
		elif waveform == SG_WAVE_TRIANGLE:
			plt.plot(ts, [_sawtooth(t, measured_amp, params[1], measured_offset, measured_freq, params[4]) for t in ts])
		plt.show()

		assert in_bounds(measured_amp, vpp/2.0, ADC_AMP_TOL_P*vpp/2.0)
		assert in_bounds(measured_offset, offset, ADC_OFF_TOL_R)
		if (waveform == SG_WAVE_SQUARE) or (waveform == SG_WAVE_TRIANGLE):
			measured_duty = params[4]
			assert in_bounds(measured_duty, duty, DAC_DUTY_TOL_R)

		assert False


	@pytest.mark.parametrize("ch, vpp, freq, offset, duty, waveform", 
		itertools.product(
			[1,2],
			[0, 0.5, 1.0],
			[1e3, 1e6], 
			[0, 0.3, 0.5], 
			[0.0, 0.1, 0.3, 0.7, 0.9, 1.0],
			[SG_WAVE_SINE, SG_WAVE_SQUARE, SG_WAVE_TRIANGLE]
			))
	def test_waveform_amp(self, base_instrs, ch, vpp, freq, offset, duty, waveform):
		'''
			Test the max/min amplitude of the waveforms are correct
		'''
		master = base_instrs[0]
		slave = base_instrs[1]

		# Set timebase to allow for 5 cycles
		if freq == 0:
			tspan = 1.0 # Set DC to 1 second
		else:
			tspan = (1.0/freq) * 5.0
		slave.set_timebase(0,tspan)

		# Loop DAC to input to measure the generated waveforms
		master.set_source(ch,OSC_SOURCE_DAC)
		if(ch==1):
			master.set_trigger(OSC_TRIG_DA1, OSC_EDGE_RISING, 0)
		else:
			master.set_trigger(OSC_TRIG_DA2, OSC_EDGE_RISING, 0)

		# Generate the desired waveform
		if waveform == SG_WAVE_SINE:
			master.synth_sinewave(ch, vpp, freq, offset)
		elif waveform == SG_WAVE_SQUARE:
			master.synth_squarewave(ch, vpp, freq,offset=offset, duty=duty)
		elif waveform == SG_WAVE_TRIANGLE:
			master.synth_rampwave(ch, vpp, freq, offset=offset, symmetry=duty)
		master.commit()

		# 5mV Tolerance on max/min values
		tolerance = 0.005


		# Test amplitudes on a few frames worth of generated output
		for _ in range(10):
			frame = master.get_frame(wait=True)
			print frame
			if(ch==1):
				ch_frame = frame.ch1
			else:
				ch_frame = frame.ch2

			# For debugging the received frame
			for y in ch_frame:
				print y

			# Get max/min amplitudes for each frame
			maxval = max(x for x in ch_frame if x is not None)
			minval = min(x for x in ch_frame if x is not None)

			# Check max/min values are within tolerance bounds
			assert in_bounds(maxval, (vpp/2.0)+offset, tolerance)
			assert in_bounds(minval, (-1*(vpp/2.0) + offset), tolerance)


	@pytest.mark.parametrize("ch, vpp, freq, waveform", 
		itertools.product([1,2],[1.0],[100, 1e3, 100e3, 1e6, 3e6],[SG_WAVE_SINE, SG_WAVE_SQUARE, SG_WAVE_TRIANGLE]))
	def tes2_waveform_freq(self, base_instrs, ch, vpp, freq, waveform):
		'''
			Test the frequency of generated waveforms

			This is done by checking that the amplitude of generated signals is constant as we jump across multiple cycles
			of the waveform.
		'''
		master = base_instrs[0]

		# Set timebase to allow for 5 cycles
		number_periods = 5
		period = (1.0/freq)
		tspan = period * number_periods
		master.set_timebase(0,tspan)

		# Loop DAC output to input for measurement
		master.set_source(ch,OSC_SOURCE_DAC)
		master.set_xmode(OSC_FULL_FRAME)
		if(ch==1):
			master.set_trigger(OSC_TRIG_DA1, OSC_EDGE_RISING, 0)
		else:
			master.set_trigger(OSC_TRIG_DA2, OSC_EDGE_RISING, 0)

		# Get back actual timebase (this will not be precisely 5 cycles due to rounding)
		(tstart, tend) = master._get_timebase(master.decimation_rate, master.pretrigger, master.render_deci, master.offset)

		# Compute the approximate number of samples per waveform period
		time_per_smp = (tend-tstart)/_OSC_SCREEN_WIDTH
		smps_per_period = period/time_per_smp

		# Generate the waveform type to be tested
		# Define the offset into each frame that we should start measuring amplitudes from
		if waveform == SG_WAVE_SINE:
			master.synth_sinewave(ch,vpp,freq,0.0)
			start_xs = [0, int(smps_per_period/2), int(smps_per_period/3), int(smps_per_period/4), int(smps_per_period/8), int(3*smps_per_period/4)]
		elif waveform == SG_WAVE_SQUARE:
			master.synth_squarewave(ch, vpp, freq)
			# Don't start on a squarewave edge
			start_xs = [int(smps_per_period/3), int(3*smps_per_period/4), int(2*smps_per_period/3), int(smps_per_period/8), int(7*smps_per_period/8)]
		elif waveform == SG_WAVE_TRIANGLE:
			master.synth_rampwave(ch, vpp, freq)
			start_xs = [0, int(smps_per_period/2), int(smps_per_period/3), int(smps_per_period/4), int(smps_per_period/8), int(3*smps_per_period/4)]
		master.commit()

		# Allow 2% variation in amplitude
		allowable_error = 0.02*vpp

		# Workaround for ensuring we receive a valid waveform in the frame
		# The squarewave generator has unpredictable initial conditions currently
		# So we want to skip the first frame
		time.sleep(3*(tend-tstart))
		master.flush()
		master.get_frame()

		# Test multiple frames worth
		for _ in range(5):

			frame = master.get_frame()
			if(ch==1):
				ch_frame = frame.ch1
			if(ch==2):
				ch_frame = frame.ch2

			for start_x in start_xs:
				# First amplitude measurement of the waveform
				expectedv = ch_frame[start_x]

				# Skip along the waveform, 1 cycle at a time and check
				# the amplitude matches the expected value.
				for i in range(number_periods-1):
					x = start_x + int(round(i*smps_per_period))

					actualv = ch_frame[x]

					# For debugging the received frame
					#for y in ch_frame:
					#	print y

					# Debugging info
					# print "Allowable tolerance: %.10f, Error: %.10f, Frame index: %d, Expected value: %.10f, Actual value: %.10f, Samples per period: %d, Render deci: %f" % (allowable_error, expectedv-actualv, x, expectedv, actualv, smps_per_period, master.render_deci)
					
					# Check actual value is within tolerance
					assert in_bounds(actualv, expectedv, allowable_error)

	
	# NOTE: Modulation cannot be tested using the Oscilloscope instrument as it is not enabled.
	# 		The SignalGenerator bitstream should be tested on its own with full modulation functionality enabled.
	@pytest.mark.parametrize("ch, source, depth, frequency", [
		#(1, 0, 0.5, 3)
		])
	def tes2_am_modulation(self, base_instrs, ch, source, depth, frequency):
		master = base_instrs[0]

		# Set a sampling frequency
		master.set_timebase(0,1.0) # 1 second
		master.synth_sinewave(1, 1.0, 10, 0)
		master.synth_sinewave(2, 1.0, 5, 0)
		master.synth_modulate(1, SG_MOD_AMPL, SG_MODSOURCE_INT, depth, frequency)
		master.commit()

		# Get sampling frequency
		fs = _OSC_ADC_SMPS / (master.decimation_rate * master.render_deci)
		fstep = fs / _OSC_SCREEN_WIDTH

		assert False

class Test_Trigger:
	'''
		This class tests Trigger modes of the Oscilloscope
	'''
	


	@pytest.mark.parametrize("edge, trig_level, waveform",
		itertools.product(
			[OSC_EDGE_RISING, OSC_EDGE_FALLING, OSC_EDGE_BOTH], 
			[-0.1, 0.0, 0.1, 0.3], 
			[SG_WAVE_SINE, SG_WAVE_SQUARE, SG_WAVE_TRIANGLE]))
	def test_triggered_edge(self, base_instrs, edge, trig_level, waveform):
		'''
			Test the triggered edge type and level are correct
		'''
		# Get the Master Moku
		master = base_instrs[0]

		# Set up the source signal to test triggering on
		trig_ch = 1
		source_freq = 100.0 #Hz
		source_vpp = 1.0
		source_offset = 0.0
		master.set_source(trig_ch, OSC_SOURCE_DAC)

		if waveform == SG_WAVE_SINE:
			master.synth_sinewave(trig_ch, source_vpp, source_freq, source_offset)
		elif waveform == SG_WAVE_SQUARE:
			master.synth_squarewave(trig_ch, source_vpp, source_freq, source_offset)
		elif waveform == SG_WAVE_TRIANGLE:
			master.synth_rampwave(trig_ch, source_vpp, source_freq, source_offset)
		else:
			print "Invalid waveform type"
			assert False

		# Set a symmetric timebase of ~10 cycles
		master.set_timebase(-5.0/source_freq,5.0/source_freq)

		# Sample number of trigger point given a symmetric timebase
		half_idx = (_OSC_SCREEN_WIDTH / 2) - 1

		# Trigger on correct DAC channel
		if trig_ch == 1:
			master.set_trigger(OSC_TRIG_DA1, edge, trig_level, hysteresis=0, hf_reject=False, mode=OSC_TRIG_NORMAL)
		if trig_ch == 2:
			master.set_trigger(OSC_TRIG_DA2, edge, trig_level, hysteresis=0, hf_reject=False, mode=OSC_TRIG_NORMAL)

		master.commit()

		for _ in range(5):
			frame = master.get_frame(timeout=5)
			if trig_ch == 1:
				ch_frame = frame.ch1
			elif trig_ch == 2:
				ch_frame = frame.ch2

			# Check for correct level unless we are on a square edge
			if not (waveform == SG_WAVE_SQUARE):
				assert in_bounds(trig_level,ch_frame[half_idx], 0.005)

			if(edge == OSC_EDGE_RISING):
				assert _is_rising(ch_frame[half_idx-1],ch_frame[half_idx])
			elif(edge == OSC_EDGE_FALLING):
				assert _is_falling(ch_frame[half_idx-1], ch_frame[half_idx])
			elif(edge == OSC_EDGE_BOTH):
				assert _is_rising(ch_frame[half_idx-1],ch_frame[half_idx]) or _is_falling(ch_frame[half_idx-1],ch_frame[half_idx])


	def _setup_trigger_mode_test(self, master, trig_mode, trig_lvl, source_vpp, source_offset, source_freq):
		# Set up the triggering and a DAC source to trigger on
		trig_ch = 1
		trig_level = trig_lvl
		trig_edge = OSC_EDGE_RISING

		trig_source_freq = source_freq
		trig_source_vpp = source_vpp
		trig_source_offset = source_offset

		timebase_cyc = 10.0

		master.set_source(trig_ch, OSC_SOURCE_DAC)
		master.set_timebase(0, (timebase_cyc/trig_source_freq))
		if trig_ch == 1:
			master.set_trigger(OSC_TRIG_DA1, trig_edge, trig_level, hysteresis = 0, hf_reject = False, mode = trig_mode)
		if trig_ch == 2:
			master.set_trigger(OSC_TRIG_DA2, trig_edge, trig_level, hysteresis = 0, hf_reject = False, mode = trig_mode)

		# Generate waveform to trigger off
		master.synth_sinewave(trig_ch, trig_source_vpp, trig_source_freq, trig_source_offset)
		master.commit()

		return timebase_cyc

	@pytest.mark.parametrize("freq",([20, 30, 40, 1e3, 10e3, 1e6, 10e6]))
	def test_trigger_mode_normal(self, base_instrs, freq):
		'''
			Tests 'Normal' trigger mode
		'''
		master = base_instrs[0]
		timebase_cyc = self._setup_trigger_mode_test(master, OSC_TRIG_NORMAL, 0.0, 1.0, 0.0, freq)
		# Sample number of trigger point given a symmetric timebase
		half_idx = (_OSC_SCREEN_WIDTH / 2) - 1

		frame_timeout = max(5,(1/freq) * 20)
		triggers_per_frame = min((freq/timebase_cyc)/master.framerate, OSC_MAX_TRIGRATE/master.framerate)

		# Case when trigger rate is greater than frame rate
		if triggers_per_frame > 2:
			waveformid = None

			for _ in range(20):
				frame = master.get_frame(timeout = frame_timeout)

				if waveformid is None: # Get the first ID
					waveformid = frame.waveformid
				else: 
					# Waveform ID has increased since last frame
					assert frame.waveformid > waveformid

					# The change in waveform ID is approximately the expected number of triggers per frame
					delta_id = frame.waveformid - waveformid
					assert in_bounds(triggers_per_frame, delta_id, max(triggers_per_frame*0.2, 1))

				waveformid = frame.waveformid
				# Debug print
				print("Waveform ID: %s, Frame ID: %s" % (waveformid, frame.frameid))
		
		# Case when trigger rate is slower than frame rate
		else:
			frames_per_trigger = 1.0/triggers_per_frame

			for _ in range(10):
				frame = master.get_frame(timeout = frame_timeout)
				waveformid = frame.waveformid
				frame_ctr = 0

				while (frame.waveformid == waveformid):
					frame_ctr = frame_ctr + 1
					frame = master.get_frame(timeout = frame_timeout)

				# The number of frames per trigger is approximately as expected (within 1 frame)
				assert in_bounds(frames_per_trigger, frame_ctr, max(frames_per_trigger+1,1))

				# Debug print
				print("Waveform ID: %s, Frame ID: %s, Frame Counter: %s" % (waveformid, frame.frameid, frame_ctr))


	def test_trigger_mode_normal_notrigger(self, base_instrs):
		'''
			Tests the case of Normal trigger mode when there are no trigger events
		'''
		master = base_instrs[0]

		# Set up the trigger source with a trigger level exceeding the peak voltage
		source_freq = 1e3
		source_vpp = 1.0
		source_offset = 0.0
		trig_lvl = 1.5
		timebase_cyc = self._setup_trigger_mode_test(master, OSC_TRIG_NORMAL, trig_lvl, source_vpp, source_offset, source_freq)

		# There should be no trigger events
		with pytest.raises(FrameTimeout):
			frame = master.get_frame(timeout = 5)
 

	def test_trigger_mode_auto_notrigger(self, base_instrs):
		'''
			Tests 'Auto' trigger mode
		'''
		master = base_instrs[0]

		# Set up the trigger source with a trigger level exceeding the peak voltage
		source_freq = 1e3
		source_vpp = 1.0
		source_offset = 0.0
		trig_lvl = 1.5
		timebase_cyc = self._setup_trigger_mode_test(master, OSC_TRIG_AUTO, trig_lvl, source_vpp, source_offset, source_freq)

		# Auto mode test - every frame should have maximum number of triggers
		waveformid = None
		delta_ids = []
		for _ in range(20):
			frame = master.get_frame(timeout = 5)
			if waveformid == None:
				waveformid = frame.waveformid
			else:
				delta_ids = delta_ids + [frame.waveformid - waveformid]
				waveformid = frame.waveformid

			# Debug print
			print("Waveform ID: %s, Frame ID: %s" % (frame.waveformid, frame.frameid))


		avg = sum(delta_ids)/float(len(delta_ids))
		assert in_bounds(avg, OSC_AUTO_TRIGRATE/master.framerate, 0.2)
		print("Delta IDs: %s, Avg: %f" % (delta_ids, avg))


	def test_trigger_mode_single(self, base_instrs):
		'''
			Tests 'Auto' trigger mode
		'''
		master = base_instrs[0]

		# Set up the trigger source with a trigger level exceeding the peak voltage
		trig_source_freq = 1e3
		trig_source_vpp = 1.0
		trig_source_offset = 0.0
		trig_lvl = 0.0
		timebase_cyc = self._setup_trigger_mode_test(master, OSC_TRIG_SINGLE, trig_lvl, trig_source_vpp, trig_source_offset, trig_source_freq)

		frame = master.get_frame(timeout=5)
		init_state_id = frame.stateid
		init_waveform_id = frame.waveformid
		init_trig_id = frame.trigstate

		# Force a change of state ID and check it doesn't retrigger
		master.commit()

		while frame.stateid == init_state_id:
			frame = master.get_frame(wait=False, timeout = 5)

		# Assert that the same waveform is being sent in the frame, and no additional triggers have occurred
		assert frame.waveformid == init_waveform_id
		assert frame.stateid > init_trig_id

		print("State ID: %s, Trigstate: %s, Waveform ID: %s, Frame ID: %s" % (frame.stateid, frame.trigstate, frame.waveformid, frame.frameid))

	@pytest.mark.parametrize("ch", ([OSC_TRIG_CH1, OSC_TRIG_CH2, OSC_TRIG_DA1, OSC_TRIG_DA2]))
	def test_trigger_channels(self, base_instrs, ch):
		'''
			Tests triggering on ADC and DAC channels
		'''
		master = base_instrs[0]
		slave = base_instrs[1]

		trig_source_freq = [1e3, 1e3, 0.75e3, 1.75e3]
		trig_source_vpp = [1.0, 0.5, 1.0, 0.5]
		trig_source_offset = [0.0, 0.0, 0.0, 0.0]
		trig_lvl = [0.0,0.0,0.0,0.0]

		# Make sure signals coming from slave are not amplified or attenuated
		master.set_frontend(1, fiftyr=True, atten=False, ac=False)
		master.set_frontend(2, fiftyr=True, atten=False, ac=False)

		# Generate a different output on Channel 2 so 
		master.synth_sinewave(1, trig_source_vpp[0], trig_source_freq[0], trig_source_offset[0])
		master.synth_sinewave(2, trig_source_vpp[1], trig_source_freq[1], trig_source_offset[1])
		slave.synth_sinewave(1, trig_source_vpp[2], trig_source_freq[2], trig_source_offset[2])
		slave.synth_sinewave(2, trig_source_vpp[3], trig_source_freq[3], trig_source_offset[3])

		# Check the correct frame is being received
		if ch == OSC_TRIG_CH1:
			master.set_source(1, OSC_SOURCE_ADC)
			idx = 2
		elif ch == OSC_TRIG_DA1:
			master.set_source(1, OSC_SOURCE_DAC)
			idx = 0
		elif ch == OSC_TRIG_CH2:
			master.set_source(2, OSC_SOURCE_ADC)
			idx = 3
		elif ch == OSC_TRIG_DA2:
			master.set_source(2, OSC_SOURCE_DAC)
			idx = 1
		else:
			print "Invalid trigger channel"
			assert False

		master.set_trigger(ch, OSC_EDGE_RISING, 0.0, mode=OSC_TRIG_NORMAL)
		master.set_timebase(-5/trig_source_freq[idx], 5/trig_source_freq[idx])
		master.commit()
		slave.commit()

		# Get a frame on the appropriate channel and check it is as expected
		frame = master.get_frame(timeout = 5)

		# Check the frame
		if ch == OSC_TRIG_CH1 or ch == OSC_TRIG_DA1:
			data = frame.ch1
		elif ch == OSC_TRIG_CH2 or ch == OSC_TRIG_DA2:
			data = frame.ch2
		else:
			print "Invalid trigger channel"
			assert False

		# Generate timesteps for the current timebase
		# Step size
		t1, t2 = master._get_timebase(master.decimation_rate, master.pretrigger, master.render_deci, master.offset)
		ts = numpy.cumsum([(t2 - t1) / _OSC_SCREEN_WIDTH]*len(data))

		# Crop the data if there are 'None' values at the end of the frame
		try:
			invalid_indx = data.index(None)
			data = data[0:data.index(None)]
			ts = ts[0:len(data)]
		except ValueError:
			pass

		# Curve fit the frame data to ensure correct waveform has been triggered
		bounds = ([0, 0, -0.2, trig_source_freq[idx]/2.0], [2.0, 2*math.pi, 0.2, 2.0*trig_source_freq[idx]])
		p0 = [trig_source_vpp[idx], 0, 0, trig_source_freq[idx]]
		params, cov = curve_fit(_sinewave, ts, data, p0 = p0, bounds=bounds)
		ampl = params[0]
		phase = params[1]
		offset = params[2]
		freq = params[3]

		plt.plot(ts,data)
		plt.show()

		print("Vpp: %f/%f, Frequency: %f/%f, Offset: %f/%f" % (trig_source_vpp[idx], ampl*2.0, trig_source_freq[idx], freq, trig_source_offset[idx], offset))
		assert in_bounds(ampl*2.0, trig_source_vpp[idx], trig_source_vpp[idx]*0.1)
		assert in_bounds(freq, trig_source_freq[idx], trig_source_freq[idx]*0.1)
		assert in_bounds(offset, trig_source_offset[idx], max(0.05, trig_source_offset[idx]*0.1))

		# Sample number of trigger point given a symmetric timebase
		half_idx = (_OSC_SCREEN_WIDTH / 2) - 1
		# Assert the trigger point is the correct position
		assert _is_rising(data[half_idx-1],data[half_idx])

		assert False


class Test_Timebase:
	'''
		Ensure the timebase is correct
	'''
	def zero_crossings(self, a):
		return numpy.where(numpy.diff(numpy.sign(a)))[0]

	
	# Test frames from both channels
	# TODO: Need to more thoroughly test negative timebases as some of these are currently broken  # [-3e-3, -1e-3]
	@pytest.mark.parametrize("timebase", [[-10e-6, -5e-6], [-2, -1], [-10e-6, 10e-6], [-2e-3,1e-3],[-1,2], [0,1],[-3e-3,0],[0,2e-3], [1e-6, 2e-3]])
	def test_timebase_span(self, base_instrs, timebase):

		master = base_instrs[0]
		slave = base_instrs[1]
		span = timebase[1]-timebase[0]
		f1 = 10.0/span
		f2 = 5.0/span

		master.set_source(1, OSC_SOURCE_DAC)
		master.set_source(2, OSC_SOURCE_DAC)
		master.set_trigger(OSC_TRIG_DA1, OSC_EDGE_RISING, 0.0, mode=OSC_TRIG_NORMAL)
		master.synth_sinewave(1, 1.0, f1, 0.0)
		master.synth_sinewave(2, 1.0, f2, 0.0)
		master.set_timebase(timebase[0],timebase[1])
		master.commit()

		startt, endt = master._get_timebase(master.decimation_rate, master.pretrigger, master.render_deci, master.offset)
		ts = numpy.cumsum([(endt - startt)/_OSC_SCREEN_WIDTH] * _OSC_SCREEN_WIDTH)

		frame = master.get_frame(timeout = 20)
		data1 = frame.ch1
		data2 = frame.ch2

		data1 = _crop_frame_of_nones(data1)
		data2 = _crop_frame_of_nones(data2)

		ts1 = ts[0:len(data1)]
		ts2 = ts[0:len(data2)]
		# Assuming a timebase, do a curve fit on both frames and check the frequency is the minimum
		params1, cov1 = curve_fit(_sinewave, ts1, data1, p0 = [1.0, 0, 0, f1])
		params2, cov2 = curve_fit(_sinewave, ts2, data2, p0 = [1.0, 0, 0, f2])

		print("Span: %.10f/%.10f, Freq1: %f/%f, Freq: %f/%f" % (span, endt-startt, f1, params1[3], f2, params2[3]))

		#plt.plot(range(1024), frame.ch1)
		#plt.plot(range(1024), frame.ch2)
		#plt.show()

		assert params1[3] > (f1*0.98)
		assert params2[3] > (f2*0.98)

	@pytest.mark.parametrize("ch, pretrigger_time",
		itertools.product(
			[1,2],
			[20e-6, 1e-6, 20e-3, 1e-3, 100e-3, 1, 3]))
	def test_pretrigger(self, base_instrs, ch, pretrigger_time):

		master = base_instrs[0]
		#slave = base_instrs[0]

		# Generate a pulse of some small width and period < frame length
		master.synth_sinewave(ch, 1.0, 1.0/(3*pretrigger_time))
		if ch == 1:
			master.set_trigger(OSC_TRIG_DA1, OSC_EDGE_RISING, 0, mode=OSC_TRIG_NORMAL)
		else:
			master.set_trigger(OSC_TRIG_DA2, OSC_EDGE_RISING, 0, mode=OSC_TRIG_NORMAL)
		master.set_source(ch, OSC_SOURCE_DAC)
		master.set_timebase(-pretrigger_time, 3*pretrigger_time)
		master.commit()

		# Compute the index of which the rising edge should occur
		if ch == 1:
			frame = master.get_frame(timeout = 20).ch1
		else:
			frame = master.get_frame(timeout = 20).ch2
		if None in frame:
			frame = frame[0:frame.index(None)]

		# Get index of the zero crossing
		zc = self.zero_crossings(frame)
		#plt.plot(range(len(frame)), frame)
		#plt.show()

		# Convert indices to timesteps
		ts = _get_frame_timestep(master)
		pretrig_time = zc[0] * ts

		print("Pretrigger (s): %f/%f" % (pretrigger_time, pretrig_time))

		# Within two samples or 5% of desired pretrigger time
		assert in_bounds(pretrig_time, pretrigger_time, max(2*ts, 0.05*pretrigger_time))

	@pytest.mark.parametrize("ch, posttrigger_time",
		itertools.product(
			[1,2],
			[20e-6, 1e-6, 20e-3, 1e-3, 100e-3, 1, 3]))
	def test_posttrigger(self, base_instrs, ch, posttrigger_time):

		master = base_instrs[0]

		source_freq = 1.0/(2*posttrigger_time)
		print "Source Freq ", source_freq
		master.synth_squarewave(ch, 1.0, source_freq, duty=0.1)
		if ch == 1:
			master.set_trigger(OSC_TRIG_DA1, OSC_EDGE_RISING, 0, mode=OSC_TRIG_NORMAL)
		else:
			master.set_trigger(OSC_TRIG_DA2, OSC_EDGE_RISING, 0, mode=OSC_TRIG_NORMAL)
		master.set_source(ch, OSC_SOURCE_DAC)
		master.set_timebase(posttrigger_time, 5*posttrigger_time)
		master.commit()

		if ch == 1:
			frame = master.get_frame().ch1
		else:
			frame = master.get_frame().ch2
		frame = _crop_frame_of_nones(frame)

		# Get index of the zero crossing
		zc = self.zero_crossings(frame)
		#plt.plot(range(len(frame)), frame)
		#plt.show()

		# Convert indices to timesteps
		ts = _get_frame_timestep(master)

		source_period = 1.0/source_freq
		period_tolerance = max(2*ts,source_period*0.05)
		measured_period = (zc[0] * ts) + posttrigger_time
		measured_period_error = abs(measured_period-source_period)/source_period

		print("ZC: %f, Sum: %f, Period: %f, Tolerance: %f, Error: %f" % ((zc[0] * ts), measured_period, source_period, period_tolerance, measured_period_error))
		assert in_bounds(measured_period, source_period, period_tolerance)

class Test_Frontend:

	@pytest.mark.parametrize("ch, fiftyr, amp, freq, offset",
		itertools.product(
			[1,2],
			[True, False],
			[0.2, 0.5, 1.0, 1.5],
			[100, 1e3, 20e3, 1e6],
			[0.0, 0.2]
			))
	def test_input_impedance(self, base_instrs, ch, fiftyr, amp, freq, offset):
		master = base_instrs[0]
		slave = base_instrs[1]

		source_amp = amp
		source_freq = freq
		source_offset = offset
		tolerance_percent = 0.05

		# Put in different waveforms and test they look correct in a frame
		master.set_frontend(ch, fiftyr=fiftyr, atten=True, ac=False)
		master.set_source(ch, OSC_SOURCE_ADC)

		slave.synth_sinewave(ch, source_amp, source_freq, source_offset)
		master.set_timebase(0,10.0/source_freq)
		slave.commit()
		master.commit()

		master.get_frame() # throwaway
		if ch == 1:
			frame = master.get_frame(timeout = 5).ch1
		if ch == 2:
			frame = master.get_frame(timeout = 5).ch2
		frame = _crop_frame_of_nones(frame)

		# Fit a curve to the input waveform
		ts = numpy.cumsum([_get_frame_timestep(master)]*len(frame))
		p0 = [source_amp, 0, source_offset, source_freq]
		params, cov = curve_fit(_sinewave, ts, frame, p0=p0)

		print params
		expected_amp = source_amp if fiftyr else source_amp*2.0
		expected_offset = source_offset if fityr else source_offset*2.0
		measured_amp = abs(params[0]*2.0)
		measured_offset = params[2]

		assert in_bounds(measured_amp, expected_amp, expected_amp*tolerance_percent)
		assert in_bounds(measured_offset, source_offset, source_offset*tolerance_percent)

	@pytest.mark.parametrize("ch, atten, amp",
		itertools.product(
			[1,2],
			[True, False],
			[0.3, 0.7, 1.0, 1.3, 1.8, 2.0]
			))
	def test_input_attenuation(self, base_instrs, ch, atten, amp):
		master = base_instrs[0]
		slave = base_instrs[1]

		source_amp = amp # Vpp
		source_freq = 1e3 # Hz
		source_offset = 0.0
		tolerance_percent = 0.1
		SMALL_INPUT_RANGE= 1.0 # Vpp
		LARGE_INPUT_RANGE= 10.0 # Vpp
		
		# Generate a 10Vpp signal and check it doesn't clip on high attenuation
		slave.synth_sinewave(ch, source_amp, source_freq, source_offset)
		slave.commit()

		master.set_frontend(ch, fiftyr=True, atten=atten, ac=False)
		master.set_timebase(0,10.0/source_freq)
		master.commit()

		# Get a throwaway frame
		master.get_frame(timeout=5)

		# Get a valid frame
		if ch == 1:
			frame = master.get_frame(timeout = 5).ch1
		else:
			frame = master.get_frame(timeout = 5).ch2
		frame = _crop_frame_of_nones(frame)

		if (atten and source_amp < LARGE_INPUT_RANGE) or ((not atten) and source_amp < SMALL_INPUT_RANGE) :
			# Fit a curve to the input waveform (it shouldn't be clipped)
			ts = numpy.cumsum([_get_frame_timestep(master)]*len(frame))
			p0 = [source_amp, 0, source_offset, source_freq]
			params, cov = curve_fit(_sinewave, ts, frame, p0=p0)
			measured_amp = abs(params[0]*2.0)
			assert in_bounds(measured_amp, source_amp, tolerance_percent*source_amp)
		else:
			# Clipping will have occurred, full range used
			assert in_bounds(abs(max(frame)-min(frame)),SMALL_INPUT_RANGE, SMALL_INPUT_RANGE*tolerance_percent)

	@pytest.mark.parametrize("ch, fiftyr, ac, amp, offset",
		itertools.product(
			[1,2],
			[True, False],
			[True, False],
			[0.3, 0.7, 1.0],
			[-0.5, -0.1, 0.0, 0.1, 0.5]
			))
	def test_acdc_coupling(self, base_instrs, ch, fiftyr, ac, amp, offset):

		tolerance_percent =  ADC_AMP_TOL_P
		tolerance_offset = ADC_OFF_TOL_R

		master = base_instrs[0]
		slave = base_instrs[1]

		source_amp = amp # Vpp
		source_offset = offset
		# Set the source frequency "large enough" to avoid attenuation
		if fiftyr:
			source_freq = AC_COUPLE_CORNER_FREQ_50O*10.0
		else:
			source_freq = AC_COUPLE_CORNER_FREQ_1MO*10.0

		# Expected offset and amplitude
		expected_amp = source_amp if fiftyr else source_amp * 2.0
		expected_off = 0.0 if ac else (source_offset if fiftyr else source_offset * 2.0)

		slave.synth_sinewave(ch, source_amp, source_freq, source_offset)
		slave.commit()

		master.set_frontend(ch, fiftyr=fiftyr, atten=True, ac=ac)
		master.set_timebase(0, 10.0/source_freq)
		if ch == 1:
			master.set_trigger(OSC_TRIG_CH1, OSC_EDGE_RISING, expected_off, mode=OSC_TRIG_NORMAL)
		else:
			master.set_trigger(OSC_TRIG_CH2, OSC_EDGE_RISING, expected_off, mode=OSC_TRIG_NORMAL)
		master.commit()

		# Throwaway frame
		master.get_frame(timeout = 5)
		if ch == 1:
			frame = master.get_frame(timeout = 5).ch1
		else:
			frame = master.get_frame(timeout = 5).ch2
		frame = _crop_frame_of_nones(frame)

		# Check that the amplitude is half and that it is approximately 0V mean if AC coupling is ON
		# OR "Offset" if DC coupling
		# Fit a curve to the input waveform (it shouldn't be clipped)
		ts = numpy.cumsum([_get_frame_timestep(master)]*len(frame))
		p0 = [expected_amp, 0, expected_off, source_freq]
		params, cov = curve_fit(_sinewave, ts, frame, p0=p0)
		measured_amp = abs(params[0]*2.0)
		measured_off = params[2]
		print params

		assert in_bounds(measured_amp, expected_amp, tolerance_percent*expected_amp)
		assert in_bounds(measured_off, expected_off, tolerance_offset)


class Tes2_Source:
	'''
		Ensure the source is set and rendered as expected
	'''
	@pytest.mark.parametrize("ch, amp",[
		(1, 0.2),
		(1, 0.5),
		(2, 0.1),
		(2, 1.0), 
		])
	def test_dac(self, master, ch, amp):
		i = master
		i.synth_sinewave(ch,amp,1e6,0)
		i.set_source(ch, OSC_SOURCE_DAC)
		i.set_timebase(0,2e-6)
		i.commit()

		# Max and min should be around ~amp
		frame = i.get_frame()
		assert in_bounds(max(getattr(frame, "ch"+str(ch))), amp, 0.05)
		assert in_bounds(min(getattr(frame, "ch"+str(ch))), amp, 0.05)

