function [eye_3D_pos,eye_open_idx] = identify_gaps(eye_3D_pos,eye_open_idx,srate,thres_open,max_gap_length)
%% based on eye tracker measurement confidence and eye position to identify gaps (missing points) in data
% eye position will go to [0,0,1]' when losing data. Emperical data
% shows that eye openese index is superset of eye position index but I
% preserve the statement in case.
% =====================================
% if eye_open_idx is not given, calculate eye openess based on pupil
% location only
% ---------------
% Input:
%   eye_3D_pos: test_data (6 by times)
%   eye_open_idx: eye openess reported by eye tracker [0,1]
%   srate: sampling rate
%   thres_open: threshold for defining eye open
%   max_gap_length: maximum gap length to be fixed. Gaps with duration
%   longer than this threshold will be considered as blink or missing data.
% Output:
%   eye_open_idx: eye openess (binary)

%%
gap_idx_l = eye_open_idx(1,:) < thres_open | arrayfun(@(i) all(eye_3D_pos(1:3,i)==[0, 0, 1]'), 1:size(eye_3D_pos,2));
gap_idx_r = eye_open_idx(2,:) < thres_open | arrayfun(@(i) all(eye_3D_pos(4:6,i)==[0, 0, 1]'), 1:size(eye_3D_pos,2));
% fix gap that is not shorter than threshold
bf_l = 1; % floor 
bf_r = 1;
for g_i = 1:length(gap_idx_l)
    bc_l = g_i; % ceiling
    bc_r = g_i;
    % left eye
    if gap_idx_l(g_i) == 1
        if gap_idx_l(bf_l) == 0
            bf_l = g_i;
        end
    else
        if bc_l - bf_l < max_gap_length/1000*srate && gap_idx_l(bf_l) == 1
            % fix small gap
            eye_3D_pos(1:3,bf_l:bc_l-1) = eye_3D_pos(1:3,max([1,bf_l-1])) + (eye_3D_pos(1:3,bc_l)-eye_3D_pos(1:3,max([1,bf_l-1])))*(1:(bc_l-bf_l))/(bc_l-bf_l+1);
            gap_idx_l(bf_l:bc_l-1) = 0;
        else
            bf_l = bc_l;
        end
    end
    % right eye
    if gap_idx_r(g_i) == 1
        if gap_idx_r(bf_r) == 0
            bf_r = g_i;
        end
    else
        if bc_r - bf_r < max_gap_length/1000*srate && gap_idx_r(bf_r) == 1
            eye_3D_pos(4:6,bf_r:bc_r-1) = eye_3D_pos(4:6,max([1,bf_r-1])) + (eye_3D_pos(4:6,bc_r)-eye_3D_pos(4:6,max([1,bf_r-1])))*(1:(bc_r-bf_r))/(bc_r-bf_r+1);
            gap_idx_r(bf_r:bc_r-1) = 0;
        else
            bf_r = bc_r;
        end
    end 
end
% label eye open points
eye_open_idx = ~(gap_idx_r|gap_idx_l);
fprintf('Eye open portion in the data: %2.f%%\n', 100*(sum(eye_open_idx)/length(eye_open_idx)));

end