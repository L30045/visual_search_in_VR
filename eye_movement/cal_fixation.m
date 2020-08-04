%% calculate fixation for eye movement, GIP location, and head movement
function fix_struct = cal_fixation(streams,varargin)
%% calculate eye fixation based on puipl's angular velocity and eye openess.
% Input:
%   [s_eyeGaze]: eye gaze streams containing eye_3D_pos and eye_openess
%       eye_3D_pos: puipl 3D location (xyz by time)
%       eye_openess: eye openess (left, right by time) [0 1]
%   [noise_reduction]: moving average puipl location with +/- n samples
%   [max_gap_length]: max gap length to be filled in, otherwise treat as
%   blink or losing data based on eye openess.(ms)
%   [blink_length]: max length for gap to classify as blink, otherwise data
%   lose. (ms)
%   [thres_open]: label data as "gap (eye close)" when eye openess is smaller
%   than this threshold. [0 1] (0: eye fully close, 1: eye fully open)
%   [eye_selection]: calcualte velocity based on the position of selected
%   eye. ('left','right','average')
%   [velocity_smooth_win_len]: calculate angular velocity based on a
%   sliding window, time point without enough samples to fill the window
%   will not be calculated. ie. the beginning and end of a recording. (ms)
%   [thres_ang]: angular higher than this threshold will be marked as
%   saccade) (Default: 0.5 deg/s ref. Nystrom 2010.) (deg)
%   [thres_ang_v]: angular velocity higher than this threshold will be marked
%   as saccade) (Default: 30 deg/s ref. tobii, 130 deg/s ref. Eye tracking
%   2017.) (deg/s)
%   [fix_selection]: select fixation criteria. (function not complete, might
%   include angular, accelecration criteria in the future. 20200521-Chi-Yuan)
%   [max_fix_interval]: merge adjacent fixations if the interval is smaller
%   than this threshold. (ms)
%   [max_fix_ang]: merge adjacent fixations if the angle difference is
%   smaller than this threshold) (0.5 deg ref. Tobii default) (deg)
%   [min_fix_len]: discard fixations if shorter than this threshold. (60 ms
%   ref. Tobii) (ms)
%
% Output:
%   fix_struct: structure contains eye related information
%       pipeline_pars: parameters setting
%       time_stamps: time stamps in eye gaze stream
%       srate: sampling rate
%       gap_detection: type of gaps (blink or data lose)
%       reconstruct_3D_pos: reconstructed position for eye, GIP, and head.
%       eye_movement: puipl moving angle and angular velocity
%       gip_movement: Distance between GIP and head, GIP moving distance,
%       GIP moving velocity
%       head_movement: head moving distance, head moving velocity, head
%       rotate angle and angular velocity.
%       fixation: fixation index for eye, GIP, and head.

    %% parameter setting
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p,'s_eyeGaze');
    addOptional(p,'max_gap_length',75) % ms (max gap length to be filled in, otherwise treat as blink or losing data based on eye openess.)
    addOptional(p,'blink_length',150) % ms (max length for gap to classify as blink, otherwise data lose.)
    addOptional(p,'thres_open',0.1) % label data as "gap (eye close)" when eye openess is smaller than this threshold
    addOptional(p,'eye_selection','left') % calcualte velocity based on the position of left eye
    addOptional(p,'noise_reduction',5) % moving average with +/- 5 samples
    addOptional(p,'velocity_smooth_win_len',40) % ms (calculate angular velocity based on a sliding window, time point without enough samples to fill the window will not be calculated. ie. the beginning and end of a recording)
    addOptional(p,'thres_ang',0) % deg (angular higher than this threshold will be marked as saccade) (Default: 0.5 deg/s for Nystrom 2010)
    addOptional(p,'thres_ang_v',0) % deg (angular velocity higher than this threshold will be marked as saccade) (Default: 30 deg/s for tobii, 130 deg/s for Eye tracking 2017)
    addOptional(p,'fix_selection','velocity') % select fixation criteria
    addOptional(p,'max_fix_interval',75) % ms (merge adjacent fixations if the interval is smaller than 75 ms)
    addOptional(p,'max_fix_ang',1) % deg (merge adjacent fixations if the angle difference is smaller than 1 deg) (0.5 deg for tobii default)
    addOptional(p,'min_fix_len',150) % ms (discard fixations if shorter than 150ms. Tobii uses 60 ms istead)
    parse(p,streams,varargin{:})
    
    % initialize fix struct
    pipe_pars = p.Results;
    fix_struct = struct('pipeline_pars',pipe_pars,'time_stamps',[],'srate',[],...
                         'gap_detection',struct('eye_open_idx',[],'blink_idx',[],'dataLose_idx',[]),...
                         'reconstruct_3D_pos',struct('eye_pos',[],'gip_pos',[],'head_pos',[]),...
                         'eye_movement',struct('ang',[],'ang_vel',[]),...
                         'gip_movement',struct('head_obj_dist',[],'mv_dist',[],'mv_vel',[]),...
                         'head_movement',struct('mv_dist',[],'mv_vel',[],'ang',[],'ang_vel',[]),...
                         'fixation',struct('eye_fix_idx',struct('eye_fix_idx',[],'ang_fix_idx',[],'v_ang_fix_idx',[]),...
                                           'gip_fix_idx',[],'head_fix_idx',[]));
                                       
    %% extract data from eye Gaze stream
    seg_range = s_eyeGaze.segments(1).index_range; % experiment segment 
    [nbchan, pnts] = size(s_eyeGaze.time_series(:,seg_range(1):seg_range(2))); % channel and data length
    eye_3D_pos = s_eyeGaze.time_series(5:10,seg_range(1):seg_range(2)); % left_xyz, right_xyz
    gip_3D_pos = s_eyeGaze.time_series(11:13,seg_range(1):seg_range(2));
    head_loc = s_eyeGaze.time_series(14:16,seg_range(1):seg_range(2));
    head_direct = s_eyeGaze.time_series(17:19,seg_range(1):seg_range(2));
    head_vel = s_eyeGaze.time_series(20:22,seg_range(1):seg_range(2));
    head_rot = s_eyeGaze.time_series(23:25,seg_range(1):seg_range(2));
    eye_open_idx = s_eyeGaze.time_series(26:27,seg_range(1):seg_range(2));
    chest_loc = s_eyeGaze.time_series(28:30,seg_range(1):seg_range(2));
    chest_direct = s_eyeGaze.time_series(31:33,seg_range(1):seg_range(2));
    chest_rot = s_eyeGaze.time_series(34:36,seg_range(1):seg_range(2));
    
    pt_eg = s_eyeGaze.time_stamps-s_eyeGaze.time_stamps(1);
    srate = floor(1/mean(diff(pt_eg)));
    % =====================================
    fix_struct.time_stamps = pt_eg;
    fix_struct.srate = srate;

    %% based on eye tracker measurement confidence and eye position to identify gaps (missing points) in data
    % eye position will go to [0,0,1]' when losing data. Emperical data
    % shows that eye openese index is superset of eye position index but I
    % preserve the statement in case.
    gap_idx_l = eye_open_idx(1,:) < pipe_pars.thres_open | arrayfun(@(i) all(eye_3D_pos(1:3,i)==[0, 0, 1]'), 1:length(pt_eg));
    gap_idx_r = eye_open_idx(2,:) < pipe_pars.thres_open | arrayfun(@(i) all(eye_3D_pos(4:6,i)==[0, 0, 1]'), 1:length(pt_eg));
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
            if bc_l - bf_l < pipe_pars.max_gap_length/1000*srate && gap_idx_l(bf_l) == 1
                % fix small gap
                eye_3D_pos(1:3,bf_l:bc_l-1) = eye_3D_pos(1:3,bf_l-1) + (eye_3D_pos(1:3,bc_l)-eye_3D_pos(1:3,bf_l-1))*(1:(bc_l-bf_l))/(bc_l-bf_l+1);
                gip_3D_pos(:,bf_l:bc_l-1) = gip_3D_pos(:,bf_l-1) + (gip_3D_pos(:,bc_l)-gip_3D_pos(:,bf_l-1))*(1:(bc_l-bf_l))/(bc_l-bf_l+1);
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
            if bc_r - bf_r < pipe_pars.max_gap_length/1000*srate && gap_idx_r(bf_r) == 1
                eye_3D_pos(4:6,bf_r:bc_r-1) = eye_3D_pos(4:6,bf_r-1) + (eye_3D_pos(4:6,bc_r)-eye_3D_pos(4:6,bf_r-1))*(1:(bc_r-bf_r))/(bc_r-bf_r+1);
                gip_3D_pos(:,bf_r:bc_r-1) = gip_3D_pos(:,bf_r-1) + (gip_3D_pos(:,bc_r)-gip_3D_pos(:,bf_r-1))*(1:(bc_r-bf_r))/(bc_r-bf_r+1);
                gap_idx_r(bf_r:bc_r-1) = 0;
            else
                bf_r = bc_r;
            end
        end 
    end
    % label eye open points
    eye_open_idx = ~(gap_idx_r|gap_idx_l); % sanity check: 97% of data is labeled as eye open
    % left eye has fixed 4.8 sec of data
    % right eye has fixed 3 sec of data
    % =====================================
    % classify gap into blink and data lose
    blink_idx = [];
    dataLose_idx = [];
    bf_l = 1; % floor 
    for g_i = 1:length(eye_open_idx)
        bc_l = g_i; % ceiling
        if ~eye_open_idx(g_i) == 1
            if ~eye_open_idx(bf_l) == 0
                bf_l = g_i;
            end
        else
            % classify gap
            if ~eye_open_idx(bf_l) == 1
                if bc_l - bf_l < pipe_pars.blink_length/1000*srate
                    blink_idx = [blink_idx, {bf_l:bc_l-1}];
                else
                    dataLose_idx = [dataLose_idx, {bf_l:bc_l-1}];
                end
            end
            bf_l = bc_l;
        end
    end
    % =====================================
    fix_struct.gap_detection.eye_open_idx = eye_open_idx;
    fix_struct.gap_detection.blink_idx = blink_idx;
    fix_struct.gap_detection.dataLose_idx = dataLose_idx;
    
    %% smoothing eye location and gip using moving average
    mv_avg_eye_3D_pos = eye_3D_pos;
    mv_avg_gip_3D_pos = gip_3D_pos;
    mv_avg_eye_3D_pos(:,~eye_open_idx) = NaN;
    mv_avg_gip_3D_pos(:,~eye_open_idx) = NaN;
    mv_avg_win_len = floor(pipe_pars.noise_reduction/2);
    for m_i = mv_avg_win_len+1:size(eye_3D_pos,2)-mv_avg_win_len
        if ~isnan(mv_avg_eye_3D_pos(1,m_i+(-mv_avg_win_len:mv_avg_win_len)))
            % only reconstruct eye open sections
            mv_avg_eye_3D_pos(:,m_i) = mean(eye_3D_pos(:,m_i+(-mv_avg_win_len:mv_avg_win_len)),2);
            mv_avg_gip_3D_pos(:,m_i) = mean(gip_3D_pos(:,m_i+(-mv_avg_win_len:mv_avg_win_len)),2);
        end
    end
    % =====================================
    fix_struct.reconstruct_3D_pos.eye_pos = mv_avg_eye_3D_pos;
    fix_struct.reconstruct_3D_pos.gip_pos = mv_avg_gip_3D_pos;
    
    %% calculate eye movement angular velocity
    switch pipe_pars.eye_selection
        case 'left'
            e_pos = mv_avg_eye_3D_pos(1:3,:);
        case 'right'
            e_pos = mv_avg_eye_3D_pos(4:6,:);
        case 'average'
            e_pos = (mv_avg_eye_3D_pos(1:3,:)+mv_avg_eye_3D_pos(4:6,:))/2;
    end 
    ang = nan(1,size(eye_3D_pos,2));
    v_ang = nan(1,size(eye_3D_pos,2));
    vel_win_len = round(0.001*pipe_pars.velocity_smooth_win_len*srate/2);
    for v_i = vel_win_len+1:size(eye_3D_pos,2)-vel_win_len
        if ~isnan(e_pos(1,v_i+[-vel_win_len,vel_win_len]))
            ang(v_i) = acos(e_pos(:,v_i-vel_win_len)'*e_pos(:,v_i+vel_win_len));
            v_ang(v_i) = ang(v_i) / diff(pt_eg([v_i-vel_win_len,v_i+vel_win_len]));
        end
    end
    % check if angle are all real number
    if ~isreal(ang)
        error('[Calculate angular velocity]: dot product of 2 eye gaze position is greater than 1.')
    end
    % =====================================
    fix_struct.ang_movement.ang = ang;
    fix_struct.ang_movement.ang_vel = v_ang;
    
    %% calculate eye fixation based on angular and angular velocity
    % calculate eye fixation based on angular
    if pipe_pars.thres_ang == 0
        % use data driven threshold
        ang_fix_idx = v_ang/pi*180 < nanmean(ang/pi*180)+nanstd(ang/pi*180);
    else
        % use user input threshold
        ang_fix_idx = v_ang/pi*180 < pipe_pars.thres_ang;
    end
    % calculate eye fixation based on angular velocity
    if pipe_pars.thres_ang_v == 0
        % use data driven threshold
        v_ang_fix_idx = v_ang/pi*180 < nanmean(v_ang/pi*180)+0.04*nanstd(v_ang/pi*180); % from Eye tracking methodology 2017 pp.156 Tabel 13.1
    else
        % use user input threshold
        v_ang_fix_idx = v_ang/pi*180 < pipe_pars.thres_ang_v;
    end
    
    %% merge adjacent fixation
    % angular based fixation
    gap_floor = 1; % floor 
    for f_i = 1:length(ang_fix_idx)
        gap_ceiling = f_i; % ceiling
        if ang_fix_idx(f_i) == 0
            if ang_fix_idx(gap_floor) == 1
                gap_floor = f_i;
            end
        else
            if gap_ceiling - gap_floor < pipe_pars.max_fix_interval/1000*srate ...
                && ang_fix_idx(gap_floor) == 0 ...
                && abs(ang(gap_ceiling)-ang(gap_floor))/pi*180 < pipe_pars.max_fix_ang
                % merge adjacent fixation
                ang_fix_idx(gap_floor:gap_ceiling-1) = 1;
            else
                gap_floor = gap_ceiling;
            end
        end
    end

    % angular velocity based fixation
    gap_floor = 1; % floor 
    for f_i = 1:length(v_ang_fix_idx)
        gap_ceiling = f_i; % ceiling
        if v_ang_fix_idx(f_i) == 0
            if v_ang_fix_idx(gap_floor) == 1
                gap_floor = f_i;
            end
        else
            if gap_ceiling - gap_floor < pipe_pars.max_fix_interval/1000*srate ...
                && v_ang_fix_idx(gap_floor) == 0 ...
                && abs(ang(gap_ceiling)-ang(gap_floor))/pi*180 < pipe_pars.max_fix_ang
                % merge adjacent fixation
                v_ang_fix_idx(gap_floor:gap_ceiling-1) = 1;
            else
                gap_floor = gap_ceiling;
            end
        end
    end
    %% remove fixation with short period
    % angular based fixation
    fix_floor = 1; % floor 
    for f_i = 1:length(ang_fix_idx)
        fix_ceiling = f_i; % ceiling
        if ang_fix_idx(f_i) == 1
            if ang_fix_idx(fix_floor) == 0
                fix_floor = f_i;
            end
        else
            if fix_ceiling - fix_floor < pipe_pars.min_fix_len/1000*srate && ang_fix_idx(fix_floor) == 1
                % delete short fixation
                ang_fix_idx(fix_floor:fix_ceiling-1) = 0;
            else
                fix_floor = fix_ceiling;
            end
        end
    end
    % angular velocity based fixation
    fix_floor = 1; % floor 
    for f_i = 1:length(v_ang_fix_idx)
        fix_ceiling = f_i; % ceiling
        if v_ang_fix_idx(f_i) == 1
            if v_ang_fix_idx(fix_floor) == 0
                fix_floor = f_i;
            end
        else
            if fix_ceiling - fix_floor < pipe_pars.min_fix_len/1000*srate && v_ang_fix_idx(fix_floor) == 1
                % delete short fixation
                v_ang_fix_idx(fix_floor:fix_ceiling-1) = 0;
            else
                fix_floor = fix_ceiling;
            end
        end
    end
    %% decide fixation index
    switch pipe_pars.fix_selection
        case 'velocity'
            eye_fix_idx = v_ang_fix_idx;
        case 'disperation'
            eye_fix_idx = ang_fix_idx;
        case 'strictVD'
            eye_fix_idx = ang_fix_idx & v_ang_fix_idx;
        case 'looseVD'
            eye_fix_idx = ang_fix_idx | v_ang_fix_idx;
    end
    
    % =====================================
    fix_struct.eye_fix_idx.ang_fix_idx = ang_fix_idx;
    fix_struct.eye_fix_idx.v_ang_fix_idx = v_ang_fix_idx;
    fix_struct.eye_fix_idx.eye_fix_idx = eye_fix_idx;
    
end
