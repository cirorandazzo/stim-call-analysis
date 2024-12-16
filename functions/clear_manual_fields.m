function p = clear_manual_fields(p, seg_field)
%CLEAR_MANUAL_FIELDS 
% Clear all fields of a struct when manual segmentation is specified.
% Retains certain useful fields.
% 

arguments
    p;
    seg_field;
end

if strcmpi(seg_field, 'call_seg')
    p_fields = {'call_seg'};
    
    for i_f = 1:length(p_fields)
        fld = p_fields{i_f};
        subfields = fields(p.(fld));
    
        for i_s = 1:length(subfields)
            % delete all fields EXCEPT post stim call window
            sf = subfields{i_s};
            if ~strcmp(sf, 'post_stim_call_window_ms')
                p.(fld).(sf) = [];
            end
    
        end
    end
else
    error("Unrecognized segmentation field to clear: " + seg_field);
end

end

