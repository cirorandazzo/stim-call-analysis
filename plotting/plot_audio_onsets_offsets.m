% plot audio overlaid with detected onsets/offsets. can run in s3_segment_calls or segment_calls

close

i = 2;
fs = 30000;
stim_i = 45001;


figure;
hold on;

% plot(a(i, :));
y = audio_filt(i, :);
x = t(1:length(y), stim_i, fs);

plot(x, y);
% plot(smooth_audio(i, :), 'black');

n_onsets = length(onsets{i});
n_offsets = length(offsets{i});

scatter(t(onsets{i}, stim_i, fs), zeros([1 n_onsets]), 'red');
scatter(t(offsets{i}, stim_i, fs), zeros([1 n_offsets]), 'blue');

function r = t(x, stim_i, fs)
    % convert frames --> time (ms) zeroed at stim
    % r = arrayfun(@(a) (a-stim_i) * 1000/fs, x);

    % remain in frames
    r = x;

end