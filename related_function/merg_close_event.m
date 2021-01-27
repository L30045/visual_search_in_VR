function [t_tar, t_dis] = merg_close_event(ev_idx_struct, eyeMarker_name, merge_flag)
%% merge target/distrator events if they satisfy the following 2 statements:
% 1. too close to each other (1 sec)
% 2. has the same label name

if ~exist('merge_flag','var')
    merge_flag = true;
end
pt_em = ev_idx_struct.pt_em;
idx_tar = find(ev_idx_struct.t_em.tar_fix);
idx_dis = find(ev_idx_struct.t_em.dis_fix);
tar_name = eyeMarker_name(idx_tar);
dis_name = eyeMarker_name(idx_dis);
if merge_flag
    % merge markers with small gap
    thres_MarkerGap = 1; % sec
    diff_t_tar = diff(pt_em(idx_tar)) > thres_MarkerGap;
    diff_t_dis = diff(pt_em(idx_dis)) > thres_MarkerGap;
    diff_n_tar = ~cellfun(@(x, y) strcmp(x, y), tar_name(1:end-1), tar_name(2:end));
    diff_n_dis = ~cellfun(@(x, y) strcmp(x, y), dis_name(1:end-1), dis_name(2:end));
    merg_tar = [true diff_t_tar | diff_n_tar];
    merg_dis = [true diff_t_dis | diff_n_dis];
else
    merg_tar = true(size(idx_tar));
    merg_dis = true(size(idx_dis));
end
% event time
t_tar = pt_em(idx_tar(merg_tar));
t_dis = pt_em(idx_dis(merg_dis));

end