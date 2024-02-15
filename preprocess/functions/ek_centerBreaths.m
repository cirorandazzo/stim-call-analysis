
% center air sac recording around zero
% for mean three breaths preceding call onset

function [air2] = ek_centerBreaths(air, exp1, exp2)
% 
% exp1/exp2: onsets of 2 previous expirations (without stim/call)
% 
% don't necessarily need to be subsequent

z = mean(air(exp1 : exp2));

air2 = air - z;

