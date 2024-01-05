function [onsets, offsets]=SegmentNotesJC(smooth, Fs, min_int, min_dur, threshold)
% copied from evsonganaly source code
% 
% [ons,offs]=evsegment(smooth,Fs,min_int,min_dur,threshold);
% segment takes smoothed filtered song and returns vectors of note
% onsets and offsets values are in seconds
% 
% 2024.01.04 CDR - edited for readability & annotated

%threshold input
notetimes=smooth>threshold;

%extract index values for note onsets and offsets
trans = conv([1 -1] ,notetimes);  % see below for note on convolution
t_onsets  = find(trans>0);  
t_offsets = find(trans<0);

% convolution:
%   1  for onset  at frame i (where y(i)=1 and y(i-1)=0)
%  -1  for offset at frame i+1 (where y(i)=1 and y(i+1)=0)
%   0  otherwise
% 
%   note that offsets are first frame without sound

onsets = t_onsets;
offsets = t_offsets;

if (length(t_onsets) ~= length(t_offsets))
    % return error struct with relevant data
    % i'm not sure when this can actually happen, but it was here and
    % doesnt hurt to keep it
    errorStruct.message = 'Number of note onsets and offsets do not match!';
    errorStruct.notetimes = notetimes;
    errorStruct.trans = trans;
    errorStruct.t_onsets = t_onsets;
    errorStruct.t_offsets = t_offsets;

	error(errorStruct);
elseif isempty(onsets)  % no notes found.
    return;
else         
	%--eliminate short intervals
	temp_int=(onsets(2:length(onsets))-offsets(1:length(offsets)-1))*1000/Fs; % n_frames between subsequent intervals
	real_ints=temp_int>min_int;

	onsets=[onsets(1); nonzeros(onsets(2:length(onsets)).*real_ints)]; % delete offsets/onsets interrupting short intervals
	offsets=[nonzeros(offsets(1:length(offsets)-1).*real_ints); offsets(length(offsets))];
    

	%--eliminate short notes
	temp_dur=(offsets-onsets)*1000/Fs;  % length of each note
	real_durs=temp_dur>min_dur;

	onsets=[nonzeros((onsets).*real_durs)]; % delete notes that are too short
	offsets=[nonzeros((offsets).*real_durs)];
    
	%--convert to ms
    % peculiarities here are to prevent rounding problem
	% if t_ons is simply replaced with onsets, everything gets rounded
    onsets = onsets/Fs; % all in seconds
	offsets = offsets/Fs; %all in seconds
end
return;
