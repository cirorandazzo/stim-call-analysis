function [air2] = ek_centerBreaths(air, exp1, exp2)
% ek_centerBreaths.m
% 
% center air sac recording around mean signal between frames exp1 and exp2
% 
% exp1/exp2 are usually onsets of the 2 expirations preceding stimulation/call

z = mean(air(exp1 : exp2));

air2 = air - z;
