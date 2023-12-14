% dmStim_hvc_preProcessing.m
% EK
% 2023.12 edited by CR
% 
% pre-processing for DM stim with HVC pharmacology
% 

clear;

bird = 'pu65bk36';
data_root = "/Users/cirorandazzo/ek-spectral-analysis/pu65bk36/";

%% == design filter for zero phase filtering ==
N = 30;
Fpass = 400;
Fstop = 450;
fs = 30000; 

% Design method defaults to 'equiripple' when omitted
deq = designfilt('lowpassfir','FilterOrder',N,'PassbandFrequency',Fpass,...
  'StopbandFrequency',Fstop,'SampleRate',fs);

%% get filelist

file_list = loadFileList(data_root);


%% load data

% to load only a certain condition, pare dowen file_list
% TODO: add loadbar

start = tic;
for i = length(file_list):-1:1   % create struct backwards, preallocates for speed
    filestart = tic;

    fn = file_list(i).name;
    path = file_list(i).folder;

    [~, c] = evalc("ek_read_Intan_RHS2000_file(fn, path)");  % evalc streams command window output into first var

    data(i).drug =  file_list(i).drug;
    data(i).current=file_list(i).current;    

    data(i).fs =    c.frequency_parameters.amplifier_sample_rate;
    data(i).sound = c.board_adc_data(1, :);
    data(i).stim =  c.board_dig_in_data; %stim_data(stimChan, :);
    data(i).breathing=c.board_adc_data(2, :);

    clear c;

    elapsed = toc(filestart);
    disp('Loaded file ' + string(i) + ' (' + elapsed + 's)' );
end
elapsed = toc(start);
disp("Finished loading. Total time: " + elapsed + "s")

% save("/Users/cirorandazzo/ek-spectral-analysis/unproc_data.mat","data")

%% call params saline
% call amplitude, pitch, duration, latency, insp depth, insp peak time
latency.saline = [];
expAmp.saline = []; pitch.saline = []; dur.saline = []; inspPeak.saline = []; inspPeakT.saline = [];
fs = data(1).fs;

dataMat.breathing.saline = [];
dataMat.audio.saline = [];

for i = 1 : length(data)
    stim = find(data(i).stim > 0.5);
    stimT = stim(data(i).stim(stim - 1) < 0.5);
    for j = 1 : length(stimT)
        if length(data(i).breathing) < stimT(j) + fs || stimT(j) - fs < 1
            continue
        end

        % == filter data ==
        f = filtfilt(deq, data(i).breathing(stimT(j) - fs : stimT(j) + fs)) + 0.2;

        % == re-center data ==

        dataMat.breathing.saline = [dataMat.breathing.saline; f];
        dataMat.audio.saline = [dataMat.audio.saline; data(i).sound(stimT(j) - fs : stimT(j) + fs)];

        breathing = f(fs + 50 * fs / 1000 : end);
        call = find(breathing > 0);

        latency.saline = [latency.saline call(1) * 1000 / fs + 50];
        expAmp.saline = [expAmp.saline max(breathing(call(1) : call(1) + 300 * fs / 1000)) / max(data(i).breathing(stimT(j) - 1000 * fs / 1000 : stimT(j)))];
        
        [M, I] = min(data(i).breathing(stimT(j) : stimT(j) + 100 * fs / 1000));
        inspPeak.saline = [inspPeak.saline M / abs(min(data(i).breathing(stimT(j) - 500 * fs / 1000 : stimT(j))))];
        inspPeakT.saline = [inspPeakT.saline I  * 1000 / fs];
    end
end

% figure
% nhist(expAmp.saline)

%% == plot stuff across conditions ==

figure; nhist(exp_amp, 'samebins', 'binfactor', 2)
xlabel('evoked expiration amplitude')
set(gca, 'tickdir', 'out', 'fontsize', 30)

figure; nhist(insp_peak, 'samebins')
xlabel('evoked insp amplitude')
set(gca, 'tickdir', 'out', 'fontsize', 30)

figure; nhist(insp_peak_t, 'samebins')
xlabel('evoked insp peak latency (ms)')
set(gca, 'tickdir', 'out', 'fontsize', 30)

%% plot outliers

ind = find(insp_peak_t.gabazine < 40);

for i = ind
    figure
    plot(dataMat.breathing.gabazine(i, :))
end

%% == figure out insp onset latency... ==
% N = 30;
% Fpass = 100;
% Fstop = 430;
% Fs = 2000; 
% 
% % Design method defaults to 'equiripple' when omitted
% deq = designfilt('lowpassfir','FilterOrder',N,'PassbandFrequency',Fpass,...
%   'StopbandFrequency',Fstop,'SampleRate',fs);

% use derivative
threshD = -1e-3;
threshDD = -1.5e-6;

inspOn = [];

dMat = [];
ddfMat = [];

for i = 1 : length(dataMat.breathing.saline)
    % smooth data
    sf = smoothdata(dataMat.breathing.saline(i, :), 'gaussian', 10 * fs / 1000);

    % take derivative
    d = diff(sf);
    dd = diff(d);
    ddf = filtfilt(deq, dd);

    dMat = [dMat; d];
    ddfMat = [ddfMat; ddf];

%     ind = find(ddf(fs - 50 * fs / 1000 : end) < threshDD);
    [~, insp] = min(ddf(fs : fs + 50 * fs / 1000));

    inspOn = [inspOn insp];
   
end

%% plot examples

for i = 1 : 10
    figure; hold on; plot(dataMat.breathing.saline(i, :)), 'k'; scatter(inspOn(i)  + fs, 0, 'filled', 'k'); scatter(fs, 0, 'filled', 'r')
end

%% plot examples of stim
i = 6;

stim = find(data(i).stim > 0.5);
stim_t = stim(data(i).stim(stim - 1) < 0.5);
stim_x = [];
for j = 1 : length(stim_t)
    stim_x = [stim_x [stim_t(j) : stim_t(j) + 50 * data(i).fs / 1000 - 1]];
end
stim_y = ones(length(stim_x), 1) * 0.8;

x = [1 : length(data(i).breathing)] * 1000 / data(i).fs;
breathing = lowpass(data(i).breathing, 200, data(i).fs);
figure; plot(x, breathing + 0.2, 'k', 'linewidth', 1);
hold on;
scatter(stim_x * 1000 / data(i).fs, stim_y, 'r','filled')

xlim([1 5000]); ylim([-2 2])
set(gca, 'tickdir', 'out')

%% stim-call latency
% latency.saline = [];
latency.gabazine = [];
% latency.muscimol = [];
fs = data(1).fs;

for i = 1 : length(data)
    stim = find(data(i).stim > 0.5);
    stim_t = stim(data(i).stim(stim - 1) < 0.5);
    for j = 1 : length(stim_t)
        breathing = data(i).breathing(stim_t(j) + 50 * fs / 1000 : end) + 0.2;
        call = find(breathing > 0);

%         latency.muscimol = [latency.muscimol call(1) * 1000 / fs + 50];
%         latency.saline = [latency.saline call(1) * 1000 / fs + 50];
        latency.gabazine = [latency.gabazine call(1) * 1000 / fs + 50];
    end
end

% plot stim-call latency
figure
nhist(latency, 'samebins', 'linewidth', 3)
xlabel('stim-call latency (ms)')
set(gca, 'tickdir', 'out', 'fontsize', 40)

%% evoked expiratory amplitude
% amp10.saline = [];
amp10.muscimol = [];

% amp14.saline = [];
% amp14.gabazine = [];


for i = 1 : length(data)
    stim = find(data(i).stim > 0.5);
    stim_t = stim(data(i).stim(stim - 1) < 0.5);
    for j = 1 : length(stim_t)
        if stim_t(j) + 400 * fs / 1000 > length(data(i).breathing) || stim_t(j) - 300 * fs / 1000 <= 0
            continue
        end
        breathing = data(i).breathing(stim_t(j) + 50 * fs / 1000 : stim_t(j) + 400 * fs / 1000) + 0.2;
        amp = max(breathing) / max(data(i).breathing(stim_t(j) - 300 * fs / 1000 : stim_t(j)) + 0.2);

%         amp14.saline = [amp14.saline amp];
%         amp14.gabazine = [amp14.gabazine amp];
% 
%         amp10.saline = [amp10.saline amp];
        amp10.muscimol = [amp10.muscimol amp];
    end

end

% plot evoked amp
% figure
% nhist(amp14, 'samebins', 'linewidth', 3)
% xlabel('normalized evoked expiratory amplitude')
% set(gca, 'tickdir', 'out', 'fontsize', 40)

figure
nhist(amp10, 'samebins', 'linewidth', 3)
xlabel('normalized evoked expiratory amplitude')
set(gca, 'tickdir', 'out', 'fontsize', 40)

%% create matrix of data aligned to stim onset
clear dataMat

fs = data(1).fs;
thresh = 0.2;

preWin = 2000 * fs / 1000;
postWin = 2000 * fs / 1000;

% x = data.chan;
% chans = {amplifier_channels.native_channel_name};

dataMat.breathing = [];
dataMat.audio = [];
dataMat.stim = [];

for k = 1 : 1 %length(chans)
%     eval(['dataMat.chan', chans{k}, ' = []']);
    
    for i = 1 : length(data)
        i
        if k == 1
            breathFilt = lowpass(data(i).breathing, 200, fs);
%             breathFilt = smoothdata(breathFilt, 'gaussian', 70 * fs / 1000);
        end
        
        stim = data(i).stim; % == blank stimulation artifact ==
%         blanked = data(i).chan(k, :);
%         blanked(find(stim > 0.1)) = 0;

%         chanFilt = highpass(blanked, 250, fs);
%         chanRect = sqrt(chanFilt .^2);
%         chanSmoothGauss = smoothdata(chanRect, 'gaussian', 20 * fs / 1000);

        % == find stim times ==
        stim = find(data(i).stim > 0.5);
        stimTimes = stim(data(i).stim(stim - 1) < 0.5);
        data(i).stimTimes = stimTimes;

        for j = 1 : length(stimTimes)
            if stimTimes(j) + postWin > length(breathFilt) || stimTimes(j) - preWin < 0
                break
            end
%             eval(['dataMat.chan', num2str(chans(k)), ' = [dataMat.chan', chans{k}, '; chanSmoothGauss(stimOn(j) - preWin : stimOn(j) + postWin)]']);

            % append breathing only for first channel
            if k == 1
                dataMat.breathing = [dataMat.breathing; breathFilt(stimTimes(j) - preWin : stimTimes(j) + postWin) + 0.2];
                dataMat.audio = [dataMat.audio; data(i).sound(stimTimes(j) - preWin : stimTimes(j) + postWin)];
                dataMat.stim = [dataMat.stim; data(i).stim(stimTimes(j) - preWin : stimTimes(j) + postWin)];
            end
        end
    end
end
%%
i = 3;
figure; hold on
plot(dataMat.stim(i, :), 'r'); plot(dataMat.breathing(i, :), 'k', 'linewidth', 2)

%%

save('DMStim_pk30gr9_muscimol_14uA.mat', 'dataMat', '-v7.3')



