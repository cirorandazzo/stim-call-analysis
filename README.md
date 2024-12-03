# stim-call-analysis

Analysis for DM & PAm stimulation experiments, with or without HVC pharmacology.

Automated pipeline: `./automated_pipeline/main.m`

TODO: general description of pipeline.

Before running, add the following to path:

- `./automated_pipeline`
- `./functions`
- `./pharmacology_analyses`

## Per-Bird Pipeline

Some notes:

- Sections named "Pipeline Step #" happen in `pipeline.m`.
- `save_files_pipeline.m` is run after each step in pipeline.

### Parameter Files

Running the pipeline requires creation of parameter struct `p`. These are created by running a parameter file; these are named as bird_id.m (eg, `pk30gr9.m`). Most of these parameter files call `default_params.m`, which must be added to the path. Note that the order of parameter files matters when invoking `default_params`, since it may overwrite existing elements of the struct. See section "Parameters" below for list & description of parameters.

`main.m` works by getting all `.m` files in a directory of parameter files, then loading each and running `pipeline.m`.

### Pipeline Step 1: Load Data

Major function: `s1_load_raw`

This step loads data, with output `unproc_data`. When loading from `.rhs` or `.csv` files, each row of this struct represents a separate `.rhs` file.

There are three options for loading data. The relevant option is automatically selected given the extension of `p.files.raw_data`.

1. **Directory of `.rhs` files**:
2. **`.csv` batch file of `.rhs` directories**: used for pharmacology experiments to load multiple conditions. File should have columns: `folder`, `notes`, and at least one experimental parameter (eg, birdname, surgery_condition, drug, current, stimulation_duration).
    - Columns with names other than `folder` or `notes` are treated as experimental parameters and will be added to struct. Experimental parameters columns should be named valid matlab struct field names. In step 2, rows of `unproc_data` will be merged by these parameters.
    - `folder` should contain directory of `.rhs` files for this condition. If there are multiple data folders for one condition, add these as separate rows with the same experimental parameters - these will be merged.
    - `notes` is automatically ignored, but can be used to record notes about a given folder.
3. **preprocessed `.mat` file**

`unproc_data` structure:

- if `.mat` input, scalar struct with fields:
  - `breathing`: matrix of raw breathing data
  - `audio`: matrix of raw audio data
  - `stim`: stimulation trigger
  - `fs`: sample frequency
- if `.rhs` or `.csv` input, struct array:
  - fields
    - `breathing`, `audio`, `stim`, `fs` as in `.mat` condition (see above)
    - experimental parameters, from either `p.files.labels` or `csv` columns
    - `file`, substruct containing row of `dir('folder/**/*.rhs')` output tracking which rhs file these data came from
  - each row of struct corresponds to a single rhs file.

### Pipeline Step 2: Cut Trials

Major function: `s2_restructure`

Preprocessing step, outputs `proc_data`. Does the following:

- Cuts windows around stimulation (see `p.window`) into "trials"
- Stacks audio & breathing of each trial into matrices, 1 per experimental condition.
- Filters breathing data (`deq_br`; see `p.filt_breath`).

Each row of `unproc_data` corresponds to 1 rhs file. After step 2, each row of `proc_data` corresponds to a unique experimental condition (eg, drug). For non-pharmacology experiments, `proc_data` has 1 row per bird. For DM-stim + HVC-pharmacology experiments, `proc_data` usually has 2-4 rows per bird (baseline, gabazine, muscimol, respective washouts).

`proc_data` structure:

- As `unproc_data`. However:
  - `sound` is renamed `audio`
  - `stim` is deleted
  - `audio` and `breathing` matrices are cut into trials centered at stim onset (see above)
  - `breathing_filt` is created (`deq_br` on breathing trials)
  - Rows represent one condition instead of one rhs file (merges rhs files with same condition).

### Pipeline Step 3: Audio Segmentation of Calls

Major function: `s3_segment_calls`

Process audio & segment calls by amplitude threshold, outputs `call_seg_data`. Does the following:

- Filters, rectifies, and smooths (FRS) audio (`s3_segment_calls:filterRectifySmooth`)
- Segment calls with amplitude thresholding of FRS audio (`s3_segment_calls:segmentCalls`)
  - Noise thresholds are computed for each trial as (`p.call_seg.q`) * (median(pre-stim audio))
  - Eliminate short intervals (2 calls less than `p.call_seg.min_interval_ms` ms apart are merged)
  - Remove short calls (Delete calls shorter than `p.call_seg.min_duration_ms`)
  - Remove calls outside of reasonable stim window (Between frames specified in `p.call_seg.post_stim_call_window_ii`; in `s3_segment_calls` body)
- Sort trials according to call count & store trial #s
  - `no_calls`, `one_call`, `multi_calls`
- For `one_call` trials:
  - Cut & save call audio (raw: `audio_call`; FRS: `audio_filt_call`)
  - Compute acoustic features (`s3_segment_calls:getAcousticFeatures`)

`call_seg_data` structure as in `proc_data`. However:

- `call_seg`: new substruct storing call data
  - `noise_thresholds`: noise threshold per trial ((`p.call_seg.q`) * (median(pre-stim audio)))
  - `onsets` & `offsets`: Cell array containing call onsets/offsets (as array) for each trial as frame values with respect to trial onset (ie, `p.window.radius_seconds` seconds before stim onset).
  - `q`, `min_int`, `min_dur`: copies of `p.call_seg.q`, `p.call_seg.min_interval_ms`, `p.call_seg.min_duration_ms`
  - `no_calls`, `one_call`, `multi_calls`: trial numbers corresponding to each call count
  - *Data for just `one-call` trials*
    - `audio_filt_call`: cell containing
    - `acoustic_features` substruct for one call trials
      - `duration` (ms)
      - `freq_max_amp`, `max_amp_fft`: frequency of maximum amplitude (Hz), and the amplitude of that frequency  
      - `max_amp_filt`: Maximum amplitude of raw waveform
      - `spectral_entropy`: matlab function `pentropy`
      - `latencies`: latency from stim onset to call onset (ms)

### Pipeline Step 4

Major function: `s4_segment_breaths`

This function segments breaths from all trials in call_seg_data, outputs `call_breath_seg_data`.

- Zero-crossing algorithm for inspirations & expirations.
  - Roughly center breath wave around zero by subtracting median (more robust to high pressures associated with call)
  - Get rough estimate of pre-stim expirations (`ek_segmentBreaths_current`)
  - Center breath on mean of all full pre-stim breath cycles in trial (ie, from first to last pre-stim expiration)
  - Resegment breaths (`ek_segmentBreaths_current`)
- Derivative algorithm for inspiration onset (`s4_segment_breaths:getInspiratoryLatency`)
  - Take window of centered breath wave: stim onset to `p.breath_seg.stim_induced_insp_window_ms` ms after stim onset
  - Find time of minimum second derivative (ie, ). Intermediate smoothing after first derivative and before taking min of second derivative (moving mean with window size `p.breath_seg.derivative_smooth_window_f`).
- Normalized amplitudes
  - Inspiratory amplitude: minimum of centered breath wave in window: `p.call_seg.post_stim_call_window_ii`
  - Expiratory amplitude: maximum of centered breath wave in window: `p.call_seg.post_stim_call_window_ii`
  - Both normalized to min/max of `pre_stim_amp_normalize_window` (hardcoded in `s4_segment_breaths`, 1s before stim to stim onset)
- Respiratory rate
  - Get all pre-stim breath zero-crossings.
  - t = duration between first and last zero crossings (disregard whether insp or exp)
  - n = total # zero crossings
  - resp rate = (n/2)/t; ie, number of full breaths between these crossings.
  - n.b. For some conditions with low respiratory rate, only 1 insp or only 1 exp was found in the entire pre-stim window, so exp-to-exp or insp-to-insp timing is not always possible.

TODO: describe ZK's segment breath algorithm (`ek_segmentBreaths_current`)

`call_breath_seg_data`: call_seg_data with new additional field, `breath_seg` (struct array). each row is a trial, and contains subfields

- `error`: 0 if no error, else stores information about error with processing this trial. Most common error is with first/rough centering and segmentation
- `insp_amplitude`/`exp_amplitude`: min/max of centered waveform, normalized to pre-window (see above)
  - *Zero-crossing algorithm*
    - `centered`: recentered breathing data
    - {exps/insps}_{pre/post/peri}: breath zero crossings before/during/after defined stimulation window (see `p.breath_seg.pre_stim_ms` and `p.breath_seg.post_stim_ms`)
    - `latency_exp`: time to first expiratory zero-crossing (ms)
  - *Derivative algorithm*
    - `latency_insp`: latency to inspiration in ms, computed by derivative algorithm
    - `latency_insp_f`: same value in frames (useful for plotting)

### Save Breathing & Audio; Save Parameters

TODO: save breathing & audio description

### Pipeline Step: Individual Plots

Major function: `pipeline_plots`

Requires `do_plots=true` in `pipeline.m`.

Output plots at this step:

- latency histograms for:
  - expiration (stimulation -> expiratory 0 crossing)
  - inspiration (stimulation -> derivative thresholded inspiration)
  - call (stimulation -> audio thresholded call)
- breath traces: all breath traces of one-call trials overlaid with average breath trace
- breath traces + insp:  as above, but with green dots overlaid on each breath trace to show derivative thresholded inspiration

## Summary Analyses/Figures

Running `main.m` on multiple parameter files adds struct `summary_bird` to the workspace. Many fields of this are left blank for birds with multiple conditions (eg, pharmacology; see below).

Run `batch_plot_spectrograms.m` or `batch_plot_breaths.m` to plot spectrograms/breaths with call onsets/offsets."

### DM/PAm Stimulation (non-pharmacology)

To do subsequent DM/PAm analyses, run `dmpam_group_comparisons.m` *without clearing* `summary_bird`!"

> [!WARNING]
> The distributions stored in `summary_bird` generally only take data from trials where exactly one call was found in the audio data (see occurrences of indexing with `data.call_seg.one_call` in `main.m`).

> [!TIP]
> You can regenerate `summary_bird` from processed data by running `main.m` with `suppress_reprocess = true`.

`dmpam_group_comparisons.m`

1. `group_plot_all_stims`: Histograms which show multiple groups and merge all birds in a group. Uses data from all stimulations, not just stimulations where a call was detected by audio. Filenames prepended with `hist-ALL_STIM-`. Historgrams plotted:

- Inspiratory amplitude (normalized to prestim ampl)
- Expiratory amplitude (normalized to prestim ampl)
- Expiratory latency (ms)

2. Exclude birds with bad audio.
3. `make_group_summaries`: restructures `summary_bird` to `summary_group`, which merges all birds in a group. See function documentation for details of struct. Uses only trials where exactly 1 call was found in the audio data.
4. From `summary_group`, plot the following group histograms; files prepended with `group-`

- Audio segmented call latency
- Expiratory latency
- Inspiratory latency

5. Scatter plots of bird medians, using data from `summary_bird`.

- Expiratory latency (s)
- Inspiratory latency (s)
- Audio-segmented call latency (s)
- Inspiratory amplitude (norm to pre)
- Expiratory amplitude (norm to pre)
- Audio amplitude
- Evoked call success rate (% of stimulations)

6. Run group comparison statistics (`get_stats_dm_pam.m`; `ranksum`, Mann-Whitney U-test)

- For all birds/all stims:
  - exp_amplitude
  - insp_amplitude
  - latency_exp
- For call-evoking stims (audio seg) on birds with good audio:
  - call_success_rate
  - median_insp_lat

### DM-Stimulation + HVC Pharmacology

Pharmacology analyses are conducted in file `run_pharmacology_analyses.m` and directed according to `comparisons` structs (in `./pharmacology_analyses/comparison_directions`). For each bird, these structs provide data indices (which refer to indices in the saved data struct array) and assign a label to each comparison (usually "gabazine" vs "muscimol"). Also in comparisons direction files are variables:

- `data_path`: path to saved `call_breath_seg_data`, which has been renamed `data`.
- `bird_name`
- `surgery_state`: `"anesthetized`" or `"awake"`, for distinction on plots.

Note: ouput `figures/pharmacology-summary/pharmacology-stats.mat` contains the following structs (which are described below):

- `comparison_struct`
- `distributions`
- `p_vals`
- `summary_stats`
- `summary_stats_bird_condition`

> [!Note]
> Older runs lack `summary_stats_bird_condition` due to a bug.

> [!Important]  
> `summary_bird` will not be fully populated for HVC pharmacology birds, since it hasn't been implemented for multiple conditions.

1. `run_pharmacology_analyses:construct_bird_distributions`: constructs the `distributions` struct, which contains distributions of various measures. each row is a single condition for a single bird.

- cut data according to comparisons(i).ii_data
- if `options.SkipPlots == false`, plots the following. general filename format is `{data folder}/figures/pharmacology-summary/{birdname}/{birdname}-{comparison_label}-{measure}` (eg `figures/pharmacology-summary/bu69bu75/bu69bu75-muscimol-aud_amp.svg`)
  - Multi histograms (overlaid conditions)
    - Latency: inspiratory/expiratory/audio-segmented
    - Amplitude: inspiratory/expiratory/audio
    - Pre-stim respiratory rate
  - Inspiratory amplitude vs. expiratory amplitude
  - Timeseries (across stims)
    - respiratory rate
    - insp amplitude
    - exp amplitude
  - call success by inspiratory amplitude
- logic & plotting occur in `pharmacology_plot_pipeline`

2. Make `summary_stats_bird_condition`; each row refers to a single condition for a single bird.
3. Pre/post line plots. Median for each bird/condition.

- Plots show one-call trials unless filename lists 'all_stims'
- Saved as `figures/pharmacology-summary/{measure}-pre_post`

4. Make `comparison_struct` (during previous plotting step)

- Distribution of medians for each bird/condition, to run statistical test.

5. Run stats (MATLAB builtin `signrank`) for each comparison, generating structs:

- `p_vals`
- `summary_stats`

## Parameters

- `fs`: sample rate for data acquisition (Hz). 30000Hz for all files in these experiments.
- `files`: substruct containing general metadata about files & saving
  - `raw_data`: path to directory of `.rhs` files, `.csv` batch file, or processed `.mat` file (see step 1)
  - `bird_name`: string containing bird name.
  - `group`: string containing group identity. useful for dm/pam plotting
  - `labels`: for `.rhs` files, get experimental parameters to add to data struct from filename, sorting into different struct rows in step 2. empty cell to skip parsing. Eg, for format curr_freq_len_date_time.rhs -- eg '20uA_100Hz_50ms_230725_143022.rhs', pass {"current", "frequency", "length", [], []}.
  - `delete_fields`: fields to delete when saving structs. empty cell to save all
  - `save_folder`: folder to save processed data
  - `figure_folder`: folder to save figures created in pipeline
  - `save`: substruct containing save paths. Pass empty arrays to skip saving.
    - `save_prefix`: includes start of filename (eg, './data/birdname-', which can be used to save './data/birdname-call_seg_data.mat')
    - `figure_prefix`: same as `save_prefix`, but for saving figures
    - `fig_extension`: filetype to save figures. Pass without a period (eg, `svg` instead of `.svg`). Must be a filetype compatible with `saveas` for matlab figure
    - `unproc_save_file`: where to save unprocessed data (struct `unproc_data`) as `.mat` (post-step1)
    - `proc_save_file`: where to save processed data (struct `proc_data`) as `.mat` (post-step2)
    - `call_seg_save_file`: where to save audio-segmented data (struct `call_seg_data`) as `.mat` (post-step3)
    - `call_breath_seg_save_file`: where to save audio-segmented + breathing-segmented data (struct `call_breath_seg_data`) as `.mat` (post-step4)
    - `parameter_save_file`: where to save parameter struct `p` as as `.mat`
    - `breathing_audio_save_file`: where to save a copy of pared-down data (see step 'Save Breathing & Audio')
  - `to_plot`: figure types to plot for this bird (see `./automated_pipeline/pipeline_plots.m`)
- `window`: substruct containing information about cut stimulation trials
  - `radius_seconds`: time before and after stimulation to keep in each trial (in seconds). usually 1.5s, for total window length of 3s
  - `stim_i`: frame index of stimulation onset in window (should be `radius_seconds` * `fs` + 1)
  - `stim_cooldown`: framecount in which to consider 2 stimulation onsets as the same stimulation (eg, stim flickers off for 10 frames).
- `filt_breath`: breathing filter parameters struct. See matlab builtin `designfilt` for descriptions.
  - `type`
  - `FilterOrder`
  - `PassbandFrequency`
  - `StopbandFrequency`
- `audio_filt_smooth`: filter & smoothing options for audio (see step 3)
  - `f_low`: low cutoff frequency for filtering (Hz)
  - `f_high`: high cutoff frequency for filtering (Hz)
  - `filt_type`: filter type. allowed values are `'butterworth'` or `'hanningfir'`
  - `smooth_window_ms`: length of window (in ms) used for smoothing rectified audio data

*The following parameters are the most likely to vary between birds, and are often overwritten from default values.*

- `call_seg`: parameters for call segmentation from filtered/rectified/smoothed audio (see step 3)
  - `q`: audio threshold = `q` * (median amplitude of pre-stimulation audio)
  - `min_interval_ms`: minimum time (in ms) between 2 notes to be considered separate notes (else merged)
  - `min_duration_ms`: ms; minimum duration of note (In ms) to be considered (else ignored)
  - `post_stim_call_window_ii`: only check for call within these frames of the window (length 2 vector, in units of frames. eg, [100 200] will only check frames 100-200 of the trial). Also used as window for expiratory and inspiratory amplitude.
- `breath_seg`: parameters for breath segmentation (see step 4)
  - *for zero-crossing breath segmentation*
    - `min_duration_fr`: min time (FRAMES) between 2 insps or 2 exps.
    - `exp_thresh` & `insp_thresh`: threshold to consider zero crossing for breath segmentation; in pressure units. `exp_thresh` should be positive and `insp_thresh` should be negative. There can be some variation in these values.
    - `pre_stim_ms` and `post_stim_ms`: time (ms) before/after stim to consider breath crossings pre/post/peri-stimulation. eg, 0 and 10, respectively, will consider all breath crossings before the exact stimuluation onset frame 'pre-stim', all breath crossings ≥10ms after stim onset 'post-stim', and all else 'peri-stim'.
  - *for derivative measure of inspirations*
    - `stim_induced_insp_window_ms`: window after stimulation to check for inspiration onset (ms)
    - `derivative_smooth_window_f`: number of frames to smooth 1st/2nd derivatives
