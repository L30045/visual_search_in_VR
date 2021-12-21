function fix_idx = rm_short_fix(fix_idx,min_fix_len)

rm_floor = 1; % floor 

for f_i = 1:length(fix_idx)
    rm_ceiling = f_i; % ceiling
    [rm_floor, fix_idx] = rm_fix(f_i, fix_idx, rm_floor, rm_ceiling, min_fix_len);
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