function epoch_lib = epoch_behavior_matrice(d_s, eye_fix_idx, t_tar, t_dis, ev_duration)
%% create epochs for behavior matrice including:
% 1. head rotation
% 2. fixation index
% 3. angle between head-location-to-GIP vector and head-direction vector
%
% Input:
%       d_s: data structure which contains data from eyeGaze stream
%       eye_fix_idx: fixation index
%       t_tar: target event time points (in clock of eyeGaze stream)
%       t_dis: distractor event time points (in clock of eyeGaze stream)
%       ev_duration: time before and after finding target / distractor (sec)
%       
% Output:
%       rot_tar/dis: head rotation epoch (xyz by duration by # of trials)
%       fi_tar/dis: fixation index epoch (duration by # of trials)
%       ang_tar/dis: angle between head-location-to-GIP vector and
%       head-direction vector (duration by # of trials)
%       ang2d_tar/dis: angle between head-location-to-GIP vector and
%       head-direction vector from bird view (top of the head looking
%       down) (duration by # of trials)
%       srate: sampling rate
%       sample_duration: epoch duration in samples, for plotting purpose

%% parameter parsing
srate = d_s.srate;
pt_eg = d_s.pt_eg;
ori_head_rot = d_s.ori_head_rot;

if ~exist('ev_duration','var')
    ev_duration = [-1 1.7]; 
end
sample_duration = round(ev_duration*srate);

%% calculate the angle between  GIP vector and head direction
[ang_GIP_hd, ang_2d] = cal_ang_GIP_hd(d_s);

%% behaviors before and after finding tar
rot_tar = cal_epoch_ev(ori_head_rot, pt_eg, t_tar, ev_duration, srate);
rot_dis = cal_epoch_ev(ori_head_rot, pt_eg, t_dis, ev_duration, srate);
fi_tar = cal_epoch_ev(eye_fix_idx, pt_eg, t_tar, ev_duration, srate);
fi_dis = cal_epoch_ev(eye_fix_idx, pt_eg, t_dis, ev_duration, srate);
ang_tar = cal_epoch_ev(ang_GIP_hd, pt_eg, t_tar, ev_duration, srate);
ang_dis = cal_epoch_ev(ang_GIP_hd, pt_eg, t_dis, ev_duration, srate);
ang2d_tar = real(cal_epoch_ev(ang_2d, pt_eg, t_tar, ev_duration, srate));
ang2d_dis = real(cal_epoch_ev(ang_2d, pt_eg, t_dis, ev_duration, srate));

%% output struct
epoch_lib = struct('rot_tar',rot_tar,'rot_dis',rot_dis,...
    'fi_tar',fi_tar,'fi_dis',fi_dis,...
    'ang_tar',ang_tar,'ang_dis',ang_dis,...
    'ang2d_tar',ang2d_tar,'ang2d_dis',ang2d_dis,...
    'srate',srate,'sample_duration',sample_duration);


end