# VeryScore3

This software allows you to score mouse sleep (wakefulness, NREMS, REMS) in 4 second epochs.

VeryScore3 is the continuation of **VeryScore2**, written by Romain Cardis and Anita Lüthi in the Lüthi lab (University of Lausanne), with later updates by Georgios Foustoukos. It opens the same files and saves the same scoring, so files can go back and forth between VeryScore2 and VeryScore3. What is new:

- **Auto-scoring** that learns from scored recordings and adapts to each new one (about 90 % agreement with a human scorer, as good as a second human)
- **Thermal video**: the temperature of the animal from an Optris thermal camera, in a panel above the hypnogram
- **Photometry**: dF/F of a fibre photometry channel recorded with the EEG
- Everything in one program, `VS3_main`. See CHANGELOG.md for the full list.

_Dedicated to Romain Cardis and Anita Lüthi, who wrote VeryScore2 and shared it with all of us._


## Installation

1. Add the folder `VeryScore3_For_Sleep_Scoring` to the MATLAB path (the subfolders are added by the tools when they need them).
2. Type `VS3_main` and import a file in the "File" menu.

Requirements: MATLAB R2022b or newer (tested with R2024b), Signal Processing Toolbox. Optional: Parallel Computing Toolbox (faster thermal video analysis), Image Processing Toolbox (only for the `hottestBlob` thermal ROI method), Python 3 with `numpy` and `h5py` (only to convert thermal videos). The Statistics toolbox is not needed.

If VeryScore2 is also on your MATLAB path, remove it: both have files with the same names (the thermal code, `renameFileToBt`, ...).


## Files

Simply launch VS3_main and import a file obtained with Simply2Read (or any .mat file in the same format) in the "File" menu.
The files should be named like this:

AnimalName_recordingNumber_condition_t.mat

A file holds the variable `traces` (one row per channel) and a structure `Infos` with at least the sampling rate `Infos.Fs`. Optional: `Infos.Channel` or `traceName` (channel names), `Infos.StartTime` (time of the first sample, used to align a thermal video). VeryScore3 saves the scoring as `b` (one letter per 4-s epoch) and `bTrans`, the temperature as `Thermal` and the dF/F as `Photometry`, all in the same file.

Your raw traces now appear.

**Important notice: All the display changes you will do on the traces, such as filters, gain changes or supressing traces are not saved in the file. The only thing saved is the b string containing your scoring (and the Thermal and Photometry results when you compute them). This means you should not be afraid to make display changes to ease your scoring.**

**Second notice: In the lab we are using super nintendo USB controllers to score. Coupled with a small software such as JoyToKey, you can score much faster and more confortably (https://joytokey.net/en/). We provide a configuration for JoyToKey that is prepared for super nintendo controllers in the VeryScore3 folder (JTK_scoring.cfg).**


## Naming your traces
It is advised at this step to give names to your traces, especially if you have more than 2. To do so, you need to go into:

File > Edit file Infos

There you should choose to create a **New** field.

The new field name SHOULD be: **Channel**
now in the Field content put the trace labels between commas such as: EEG, EMG, S1, CA1
You can name them whatever.

Now go to:

**Tools > Reload Names from Infos**

You should see the names on the right of the traces.

Before Scoring:

You can select the traces by clicking on them. The selected ones are orange.

Once selected, you can filter the trace(s) in the menu **Traces > Filter traces**

If your EMG or EEG is composed of two traces, you can "bipolarize" them to get the difference betweem the two.

Select two traces > **Traces > Bipolarize**

This simulates a referencing of one to the other.

To auto-score the file: **Tools > Auto-Scoring > Score this file...** (see **Auto-scoring** below), then correct it.


## Moving around and scoring

Left: **a**

right: **d**

next transition to the left: **left arrow**

next transition to the right: **right arrow**

increase gain of all traces: **up arrow** (when none selected or of the selected traces only)

decrease gain of all traces: **down arrow** (when none selected or of the selected traces only)

WAKE epoch: **w**

NREM epoch: **n**

REM epoch: **r**

WAKE artifact: **1**

NREM artifact: **2**

REM artifact: **3**

Microarousal: **m**

Whatever purple epoch: **f**

Moving the selected trace up and down in position: **shift+arrow**

Next epoch of a state: **shift+w**, **shift+n**, **shift+r**, **shift+m**, **shift+f**, and **shift+b** for the next unscored epoch (the uncertain epochs left by the auto-scoring)


## Advanced functions

**File >**

**Import:** Let you import a new file.

**Import randomly:** Let you select multiple files and give them for you to score in a random order without knowing which one. This is very useful in case you need to score your files in a blind manner. We are all subjected to treatment biases so doing this removes this concern.

**Save:** Save your current scoring. The file will then receive a **b** in its name to show that is contains scoring data (`name_t.mat` and `name.mat` become `name_bt.mat`). If you load that file again, the saved scoring will appear.

**Edit file Infos:** This allows you to add field to the Infos structure contained in the file. You can precise treatments, important time points, or whatever you would like to use for future analysis with this file. Like mentionned above, you can create the field **Channel** to add names to your traces. An idea is to put the name of the person that did the scoring.

**Reduce file size:** We noticed that loading the whole file and saving it again all in one shot sometimes reduces the file size. If size is a problem for you, you can try this function once you have a file loaded.

**Rename files to bt:** renames recordings named like `date_name1_name2_name3_name4_condition_AnimalN_n.mat` (Symply2Read) to `name_0n_condition_t.mat`.

**Tools >**

**Auto-Scoring:** score the file automatically, teach the auto-scoring with your corrected scorings, or run the classic autoscoring of VeryScore2. See **Auto-scoring** below.

**Reload Names from Infos:** Once the field **Channel** exists in Infos and contains the trace names, you can load the names for them to appear on the chart.

**Take a snapshot:** It takes a snapshot of the current window, essentially reploting the current view in a new figure. You can then save the figure to keep track of your nicest spindles or show irregularities to your collegues.

**Thermal video:** see **Thermal video** below.

**Photometry:** see **Photometry** below.

**Traces >**

**Lock YLim:** The Y-limit of the chart is dynamically updated to see all the traces. While scoring, you sometimes have big artifacts that would mess up the view. You can lock the YLim for it not to move. It is then more confortable to score.

**Filter traces:** Allows to apply filters to selected traces. Three filters are available: >0.75 Hz, >25 Hz, <25 Hz. We typically filter >0.75 Hz for EEGs and LFPs and >25 Hz for EMGs.

**Bipolarize:** Create a new trace from the difference of two selected traces. You can choose to keep the two original or not.

**Change gain * 1000:** This allows to change the gain massively, instead of using the arrows up and down.

**Notch:** Apply a notch on the selected traces. You can use 50 hz or 60 hz notches. We record our animal within faraday cages so we usually don't require notches.

**Supress selected traces:** If a specific trace in not needed for your scoring, or you want to not see a stimulation trace, you can select it and supress it from the display. The trace will still exist in the file and would appear if you load it again.

**Swap traces positions:** Select two traces and swap their position on the display. This change will not affect the ordering of the channel within the file. This is for display purpose only.

**Reverse gain and filter:** If a trace is unreadable due to a false manipulation or if you want to reset it to raw data, you can reverse the changes made to it.

**Reverse all changes:** Returns the display of the traces to the original state at the moment of loading the file. This will not affect your scoring, it reverses only the display (the dF/F and the temperature panel are shown as at loading; the transitions you placed by hand are kept).

**Width >**

This menu allows to change the view window to zoom in or out on the x-axis. I prefer to score in 40 s-windows, Alejo prefers in 32 s-windows for example.


## Auto-scoring

**Tools > Auto-Scoring > Score this file...** scores wake, NREM and REM in about 2 s for 8 h of recording (`VS3_autoScoreTool.m`).

1. Choose the EEG channel(s) and the EMG channel(s), one or two of each. No filtering is needed first. The choice is remembered for files with the same channel names. With no remembered choice: the channels named EEG / EMG, otherwise EMG = channels 1-2 and EEG = channels 3-4.
2. If the file already contains a partial scoring, tick **Keep the epochs already scored and learn from them**: they stay as they are and the model is calibrated on them. Scoring the first 30 min by hand before launching it helps a lot on a new animal or setup.
3. Epochs where the model is not sure (probability < 0.6) stay unscored (**b**, blue). **shift+b** jumps to the next one. Then check the transitions with the arrows as usual.

How it works: for every 4-s epoch, the EEG power in 8 bands (0.5-45 Hz) and the theta/delta ratio are computed for each EEG; the EMG RMS above 30 Hz (with 50/60 Hz notches) for each EMG and for the difference of the two EMGs, which cancels the EEG picked up by the neck electrodes. The features are normalized within the recording and the two epochs before and after are added as context. A linear discriminant model is trained on a library of manually scored recordings; the muscle tone, which is bimodal (awake / asleep) in every recording, vetoes its obvious mistakes; the model is then trained again on the library plus the confident epochs of the recording, so that it adapts to the animal, the electrodes and the amplifier.

**The library.** VeryScore3 comes with 4 recordings (mice Os21 and Li15, 8 h each, manual scoring by AO) in `autoscore/VS3_autoLibrary.mat`. **Add this scoring to the library...** adds the file you just corrected to your own library (`autoscore/VS3_autoLibrary_local.mat`, not shared through git), so that the auto-scoring learns your animals, electrodes and scoring style. **Library contents...** lists all recordings and lets you remove yours.

Validation: each recording scored with a library made without it, compared with the manual scoring (AO).

| | agreement | kappa | REM F1 |
|---|---|---|---|
| Auto-scoring, 2 EEG + 2 EMG | 89.8-92.9 % | 0.82-0.87 | 0.87-0.93 |
| Same, library from the other mouse only | 82.8-93.5 % | 0.69-0.88 | 0.79-0.92 |
| Auto-scoring, 1 EEG + 1 EMG | 86.7-89.6 % | | |
| Second human scorer (JF) | 87.9-93.0 % | 0.79-0.88 | 0.56-0.84 |
| Classic autoscoring (VeryScore2) | 56.7-79.1 % | 0.29-0.63 | 0.13-0.41 |

See `autoscore/validation_200124_Os21_BL1.png`. Artifacts (1/2/3) and microarousals (m) are not detected: they are scored as their state.

**Classic auto-scoring (VeryScore2, selected traces)...:** the autoscoring of VeryScore2: filter the EEG over 0.75 Hz and the EMG over 25 Hz, select both EEG and EMG, then launch it. Its blue epochs are _unknown_ and represent potential changes during long NREMS sleep bouts. This is oversensitive on purpose and allows not to miss any events such as microarousals.


## Thermal video (temperature panel)

If the animal was filmed with an Optris thermal camera (PIX Connect `.ravi` recording) during the EEG recording, VeryScore3 extracts the temperature of the animal from the video and shows it in a panel just above the hypnogram, on the same time axis. The panel shows the value of every video frame (grey), the mean per 4-s epoch (red), the current position and, on the right, the temperature of the epoch you are scoring. Clicking in the panel navigates like the hypnogram.

**Tools > Thermal video >**

**Analyse video (.ravi / .h5)...:** Select the `.ravi` of the loaded recording (or a `.h5` already converted) and fill in the options: ROI method, number of hottest pixels averaged (N), and the video/EEG offset in seconds or as the EEG start time. The tool then:

1. converts the `.ravi` once into a compact `.h5` next to it (Python, a few minutes, progress bar with cancel). If the `.h5` already exists it is reused.
2. extracts one temperature per frame with the ROI method (`hottestN` = mean of the N hottest pixels of the frame, default N = 50; `hotspotWindow` and `hottestBlob` are more robust when several warm objects are in the image; your own methods go in `thermal\roi_methods\roi_<name>.m`). About 1 min for a 5-h video; with the Parallel Computing Toolbox (used automatically for videos longer than about 3 h) about 30 s the first time in a MATLAB session, while the workers start, and about 10 s afterwards.
3. puts the values on the time base of the scoring (one value per 4-s epoch, same indexing as the scoring string `b`), checks with the movement seen in the video whether the offset agrees with the wake epochs, and stores everything as the variable **Thermal** in the scoring file (`Thermal.valueEpoch`, `Thermal.t2Hz` / `Thermal.value2Hz` per frame, `Thermal.valueFs` per EEG sample, `Thermal.unit`, `Thermal.offset`, ...).

The next time the file is loaded, the panel appears automatically.

Reading the panel: during wake the value also follows the movement of the animal. A moving animal smears the hottest pixels of the 2-Hz frames and looks colder (in our recordings still wake was warmer than NREM, moving wake colder), so compare states with this in mind.

**Show temperature panel:** hide or show the panel (the data stay in the file).

**Change video/EEG offset...:** the offset is the video time (seconds since the first frame) at which the EEG recording started: 0 when both were started together, positive when the EEG started after the video. You can also type the EEG start time instead. Changing it re-aligns the stored values without touching the video.

**Alignment from timestamps.** The video knows when it started (the camera metadata holds the clock of the recording PC). If the scoring file knows when the EEG started, the offset is computed for you: `Infos.StartTime` (written by Open Ephys converters, or added with File > Edit file Infos, e.g. `2026-09-07 12:44:07`), or the Intan time token in the file name (`..._260907_124407_...`), or typed in the dialog. A date without time of day is not used, and a start time more than 12 h away from the video start is ignored with a warning. Otherwise the tool uses the offset of the previous analysis of the file, or assumes both recordings were started together (offset 0) and checks that against the movement in the video. The two computers' clocks must agree for this to be exact.

**Estimate offset from movement:** cross-correlates the movement of the hot spot in the video with the wake epochs of your scoring and proposes the best offset (score the file first, at least roughly). Its resolution is a few seconds: when the offset comes from the start times of the two recordings, keep it.

**EEG start time from Open Ephys recording...:** select the `sync_messages.txt` of the Open Ephys recording the file was made from (`<recording>\experiment1\recording1\sync_messages.txt`). The exact time of the first EEG sample is computed from the software time written there and stored as `Infos.StartTime`, and the temperature is re-aligned with the offset that follows from it and from the video start time.

**Add camera calibration (degC) to video...:** the `.ravi` contains energy counts, not degrees. Without the characteristic curve of the camera (`Kennlinie-<serial>-<lens>-M20-100.prn`, kept by PIX Connect in `%APPDATA%\Imager\Cali` on the recording PC) the panel shows counts, which are proportional to the temperature (about 40 counts per kelvin). Use this item once you have the file: it is copied into `thermal\calibration`, added to the `.h5`, and the analysis is run again in degC.

**Select python.exe...:** the conversion needs Python 3 with `numpy` and `h5py` (`pip install numpy h5py`). Python is looked for automatically the first time and remembered; use this item to point to another one.

The analysis code is in the `thermal` folder (`ThermalH5`, `thermal_roi_timeseries`, `thermal_align_to_eeg`, `estimate_offset`, `roi_methods`, `python`), the tool that drives it from the menu is `VS3_thermalTool.m`.


## Photometry (dF/F)

Fibre photometry recorded on an analog input (for example `ADC1` of an Open Ephys board, with the two LEDs modulated at 217 and 322 Hz) is stored in the file as the raw detector signal. On screen that trace looks flat: VeryScore3 downsamples every trace to 200 Hz for display, which removes the LED carriers. The photometry tool reads the channel from the file at its full sampling rate and turns it into dF/F.

**Tools > Photometry >**

**Selected trace to dF/F...:** click on the photometry trace so that it is orange, then choose this item. You are first asked which baseline F0 to use, because it depends on the sensor:

- **Purple signal (405 nm):** F0 is the purple channel fitted onto the signal (linear fit, leaving out the first 600 s). It removes bleaching and movement together, and is the right choice for sensors whose 405 nm response does not depend on the ligand.
- **Exponential decay:** F0 is a double-exponential bleaching fit of the signal itself (robust fit on its 1-Hz means, leaving out the first 300 s). The purple channel is treated the same way and only kept as a control.

Then you can check the carrier frequencies (217.38 Hz for the 465 nm LED and 322.57 Hz for the purple one; the exact values are measured in the data within 2 Hz) and the time left out at the start. The choices are remembered for the next file. The dF/F of the time left out at the start is an extrapolation of the baseline; you are warned when the bleaching fit is poorly constrained (a time constant at its limit). The exponential decay needs at least 20 min after the time left out.

The selected trace is replaced by the dF/F, scaled to about the height of one trace slot, and its name gets the suffix `dF/F`. A file holds the dF/F of one photometry channel: computing another channel replaces it (you are asked first). The values in % are stored in the file as the variable **Photometry** (`Photometry.time` in seconds since the first sample, `Photometry.dff` in % at 20 Hz, `Photometry.signal` and `Photometry.iso` the two carrier amplitudes in V, `Photometry.baseline`, `Photometry.dffIso` the purple control, `Photometry.method`, `Photometry.fit`, ...). The next time the file is loaded, the dF/F is shown in place of the raw channel. **Traces > Reverse gain and filter** shows the raw trace again.

**Show dF/F overview figure:** the carrier amplitudes with the fitted baseline, the dF/F and the purple control over the whole recording. Look at it once per recording to check the fit.

How it is computed: the channel is multiplied by the cosine and sine of each carrier, low-pass filtered (2-s Kaiser filter, 8 Hz) and decimated to 20 Hz; the amplitude of each LED is `2*hypot(I, Q)`; dF/F = 100 × (signal − F0) / F0. The tool refuses a channel without carrier, and a detector output stuck at the ADC ceiling (4.59 V). Files whose ADC channels were stored a million times too small by an early Open Ephys converter (September 2026) are recognised and corrected before computing. The code is in `VS3_photometry.m`; `VS3_photometry('compute', x, fs, 'method', 'purple')` runs the computation on a signal in volts (add `'volts', false` for other units).


## Credits

- **VeryScore2** (2018-2021): Romain Cardis and Anita Lüthi, Lüthi lab, Department of Fundamental Neurosciences, University of Lausanne, with updates by Georgios Foustoukos (2023-2024). VeryScore1's autoscoring is kept as the classic auto-scoring.
- **VeryScore3** (2026): Alejandro Osorio-Forero (Netherlands Institute for Neuroscience), written with Claude (Anthropic): auto-scoring, thermal video, photometry, unification.
- If you use VeryScore in published work, please cite the Lüthi lab as described in the README and CITATION.cff at the root of this repository.

**In the name of the Lüthi lab, we wish you a good scoring!**
