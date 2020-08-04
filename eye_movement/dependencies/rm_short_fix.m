function [ang_fix_idx_l,v_ang_fix_idx_l,ang_fix_idx_r,v_ang_fix_idx_r] = rm_short_fix(ang_fix_idx_l,v_ang_fix_idx_l,ang_fix_idx_r,v_ang_fix_idx_r,min_fix_len)

rm_floor_ang_l = 1; % floor 
rm_floor_vang_l = 1; 
rm_floor_ang_r = 1; 
rm_floor_vang_r = 1; 
for f_i = 1:length(ang_fix_idx_l)
    rm_ceiling = f_i; % ceiling
    [rm_floor_ang_l, ang_fix_idx_l] = rm_fix(f_i, ang_fix_idx_l, rm_floor_ang_l, rm_ceiling, min_fix_len);
    [rm_floor_vang_l, v_ang_fix_idx_l] = rm_fix(f_i, v_ang_fix_idx_l, rm_floor_vang_l, rm_ceiling, min_fix_len);
    [rm_floor_ang_r, ang_fix_idx_r] = rm_fix(f_i, ang_fix_idx_r, rm_floor_ang_r, rm_ceiling, min_fix_len);
    [rm_floor_vang_r, v_ang_fix_idx_r] = rm_fix(f_i, v_ang_fix_idx_r, rm_floor_vang_r, rm_ceiling, min_fix_len);
end

end

function [rm_floor, ang_fix_idx] = rm_fix(f_i, ang_fix_idx, rm_floor, rm_ceiling, min_fix_len)

if ang_fix_idx(f_i) == 1
    if ang_fix_idx(rm_floor) == 0
        rm_floor = f_i;
    end
else
    if rm_ceiling - rm_floor < min_fix_len && ang_fix_idx(rm_floor) == 1
        % delete short fixation
        ang_fix_idx(rm_floor:rm_ceiling-1) = 0;
    else
        rm_floor = rm_ceiling;
    end
end

end