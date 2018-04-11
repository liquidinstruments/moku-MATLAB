# moku-MATLAB

MATLAB library for the command, control and monitoring of the [Liquid Instruments Moku:Lab](http://www.liquidinstruments.com) device.

For moku-MATLAB documentation please run `help moku` from your MATLAB console.

## Installation

### MATLAB 2015 or later
1. Download the [moku-MATLAB Toolbox](http://updates.liquidinstruments.com/static/)
2. In MATLAB, open the downloaded Toolbox file using the file explorer.
3. Press "Install".
4. Run `help moku` in the MATLAB console to confirm installation.

### MATLAB 2013-14
1. Download the [moku-MATLAB zip file](http://updates.liquidinstruments.com/static/)
2. Extract the zip file to a convenient location (we recommend Documents/MATLAB/Add-Ons/Toolboxes).
3. Open MATLAB.
4. In the Home tool pane, click "Set Path".
5. Click "Add with Subfolders..." and select the extracted moku-MATLAB folder.
6. Press "Save" to permanently add the folder to the MATLAB path.
7. Run `help moku` in the MATLAB console to confirm installation.

## Supported Versions
- Windows - MATLAB 2013a+
- Linux - MATLAB R2013a+
- Mac - MATLAB 2014a+
## Examples
You can find example scripts for instruments in the **examples/** folder.

Here is a basic example of how to connect to a Moku:Lab, deploy the Oscilloscope and fetch a single data trace.

```Matlab
% Connect to your Moku:Lab's Oscilloscope instrument
m = MokuOscilloscope('192.168.69.100'); % Your Moku:Lab IP here

% Set the Oscilloscope timebase to be +-1msec
m.set_timebase(-0.001,0.001);

% Get a single frame of data with a 10-sec timeout period
data = m.get_realtime_data('timeout',10);

% Print the time-voltage data for both channels
data.time
data.ch1
data.ch2
```

## Troubleshooting


## Licensing

moku-MATLAB is covered under the MIT License (refer to the LICENSE file for details).

Refer to library source files for individual licensing details.
## Issue Tracking
Please log issues here on Github.