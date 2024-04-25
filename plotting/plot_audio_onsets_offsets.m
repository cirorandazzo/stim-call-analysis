% plot and breathing audio overlaid with detected onsets/offsets. can run in s3_segment_calls or segment_calls

close

trs = data.call_seg.one_call(1:15);
fs = p.fs;
stim_i = p.zero_point;



for i = numel(trs):-1:1
    tr = trs(i);

    figure;
    hold on;
    
    % plot(a(i, :));
    % y = audio_filt(tr, :);
    y = data.audio(tr, :);
    x = t(1:length(y), stim_i, fs);
    
    plot(x, y);
    % plot(smooth_audio(i, :), 'black');
    
    n_onsets = length(onsets{tr});
    n_offsets = length(offsets{tr});
    
    scatter(t(onsets{tr}, stim_i, fs), zeros([1 n_onsets]), 'red');
    scatter(t(offsets{tr}, stim_i, fs), zeros([1 n_offsets]), 'blue');
end


function r = t(x, stim_i, fs)
    % convert frames --> time (ms) zeroed at stim
    % r = arrayfun(@(a) (a-stim_i) * 1000/fs, x);

    % remain in frames
    r = x;

end