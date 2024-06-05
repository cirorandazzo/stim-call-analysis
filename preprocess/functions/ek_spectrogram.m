function S = ek_spectrogram(filtsong, fs, threshold, n, overlap, f_low, f_high)
% ek_spectrogram.m
% EK
% 2023.12 CDR received
% 
% 
% 2023.12.18
% - renamed SPTH --> threshold (& lowercased other parameters)
% - removed filtering from here. do it before.
% 
% note from ek:
% - SPTH: threshold, send lower spectral values to zero (usually range 0.01-100)

w=hamming(n);
% filtsong=pj_bandpass(sound, fs, f_low, f_high, 'butterworth');

[S,F,T] = spectrogram(filtsong, w, overlap, n, fs);
T = [1 : size(filtsong, 2)] ./ (fs / 1000);

%Find entries with very low power + scale up. Makes display nicer.
pp = find(abs(S)<=threshold); 
S(pp) = threshold;
S = log(abs(S));

imagesc(T, flipud(F), S)
set(gca, ...
    'YDir', 'normal',...
    'ylim', [f_low, f_high], ...
    'xlim', [0, max(T)])

ylabel('Freq (Hz)')
xlabel('Time (ms)')

colormap(flipud(bone))

end