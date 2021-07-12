%% make animation for vr room
%% load stream
streams = load_xdf('dataset/old_dataset/2020 recordings/pilot02_bullet_0708.xdf');
s_eyeMarker = streams{cellfun(@(x) strcmp(x.info.name,'ProEyeMarker'), streams)};
s_eyeGaze = streams{cellfun(@(x) strcmp(x.info.name,'ProEyeGaze'), streams)};
s_grab = streams{cellfun(@(x) strcmp(x.info.name,'GrabMarker'), streams)};

%% input data
seg_range = s_eyeGaze.segments(1).index_range;
head_loc = s_eyeGaze.time_series([14,16],seg_range(1):seg_range(2));
head_direct = s_eyeGaze.time_series([17,19],seg_range(1):seg_range(2));
bg_gip = s_eyeGaze.time_series([11,13],seg_range(1):seg_range(2));
pt_eg = s_eyeGaze.time_stamps(seg_range(1):seg_range(2))-s_eyeGaze.time_stamps(seg_range(1));
pt_em = s_eyeMarker.time_stamps-s_eyeGaze.time_stamps(seg_range(1));
pt_grab = s_grab.time_stamps-s_eyeGaze.time_stamps(seg_range(1));
pt_em(pt_em > max(pt_eg)) = [];
pt_grab(pt_grab > max(pt_eg)) = [];
% round up eye marker stream time stamps with eye gaze stream time stamps
for t_i = 1:length(pt_em)
    pt_em(t_i) = pt_eg(find(pt_eg>pt_em(t_i),1,'first'));
end
% round up grab stream time stamps with eye gaze stream time stamps
for t_i = 1:length(pt_grab)
    pt_grab(t_i) = pt_eg(find(pt_eg>pt_grab(t_i),1,'first'));
end
srate = round(1/mean(diff(pt_eg)));

%% calculate fixation based on eye movement
ori_eye_3D_pos = s_eyeGaze.time_series(5:10,seg_range(1):seg_range(2)); % left_xyz, right_xyz
eye_openess_idx = s_eyeGaze.time_series(26:27,seg_range(1):seg_range(2));
test_data = [ori_eye_3D_pos;eye_openess_idx];
fix_struct = cal_fix_pupil(test_data,srate);
eye_fix_idx = fix_struct.eye_fixation.eye_fix_idx;

%% extract target index
ev_idx_struct = extract_tar_idx(s_eyeMarker, pt_em, pt_eg, eye_fix_idx);

%% find out targets and distractors time points 
% merge_flag = true;
% idx_tar = find(cellfun(@(x) contains(x,'Target'),s_eyeMarker.time_series));
% idx_dis = find(cellfun(@(x) contains(x,'Distractor'),s_eyeMarker.time_series));
% tar_name = s_eyeMarker.time_series(idx_tar);
% dis_name = s_eyeMarker.time_series(idx_dis);
% uni_tar = unique(tar_name);
% uni_dis = unique(dis_name);
% if merge_flag
%     % merge markers with small gap
%     thres_MarkerGap = 1; % sec
%     diff_t_tar = diff(pt_em(idx_tar)) > thres_MarkerGap;
%     diff_t_dis = diff(pt_em(idx_dis)) > thres_MarkerGap;
%     diff_n_tar = ~cellfun(@(x, y) strcmp(x, y), tar_name(1:end-1), tar_name(2:end));
%     diff_n_dis = ~cellfun(@(x, y) strcmp(x, y), dis_name(1:end-1), dis_name(2:end));
%     merg_tar = [true diff_t_tar | diff_n_tar];
%     merg_dis = [true diff_t_dis | diff_n_dis];
% else
%     merg_tar = true(size(idx_tar));
%     merg_dis = true(size(idx_dis));
% end
% % event time
% t_tar = pt_em(idx_tar(merg_tar));
% t_dis = pt_em(idx_dis(merg_dis));
% t_interest = [idx_tar(merg_tar), idx_dis(merg_dis);...
%               find(ismember(pt_eg,t_tar)), find(ismember(pt_eg,t_dis));...
%               t_tar, t_dis;...
%               ones(size(t_tar)), zeros(size(t_dis))]';
% t_interest = sortrows(t_interest, 2);
% % [idx in eventMarker series,
% %  idx in eyeTracker series,
% %  time stamps in eyeTracker,
% %  labels for tar/dis]

%% extract event index for animation
all_idx_tar = ev_idx_struct.t_eg.tar_fix|ev_idx_struct.t_eg.tar_miss;
all_idx_dis = ev_idx_struct.t_eg.dis_fix|ev_idx_struct.t_eg.dis_miss;
tar_fix = ev_idx_struct.t_eg.tar_fix;
dis_fix = ev_idx_struct.t_eg.dis_fix;
ev_idx = [all_idx_tar; tar_fix; all_idx_dis; dis_fix];
test_range = 1:length(tar_fix);
fprintf('real-world time length: %.f sec\n', diff(test_range([1,end]))/srate)

%%
% drawing head on my computer takes 0.0438 sec
% animation sampling rate should be lower than 22.8311 Hz with 1x playspeed
% with 10x playspeed, data should downsample to 2 Hz
animate_2D(head_loc(:,test_range),head_direct(:,test_range),srate,bg_gip(:,test_range),ev_idx(:,test_range),...
          'ds_rate',2,'playback_speed',10,'t_tail',1)




























