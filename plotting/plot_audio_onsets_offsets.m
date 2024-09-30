% plot and breathing audio overlaid with detected onsets/offsets (as dots)
close all

trs = [1:5];
fs = 30000;
stim_i = 45000;
xl = [-10 300];
% trs = data.call_seg.one_call(1:15);
% fs = p.fs;
% stim_i = p.zero_point;



for i = numel(trs):-1:1
    tr = trs(i);

    figure;
    title(tr)
    hold on;
    
    y = data.audio_filt(tr, :);
    x = t(1:length(y), stim_i, fs);
    plot(x, y);
    
    onsets = data.call_seg.onsets{tr};
    offsets = data.call_seg.offsets{tr};
    
    scatter(t(onsets, stim_i, fs), zeros(size(onsets)), 'red');
    scatter(t(offsets, stim_i, fs), zeros(size(offsets)), 'blue');
    hold off;
    xlim(xl);
end


function r = t(x, stim_i, fs)
    % convert frames --> time (ms) zeroed at stim
    r = arrayfun(@(a) (a-stim_i) * 1000/fs, x);

    % remain in frames
    % r = x;

end