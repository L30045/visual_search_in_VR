function ev_idx_struct = extract_tar_idx(s_eyeMarker, pt_em, pt_eg, eye_fix_idx)
%% Plot target epoch with fixation and object label
% Input:
%   s_eyeMarker: eyeMarker stream
%   pt_em: time stamps for event marker of interest
%   pt_eg: time stamps for eye Gaze stream of interest
%   eye_fix_idx: fixation index from cal_fix_pupil function
% Output:
%   ev_idx_struct: structure for event index

ev_idx_struct = struct('t_eg', struct('obj_fix_idx',[],'tar_fix',[],'tar_miss',[],'dis_fix',[],'dis_miss',[]),...
                       't_em', struct('obj_fix_idx',[],'tar_fix',[],'tar_miss',[],'dis_fix',[],'dis_miss',[]),...
                       'pt_eg', pt_eg,'pt_em', pt_em,...
                       'com','t_eg: time index for eyeGaze stream. t_em: time_index for eyeMarker stream.');

all_target = cellfun(@(x) strcmp(x(1:3),'Tar'),s_eyeMarker.time_series(1:length(pt_em)));
all_distractor = cellfun(@(x) strcmp(x(1:3),'Dis'),s_eyeMarker.time_series(1:length(pt_em)));
target = all_target & ismember(pt_em, pt_eg(eye_fix_idx));
distractor = all_distractor & ismember(pt_em, pt_eg(eye_fix_idx));
miss_tar = (all_target - ismember(pt_em, pt_eg(eye_fix_idx))) > 0;
miss_dis = (all_distractor - ismember(pt_em, pt_eg(eye_fix_idx))) > 0;


obj_fix_idx = ismember(pt_eg, pt_em) & eye_fix_idx;
tar_fix = ismember(pt_eg, pt_em(target));
tar_miss = ismember(pt_eg, pt_em(miss_tar));
dis_fix = ismember(pt_eg, pt_em(distractor));
dis_miss = ismember(pt_eg, pt_em(miss_dis));

ev_idx_struct.t_em.obj_fix_idx = ismember(pt_em, pt_eg(eye_fix_idx));
ev_idx_struct.t_em.tar_fix = target;
ev_idx_struct.t_em.tar_miss = miss_tar;
ev_idx_struct.t_em.dis_fix = distractor;
ev_idx_struct.t_em.dis_miss = miss_dis;

ev_idx_struct.t_eg.obj_fix_idx = obj_fix_idx;
ev_idx_struct.t_eg.tar_fix = tar_fix;
ev_idx_struct.t_eg.tar_miss = tar_miss;
ev_idx_struct.t_eg.dis_fix = dis_fix;
ev_idx_struct.t_eg.dis_miss = dis_miss;

end