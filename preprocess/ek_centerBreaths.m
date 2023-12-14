
% center air sac recording around zero
% for mean three breaths preceding call onset

function [air2] = ek_centerBreaths(air, exp1, exp2)


% z = (max(air(pb - 500 * fs / 1000 : pb)) + min(dataPre(i).air(pb - 500 * fs / 1000 : pb))) / 2;

% z = (abs(max(air(exp1 : exp2))) - abs(min(air(exp1 : exp2)))) / 2;

z = mean(air(exp1 : exp2));


air2 = air - z;

