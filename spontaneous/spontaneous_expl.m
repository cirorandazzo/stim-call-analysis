%% spontaneous_expl.m
% 2024.04.22 CDR
% look at some sample audio & breathing data for spontaneous calls


filename = '/Users/cirorandazzo/code/stim-call-analysis/data/spontaneous/gr56bu23_spontaneousDataMat.mat';

% get birdname from filename
re = '([a-z]{2}[0-9]{1,2}){1,2}';
[s,e] = regexp(filename, re);
bird = filename(s:e);

% load this bird's data with name 'data'
T = load(filename, bird);
data = T.(bird);
clear T s e re;

%% plot audio + breathing subplots for some trials
% PARAMETERS

fs = 32000;
zero_point =  fs + 1;  % 1 second padding before breath-aligned call
xl = [-.1 .1];

% PLOT
trs = sooner;

for i=1:length(trs)
    tr = trs(i);

    % breathing = data.airMat(tr, :);
    % audio = data.audioMat(tr, :);

    breathing = data.breathing_filt(tr, :);
    audio = data.audio(tr, :);

    assert(length(breathing) == length(audio));
    x = minus( 1:length(breathing), zero_point) / fs;

    figure;
    subplot(2,1,1);
    plot(x, audio)
    title(string(bird) + ", tr " + int2str(tr));

    xlim(xl);

    subplot(2,1,2);
    plot(x, breathing);
    xlabel('time from call exp onset (s)')

    xlim(xl)

end

%% plot mean audio + breathing

xl = [-.1 .1];

breathing = mean(data.airMat, 1);
audio = mean(data.audioMat, 1);

assert(all(size(data.airMat) == size(data.audioMat)));
n_trs = size(data.airMat, 1);

x = minus( 1:length(breathing), zero_point) / fs;

figure;
subplot(2,1,1);
plot(x, audio)
title(string(bird) + " mean audio/breathing" );
subtitle("n=" + n_trs + " spont calls");

xlim(xl);

subplot(2,1,2);
plot(x, breathing);
xlabel('time from call exp onset (s)')
xlim(xl)
