function [insp, exp] = ek_segmentBreaths_current(air, inspThresh, expThresh, durThresh)
% 16 17 25
% air = dataMat_sorted(11, :);

% ==== SEGMENT BREATHS INTO INSPIRATIONS AND EXPIRATIONS HERE ====
zci = @(v) find(v(:).*circshift(v(:), [-1 0]) <= 0); % zero crossings
zero = zci(air);

insp_ = [];
exp_ = [];
isInsp = 0;
for i = 1 : length(zero) % sort zero crossings into putative insps and exps
    if length(air) < zero(i) + 5
        continue
    end
    if air(zero(i) + 5) < 0
        insp_ = [insp_ zero(i)];
    else
        exp_ = [exp_ zero(i)];
    end
end

% figure; plot(air); hold on; scatter(insp_, zeros(length(insp_), 1), 'b')
% scatter(exp_, zeros(length(exp_), 1), 'r')

%%
insp = [];
for i = 1 : length(insp_) - 1 % test insp & exp with dur & amplitude thresholds
    if insp_(i + 1) - insp_(i) > durThresh
%         nextExp = exp_(find(exp_ > insp_(i)));
%         nextExp = nextExp(1);
        if min(air(insp_(i) : insp_(i  + 1))) < inspThresh
            insp = [insp insp_(i)];
        end
    end
end

exp = [];
for i = 1 : length(exp_) % test insp & exp with dur & amplitude thresholds
    if isempty(insp_)
        continue
    end
    if i == length(exp_)
         exp = [exp exp_(i)];
         insp = [insp insp_(end)];
         break
    end
    if exp_(i + 1) - exp_(i) > durThresh
%         nextInsp = insp_(find(insp_ > exp_(i)));
%         nextInsp = nextInsp(1);
        if max(air(exp_(i) : exp_(i + 1))) > expThresh
            if length(exp) >= 1
                prevInsps = insp(find(insp < exp_(i)));
                if isempty(prevInsps)
                    continue
                end
                
                prevInsp = prevInsps(end);
                
                if prevInsp > exp(end) && exp_(i) - prevInsp  > durThresh
                     % if there are more than one inspiration after prev exp
%                     if length(prevInsps) >= 2
%                         while prevInsps(end - 1) > exp(end)
%                             prevInsps = prevInsps(1 : end - 1);
%                             if length(prevInsps) <= 1
%                                 break
%                             end
%                         end
%                     end
                    prevInsp = prevInsps(end);
                    exp = [exp exp_(i)];
                    inspsBetween = [find(insp > exp(end - 1) & insp < exp(end))];
                    if length(inspsBetween) > 1
                        insp = [insp(1 : inspsBetween(1) - 1) insp(inspsBetween(end) : end)];
                    end
                end
            else
                exp = [exp exp_(i)];
            end
        end
    end
end

% figure; plot(air); hold on; scatter(insp, zeros(length(insp), 1), 'b')
% scatter(exp, zeros(length(exp), 1), 'r')


%%
% preStimExp = find(exp < 1500 * 30000 / 1000);
% preStimExp1 = exp(preStimExp(end));
% T = linspace(-1000, 500, length(air));
% figure; plot(air); hold on; scatter(insp, zeros(length(insp), 1), 'b')
% scatter(exp, zeros(length(exp), 1), 'r')
% scatter(preStimExp1, 0, 'k', 'filled')
% 
% x = 0;





