function [f_maxes, amp_maxes] = fma(audio_calls, Fs)
% fma.m
% 2023.01.08 CDR
% 
% Given cell array where each cell contains audio data, return frequency of
% maximum amplitude for every cell.

f_maxes = zeros([length(audio_calls) 1]);
amp_maxes = zeros([length(audio_calls) 1]);

for tr=1:length(audio_calls)
    Y=fft(audio_calls{tr});
    L = length(audio_calls{tr});

    [amp_max, i_max] = max(abs(Y));

    f_max = Fs/L * i_max;

    f_maxes(tr) = f_max;
    amp_maxes(tr) = amp_max;

end

end

