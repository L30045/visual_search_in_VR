function [ang_fix_idx_l,v_ang_fix_idx_l,ang_fix_idx_r,v_ang_fix_idx_r] = merge_adj_fix(ang_fix_idx_l,v_ang_fix_idx_l,ang_fix_idx_r,v_ang_fix_idx_r,max_fix_interval,ang_l,ang_r,max_fix_ang)

gap_floor_ang_l = 1; % floor 
gap_floor_vang_l = 1; 
gap_floor_ang_r = 1; 
gap_floor_vang_r = 1; 
for f_i = 1:length(ang_fix_idx_l)
    gap_ceiling = f_i; % ceiling
    [gap_floor_ang_l, ang_fix_idx_l] = merge_fix(f_i, ang_fix_idx_l, gap_floor_ang_l, gap_ceiling, ang_l, max_fix_interval, max_fix_ang);
    [gap_floor_vang_l, v_ang_fix_idx_l] = merge_fix(f_i, v_ang_fix_idx_l, gap_floor_vang_l, gap_ceiling, ang_l, max_fix_interval, max_fix_ang);
    [gap_floor_ang_r, ang_fix_idx_r] = merge_fix(f_i, ang_fix_idx_r, gap_floor_ang_r, gap_ceiling, ang_r, max_fix_interval, max_fix_ang);
    [gap_floor_vang_r, v_ang_fix_idx_r] = merge_fix(f_i, v_ang_fix_idx_r, gap_floor_vang_r, gap_ceiling, ang_r, max_fix_interval, max_fix_ang);
end

end

function [gap_floor, ang_fix_idx] = merge_fix(f_i, ang_fix_idx, gap_floor, gap_ceiling, ang, max_fix_interval, max_fix_ang)

if ang_fix_idx(f_i) == 0
    if ang_fix_idx(gap_floor) == 1
        gap_floor = f_i;
    end
else
    % The fixations are considered close if they satisfy 2 criteria:
    % 1) interval smaller than threshold
    % 2) the angle difference is smaller than threshold
    if gap_ceiling - gap_floor < max_fix_interval ...
        && ang_fix_idx(gap_floor) == 0 ...
        && abs(ang(gap_ceiling)-ang(gap_floor))/pi*180 < max_fix_ang
        % merge adjacent fixation
        ang_fix_idx(gap_floor:gap_ceiling-1) = 1;
    else
        gap_floor = gap_ceiling;
    end
end

end