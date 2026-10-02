# Changelog

## VeryScore3 3.0 (2026-10)

VeryScore2 1.6, 1.7 and 1.8 (below) brought together in one program, with every file renamed `VS3_*`
(Alejandro Osorio-Forero, with Claude). Files are the same as in VeryScore2, in both directions.

- `VS3_main` starts the program; `VS3_display`, `VS3_tracesPlot`, `VS3_autoScoreTool`, `VS3_thermalTool`,
  `VS3_photometry`, `VS3_convertOpenEphys`, `VS3_summary`, `VS3_autoScoreClassic` (the VeryScore2 autoscoring) and `VS3_pref`.
- File > Convert Open Ephys recording (`VS3_convertOpenEphys`): the converter used until now (`ToVS2_2026`)
  in VeryScore3, with the same output (checked on 14 recordings), folders asked and remembered, its own `.npy`
  reader (no npy-matlab), and the converted file opened on request.
- Tools > Summary figure (`VS3_summary`): hypnogram, sigma activity (10-15 Hz, % of the NREM mean), temperature
  and photometry of the whole recording with the statistics of each state; clicking navigates the main window.
- Photometry display: the dF/F is scaled from its typical spread within one minute (five times taller than in
  VeryScore2 1.7 on an 8-h recording) and centred in its trace slot on every screen.
- Preferences are stored in the group `VeryScore3`; the ones set in VeryScore2 1.6-1.8 (python.exe, folders,
  photometry and auto-scoring choices) are taken over automatically.
- Auto-scoring library: the shipped recordings (`autoscore/VS3_autoLibrary.mat`) are never modified; your own
  recordings go to `autoscore/VS3_autoLibrary_local.mat` (ignored by git).
- Fixes of VeryScore2 behaviour:
  - Save: a file whose name ended in `t.mat` without underscore lost characters (`AH2_test.mat` became
    `AH2_te_bt.mat`); now `name_t.mat` and `name.mat` both become `name_bt.mat`.
  - Import randomly no longer needs the Statistics toolbox (`randperm` instead of `datasample`).
  - Rename files to bt refused every correctly named file (`sep ~= 7` instead of `numel(sep) ~= 7`) and failed
    when a single file was selected.
  - `ReduceBTfileSize.m`, called by File > Reduce file size, is now part of the folder.
  - In blind mode (Import randomly) the auto-scoring, photometry and thermal messages do not show the file name.
  - Reverse all changes dropped the transitions placed by hand, so the next Save wrote NaN into `bTrans`; it
    also showed a hidden temperature panel again.
  - Clicking the hypnogram left of 4 s or after the last epoch gave an error, and a click went one epoch too early.
- Thermal video (after a review of v1.6/1.8):
  - Parallel workers re-open the video when it changed (calibration added, converted again); before, they could
    return the old uncalibrated values labelled degC.
  - The hypnogram keeps the time range of the recording when the temperature panel is shown (a longer video or a
    large offset squeezed it).
  - A new analysis uses `Infos.StartTime` instead of the offset of the previous analysis, unless that offset was
    typed or estimated by you. Start times: fixed priority (StartTime first), a date alone is not used, a start
    time more than 12 h away from the video is ignored.
  - Serial run when the parallel pool cannot start; the workers' own error messages are shown; ROI functions of
    your own work on the pool.
  - The movement estimate reads the hot-spot position of each ROI method (hottestBlob gave nonsense), is not
    offered below a correlation of 0.3, and tells how flat it is and how precise the timestamps are.
  - hottestBlob's 3 K threshold is converted to counts on uncalibrated videos.
  - ROI method names and N are checked; the scoring file must be writable before the long extraction, and a
    failed save keeps the result; a camera calibration of another camera is refused before it is applied;
    temporary logs are deleted; the offset source is recorded correctly; VS3 always uses its own thermal code.
- Photometry (after a review of v1.7):
  - NaN samples (a few are interpolated, many are refused), flat channels, too short recordings for the
    exponential baseline (< 20 min after the skipped start) and a zero baseline give clear messages.
  - The fast bleaching time constant cannot be shorter than a third of the skipped start (its extrapolation to
    the start exploded); a warning when a fitted time constant sits at its limit.
  - The display scale comes from the fitted part; extreme extrapolated values are clipped on screen only.
  - One photometry channel per file: computing another one asks first and restores the raw trace of the first.
  - A purple carrier above the Nyquist frequency counts as no purple LED; int16 traces, BitVolts as text or as
    one value; the skipped time is remembered; a failed save keeps the result on screen; less memory at high
    sampling rates.

## VeryScore2 1.8 (2026-10-01)

- New auto-scoring (Tools > Auto-Scoring > Score this file): EEG band powers and EMG above 30 Hz per 4-s epoch,
  a linear discriminant model trained on a library of manually scored recordings, vetoed by the bimodal muscle
  tone, then adapted to the recording; uncertain epochs left unscored for review. 90-93 % agreement with a
  human scorer on recordings left out of the library (VeryScore1 autoscoring: 57-79 %).
- Tools > Auto-Scoring > Add this scoring to the library / Library contents.
- shift+b jumps to the next unscored epoch.
- The VeryScore1 autoscoring stays as Classic auto-scoring.

## VeryScore2 1.7 (2026-10-01)

- Tools > Photometry: dF/F of the selected trace (raw LED-modulated photometry channel) read at full rate from the
  file; lock-in demodulation of the 465 nm and 405 nm carriers; baseline from the purple signal or from a
  double-exponential bleaching fit; stored as `Photometry` and shown at loading; overview figure.

## VeryScore2 1.6 (2026-09)

- Tools > Thermal video: temperature of the animal from an Optris `.ravi` video (conversion to `.h5` with Python,
  ROI methods, alignment to the EEG by offset, start times or movement), stored as `Thermal`, shown in a panel
  above the hypnogram. Faster ROI extraction and parallel workers (2026-10-01).
- File > Edit file Infos works with files without the Intan `Configuration` field (Open Ephys).

## VeryScore2 1.5 and before (Lüthi lab)

- See the header of `VS3_main.m` and the history of `VeryScore2_For_Sleep_Scoring` in this repository
  (Romain Cardis 2018-2021, Georgios Foustoukos 2023-2024).
