%% spontaneous_proc.m
% 2024.04.22 CDR
% segment calls & breaths from call expiration-aligned audio data

plotting = 0;

filename = '/Users/cirorandazzo/code/stim-call-analysis/data/spontaneous/gr56bu23_spontaneousDataMat.mat';

% get birdname from filename
re = '([a-z]{2}[0-9]{1,2}){1,2}';
[s,e] = regexp(filename, re);
bird = filename(s:e);

% load this bird's data with name 'data'
T = load(filename, bird);
data = T.(bird);
clear T s e re;


% rename fields for consistency with previous code
data.audio = data.audioMat;
data.breathing_filt = data.airMat;
data = rmfield(data, {'audioMat', 'airMat'});

%% PARAMETERS

p = default_params_spontaneous([]);

%% call segmentation

data = s3_segment_calls( ...
    data, p.fs, ...
    [], [], [], [], ...  % ignoring all filtering arguments
    p.call_seg.min_int, ...
    p.call_seg.min_dur, ...
    p.call_seg.q, ...
    p.zero_point, ...
    [p.call_seg.window_start p.call_seg.window_end], ...
    "nofilt");

% rename 'audio_filt_call' to 'call_audio'
data.call_seg.call_audio = data.call_seg.audio_filt_call;
data.call_seg = rmfield(data.call_seg, 'audio_filt_call');

if plotting
    %---deviation between breath & audio
    sooner = i_one_call(lats <= 0);
    later = i_one_call(lats > 20);
    
    i_one_call = data.call_seg.one_call;
    lats = [data.call_seg.acoustic_features.latencies{:}];

    figure;
    histogram(lats);
    title('call expir. vs. audio-seg call timing');
    subtitle("trials with 1 call only (n=" + int2str(length(lats)) + ")")
    xlabel('time deviation (ms)');
    ylabel('count');

    %---histogram of noise thresholds
    figure;
    histogram(data.call_seg.noise_thresholds);
    title('noise thresholds')
    

    %---histogram of # calls per audio row
    n_on = cellfun(@(x) numel(x), data.call_seg.onsets);
    n_off = cellfun(@(x) numel(x), data.call_seg.offsets);
    
    figure;
    histogram(n_on, 'BinWidth', 1, 'BinMethod','integers');
    title('number of detected calls per row')

    % hold on;
    % histogram(n_off, 'BinWidth', 1);
    % legend({'onsets', 'offsets'});
end

% remove acoustic features - ill-defined on rectified audio
data.call_seg = rmfield(data.call_seg, 'acoustic_features');


%% breath segmentation

data = s4_segment_breaths( ...
    data, ...
    p.fs, ...
    p.zero_point, ...
    p.breath_seg.dur_thresh, ...
    p.breath_seg.exp_thresh, ...
    p.breath_seg.insp_thresh, ...
    p.breath_seg.pre_delay, ...
    p.breath_seg.post_delay, ...
    [], ...
    [] ...
    );

% remove fields that are not useful/untrustworthy
data.breath_seg = rmfield(data.breath_seg, {'latency_exp', 'latency_insp_f', 'latency_insp'});

%% vicinity

data = s5_call_vicinity( ...
    data, ...
    p.fs, ...
    p.zero_point, ...
    p.call_vicinity.post_window, ...
    "PreCall", p.call_vicinity.pre_window ...
    );
