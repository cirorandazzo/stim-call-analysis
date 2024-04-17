
% can run with any data struct containing audio

fs = 30000;
stim_i = 45001;

close
figure
hold on;
for i=2
    y = data.audio_filt(i,:);
    
    
    x = 1:length(y);
    x = t(x, fs);

    
    l = t([stim_i 5.1e4], fs);
    xlim(l);

    plot(x,y);
    
    
    thr = 5 * median(y);
    plot(l, [thr thr]);

end


function r = t(x, stim_i, fs)
    % convert frames --> time (ms) zeroed at stim
    r = arrayfun(@(a) (a-stim_i) * 1000/fs, x);
end