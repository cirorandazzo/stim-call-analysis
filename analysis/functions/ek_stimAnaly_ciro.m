
fs = 30000;
preWin = 2000 * fs / 1000;

%% == re-center and segment breaths ==
% fs = 30000; preWin = 1500 * fs / 1000;

durThresh = 10 * fs / 1000; expThresh = 0.01; inspThresh = -0.03;

breathMat = [];

preStim.insp1 = [];
preStim.insp2 = [];
preStim.exp1 = [];
preStim.exp2 = [];

postStim.exp1 = [];
postStim.insp1 = [];

mat = dataMat.breathing;

for i = 1 : length(mat(:, 1))

    a = mat(i, :);

    if max(a(1 : preWin)) < 0
        a = a + 1.5;
    end

    [insp, exp] = ek_segmentBreaths_current(a, inspThresh, expThresh, durThresh);

    expPre = exp(exp < preWin);

    air = ek_centerBreaths(a, expPre(1), expPre(end));

    [insp, exp] = ek_segmentBreaths_current(air, inspThresh, expThresh, durThresh);

    preExp = exp(exp < preWin - 10);
    preInsp = insp(insp < preWin - 10);

    postExp = exp(exp > preWin +150 * fs / 1000);
    postInsp = insp(insp > preWin + 150 * fs / 1000);

%     if length(preExp) < 2 || length(preInsp) < 2
%         continue
%     end

    breathMat = [breathMat; air];

    preStim.insp1 = [preStim.insp1 preInsp(end)];
    preStim.insp2 = [preStim.insp2 preInsp(end - 1)];
    preStim.exp1 = [preStim.exp1 preExp(end)];
    preStim.exp2 = [preStim.exp2 preExp(end - 1)];

    postStim.exp1 = [postStim.exp1 postExp(1)];
    postStim.insp1 = [postStim.insp1 postInsp(1)];
end


%% failures
dataMat = [];
preCall.exp1 = [];
preCall.insp1 = [];
postCall.exp1 = [];
postCall.insp1 = [];

failures = [];
failureThresh = 1;

callAmp.inspStim = [];
callAmp.expStim = [];

for i = 1 : length(breathMat(:, 1))

    % insp or exp?
    if preStim.exp1(i) < preStim.insp1(i)
        callAmp.inspStim = [callAmp.inspStim max(breathMat(i, preWin : preWin + 250 * fs / 1000)) / max(breathMat(preWin - 500 * fs / 1000 : preWin))];
    else
        callAmp.expStim = [callAmp.expStim max(breathMat(i, preWin : preWin + 250 * fs / 1000)) / max(breathMat(preWin - 500 * fs / 1000 : preWin))];

    end


    if max(breathMat(i, preWin : preWin + 400 * fs / 1000)) < failureThresh
        failures = [failures i];
    end
end


%% phase analysis for failures

% == estimate phase of stims ==
% preWin = 1500 * fs / 1000;
phase = [];

insp = 0;
for i = failures

    stimT = preWin - preStim.exp1(i);

    % need to determine if insp or exp call b/c that will change insp times
    if preStim.exp1(i) < preStim.insp1(i)
        expDur = preStim.insp2(i) - preStim.exp2(i);
        inspDur = preStim.exp1(i) - preStim.insp2(i);
    else
        expDur = preStim.insp1(i) - preStim.exp2(i);
        inspDur = preStim.exp1(i) - preStim.insp1(i);
    end

    if stimT < 0
        phase = [phase 0.1];
    elseif stimT > expDur + inspDur
        phase = [phase 1.9 * pi];
    elseif stimT < expDur % exp call
        expPhase = linspace(0, pi, expDur);
        phase = [phase expPhase(stimT)];
    else % insp call
        inspPhase = linspace(pi, 2 * pi, inspDur);
        insp = insp + 1;
        phase = [phase inspPhase(stimT - expDur)];
    end
end


% == plot phases of failed stims ==
figure
polarhistogram(phase, 6, 'FaceColor', [220,20,60] / 250, 'FaceAlpha', 0.3, 'linewidth', 2);
% hold all;
title('failures')
set(gca, 'fontsize', 30)


%% == calculate mean vector ==

vectLength = circ_r(phase');
vectDir = circ_mean(phase');

polarplot([0, vectDir], [0, vectLength], 'k', 'linewidth', 2);
title('failures')
set(gca, 'fontsize', 30)




