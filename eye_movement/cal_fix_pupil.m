%% calculate fixation for eye movement, GIP location, and head movement
function fix_struct = cal_fix_pupil(test_data,srate,varargin)
%% calculate eye fixation based on puipl's angular velocity and eye openess.
% Input:
%   [test_data]: puipl 3D location (n by time)
%                n = 6 for left_xyz, right_xyz
%                n = 8 for left_xyz, right_xyz, left_eye_open_idx, right_eye_open_idx
%                eye_open_idx: eye openess [0, 1]
%   [srate]: sampling rate
%   [calibration_data]: fixation data for defining threshold. Dimension is
%   same as test_data.
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
%       reconstruct_3D_pos: reconstructed position for eye movement.
%       eye_movement: puipl moving angle and angular velocity
%       fixation: fixation index for eye movement.

    %% parameter setting
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p,'test_data');
    addRequired(p,'srate');
    addOptional(p,'calibration_data',[]) % a period of fixation for threshold defining.
    addOptional(p,'eye_open_idx',[]) % eye openess (left, right by time) [0, 1]
    addOptional(p,'max_gap_length',75) % ms (max gap length to be filled in, otherwise treat as blink or losing data based on eye openess.)
    addOptional(p,'blink_length',150) % ms (max length for gap to classify as blink, otherwise data lose.)
    addOptional(p,'thres_open',0.1) % label data as "gap (eye close)" when eye openess is smaller than this threshold
    addOptional(p,'eye_selection','left') % calcualte fixation based on the eye movement of selected eye. ('left','right','strictBOTH','looseBOTH')
    addOptional(p,'noise_reduction',5) % moving average with +/- 5 samples
    addOptional(p,'velocity_smooth_win_len',40) % ms (calculate angular velocity based on a sliding window, time point without enough samples to fill the window will not be calculated. ie. the beginning and end of a recording)
    addOptional(p,'thres_ang',1) % deg (angular higher than this threshold will be marked as saccade) (Default: 0.5 deg/s for Nystrom 2010)
    addOptional(p,'thres_ang_v',0) % deg (angular velocity higher than this threshold will be marked as saccade) (Default: 30 deg/s for tobii, 130 deg/s for Eye tracking 2017)
    addOptional(p,'fix_selection','velocity') % select fixation criteria ('velocity','dispersion','strictVD','looseVD')
    addOptional(p,'max_fix_interval',75) % ms (merge adjacent fixations if the interval is smaller than 75 ms)
    addOptional(p,'max_fix_ang',1) % deg (merge adjacent fixations if the angle difference is smaller than 1 deg) (0.5 deg for tobii default)
    addOptional(p,'min_fix_len',150) % ms (discard fixations if shorter than 150ms. Tobii uses 60 ms istead)
    parse(p,test_data,srate,varargin{:})
    
    % initialize fix struct
    pipe_pars = p.Results;
    fix_struct = struct('pipeline_pars',pipe_pars,'time_stamps',[],'srate',[],...
                         'gap_detection',struct('eye_open_idx',[],'blink_idx',[],'dataLose_idx',[]),...
                         'reconstruct_eye_pos',struct('test_data',[],'calibration_data',[]),...
                         'eye_movement',struct('left_ang',[],'left_ang_vel',[],'right_ang',[],'right_ang_vel',[]),...
                         'cali_eye_movement',struct('left_ang',[],'left_ang_vel',[],'right_ang',[],'right_ang_vel',[]),...
                         'eye_fixation',struct('eye_fix_idx',[],'left_ang_fix_idx',[],'left_v_ang_fix_idx',[],...
                                                                'right_ang_fix_idx',[],'right_v_ang_fix_idx',[]));
	
	% addpath to dependencies
    addpath('dependencies/')
                                       
    %% extract data from parse
    cali_data = pipe_pars.calibration_data;
    if size(test_data,1) < 6
        error('[Data format error]: test_data should contain positions for both left and right eye.')
    else
        eye_3D_pos = test_data(1:6,:);
    end
    if size(test_data,1) == 8
        eye_open_idx = test_data(7:8,:);
    else
        eye_open_idx = ones(2,size(test_data,2));
        disp('Eye openess index not found in test data. Assume eyes always open.')
    end
    if ~isempty(cali_data)
        if size(cali_data,1) < 6
            error('[Data format error]: calibration_data should contain positions for both left and right eye.')
        else
            cali_3D_pos = cali_data(1:6,:);
        end
        if size(cali_data,1) == 8
            cali_open_idx = cali_data(7:8,:);
        else
            cali_open_idx = ones(2,size(cali_data,2));
            disp('Eye openess index not found in calibration data. Assume eyes always open.')
        end
    end
    pt_eg = [1:size(eye_3D_pos,2)]/srate; % time stamps
    
    % =====================================
    fix_struct.time_stamps = pt_eg;
    fix_struct.srate = srate;

    %% based on eye tracker measurement confidence and eye position to identify gaps (missing points) in data
    % eye position will go to [0,0,1]' when losing data. Emperical data
    % shows that eye openese index is superset of eye position index but I
    % preserve the statement in case.
    % =====================================
    % if eye_open_idx is not given, calculate eye openess based on pupil
    % location only
    disp('Check eye openess')
    [eye_3D_pos,eye_open_idx] = identify_gaps(eye_3D_pos,eye_open_idx,srate,pipe_pars.thres_open,pipe_pars.max_gap_length);
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
    disp('Done.')
    
    %% identify gaps in calibration data    
    if ~isempty(cali_data)
        disp('Label blink in calibration data.')
        [cali_3D_pos, cali_open_idx] = identify_gaps(cali_3D_pos,cali_open_idx,srate,pipe_pars.thres_open,pipe_pars.max_gap_length);
        disp('Done.')
    end
    
    %% smoothing eye location and gip using moving average
    disp('Smoothing data by moving average.')
    mv_avg_eye_3D_pos = smoothing_mv_avg(eye_3D_pos, eye_open_idx, pipe_pars.noise_reduction);
    fix_struct.reconstruct_eye_pos.test_data = mv_avg_eye_3D_pos;
    % =====================================
    if ~isempty(cali_data)
        mv_avg_cali_3D_pos = smoothing_mv_avg(cali_3D_pos, cali_open_idx, pipe_pars.noise_reduction);
        fix_struct.reconstruct_eye_pos.cali_data = mv_avg_cali_3D_pos;
    end
    
    disp('Done.')
    
    %% calculate eye movement angular velocity
    disp('Cacluate eye movement angle and angular speed.')
	[ang_l, v_ang_l, ang_r, v_ang_r] = cal_ang(mv_avg_eye_3D_pos,srate,pipe_pars.velocity_smooth_win_len);
    % =====================================
    fix_struct.eye_movement.left_ang = ang_l/pi*180;
    fix_struct.eye_movement.left_ang_vel = v_ang_l/pi*180;
    fix_struct.eye_movement.right_ang = ang_r/pi*180;
    fix_struct.eye_movement.right_ang_vel = v_ang_r/pi*180;
    if ~isempty(cali_data)
        [cali_ang_l, cali_v_ang_l, cali_ang_r, cali_v_ang_r] = cal_ang(mv_avg_cali_3D_pos,srate,pipe_pars.velocity_smooth_win_len);
        fix_struct.cali_eye_movement.left_ang = cali_ang_l/pi*180;
        fix_struct.cali_eye_movement.left_ang_vel = cali_v_ang_l/pi*180;
        fix_struct.cali_eye_movement.right_ang = cali_ang_r/pi*180;
        fix_struct.cali_eye_movement.right_ang_vel = cali_v_ang_r/pi*180;
    end
    disp('Done.')
    
    %% calcualte threshold for angle and angular velocity based on calibration data if available
    if ~isempty(cali_data)
        pipe_pars = cal_threshold(ang_l,ang_r,v_ang_l,v_ang_r,...
                                  cali_ang_l,cali_ang_r,cali_v_ang_l,cali_v_ang_r,pipe_pars);
    else
        if pipe_pars.thres_ang == 0
            % data driven threshold
            pipe_pars.thres_ang = mean([nanmean(ang_l/pi*180)+nanstd(ang_l/pi*180),...
                                        nanmean(ang_r/pi*180)+nanstd(ang_r/pi*180)]);
            fprintf('[Threshold setting]: Angle threshold from whole data = %.2f deg.\n',pipe_pars.thres_ang);
        end
        % angular speed trheshold
        if pipe_pars.thres_ang_v == 0
            % use data driven threshold
            pipe_pars.thres_ang_v = mean([nanmean(v_ang_l/pi*180)+0.04*nanstd(v_ang_l/pi*180),...
                                          nanmean(v_ang_r/pi*180)+0.04*nanstd(v_ang_r/pi*180)]);
            fprintf('[Threshold setting]: Angular speed threshold from whole data = %.2f deg/sec.\n',pipe_pars.thres_ang_v);
        end
    end
    
    %% calculate eye fixation based on angular and angular velocity
    disp('Calculate eye fixation.')
    % calculate eye fixation based on angular
    ang_fix_idx_l = ang_l/pi*180 < pipe_pars.thres_ang;
    ang_fix_idx_r = ang_r/pi*180 < pipe_pars.thres_ang;
    % calculate eye fixation based on angular velocity
    v_ang_fix_idx_l = v_ang_l/pi*180 < pipe_pars.thres_ang_v;
    v_ang_fix_idx_r = v_ang_r/pi*180 < pipe_pars.thres_ang_v;
    
    disp('Done.')    
  
    %% merge adjacent fixation
    disp('Merge adjacent fixation.')
    max_fix_interval = pipe_pars.max_fix_interval/1000*srate;
    [ang_fix_idx_l,v_ang_fix_idx_l,ang_fix_idx_r,v_ang_fix_idx_r] = merge_adj_fix(ang_fix_idx_l,v_ang_fix_idx_l,ang_fix_idx_r,v_ang_fix_idx_r,max_fix_interval,ang_l,ang_r,pipe_pars.max_fix_ang);
    disp('Done.')
    
    %% remove fixation with short period
    disp('Remove fixation with short period.')
    min_fix_len = pipe_pars.min_fix_len/1000*srate;
    [ang_fix_idx_l,v_ang_fix_idx_l,ang_fix_idx_r,v_ang_fix_idx_r] = rm_short_fix(ang_fix_idx_l,v_ang_fix_idx_l,ang_fix_idx_r,v_ang_fix_idx_r,min_fix_len);
    
    % =====================================
    fix_struct.eye_fixation.left_ang_fix_idx = ang_fix_idx_l;
    fix_struct.eye_fixation.left_v_ang_fix_idx = v_ang_fix_idx_l;
    fix_struct.eye_fixation.right_ang_fix_idx = ang_fix_idx_r;
    fix_struct.eye_fixation.right_v_ang_fix_idx = v_ang_fix_idx_r;
    disp('Done.')
    
    %% decide fixation index
    % select left/right/strictBOTH/looseBOTH to determine how data from
    % left and right eyes are merge.
    switch lower(pipe_pars.eye_selection)
        case 'left'
            ang_fix_idx = ang_fix_idx_l;
            v_ang_fix_idx = v_ang_fix_idx_l;
        case 'right'
            ang_fix_idx = ang_fix_idx_r;
            v_ang_fix_idx = v_ang_fix_idx_r;
        case 'strictboth'
            ang_fix_idx = ang_fix_idx_l & ang_fix_idx_r;
            v_ang_fix_idx = v_ang_fix_idx_l & v_ang_fix_idx_r;
        case 'looseboth'
            ang_fix_idx = ang_fix_idx_l | ang_fix_idx_r;
            v_ang_fix_idx = v_ang_fix_idx_l | v_ang_fix_idx_r;
    end
    % select velocity/dispersion/strictVD/looseVD to determine how eye
    % fixation was define.
    switch lower(pipe_pars.fix_selection)
        case 'velocity'
            eye_fix_idx = v_ang_fix_idx;
        case 'dispersion'
            eye_fix_idx = ang_fix_idx;
        case 'strictvd'
            eye_fix_idx = ang_fix_idx & v_ang_fix_idx;
        case 'loosevd'
            eye_fix_idx = ang_fix_idx | v_ang_fix_idx;
    end
    
    % =====================================
    fix_struct.eye_fixation.eye_fix_idx = eye_fix_idx;
    fix_struct.pipeline_pars = pipe_pars;
    
end

