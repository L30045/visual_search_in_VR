function [repeat_idx, nb_repeat, prev_fix_idx] = cal_repeat_fix(obj_fix)
repeat_idx = [];
nb_repeat = [];
prev_fix_idx = [];
num_observ = containers.Map();
prev_fix = containers.Map();
for i = 1:length(obj_fix)
    if ~isKey(num_observ, obj_fix{i})
        repeat_idx(i) = 0;
        nb_repeat(i) = -1;
        prev_fix_idx(i) = -1;
        num_observ(obj_fix{i}) = 1;
        prev_fix(obj_fix{i}) = i - 1;
    else
        repeat_idx(i) = 1;
        nb_repeat(i) = num_observ(obj_fix{i});
        prev_fix_idx(i) = prev_fix(obj_fix{i});
        num_observ(obj_fix{i}) = num_observ(obj_fix{i}) + 1;
        prev_fix(obj_fix{i}) = i - 1;
    end
end

        