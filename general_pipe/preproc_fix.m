%% preprocessing for calculating fixation
function [output_data, preproc_struct] = preproc_fix(test_data,srate,varargin)
%% calculate fixation based on given dispersion/velocity threshold and fixation duration.
% Input:
%   [test_data]: Input data (n by time)
%   [srate]: sampling rate
%   Optional:
%     [conf_idx]: confidence index [0 1]. Ignore test_data when conf_idx is lower
%       than given threshold. (See thres_open)
%     [thres_open]: label data as "gap (eye close)" when eye openess is smaller
%       than this threshold. [0 1] (0: lowest confidence, 1: highest confidence)
%     [noise_reduction]: moving average puipl location with +/- n samples
%     [max_gap_length]: max gap length to be filled in, otherwise treat as
%       losing data.(ms)
%     [outputType]: dispersion, speed, angle, v_ang (Default: angle (degree))
%     [velocity_smooth_win_len]: calculate dispersion/angle and
%       speed/angular speed based on a sliding window if given, the window
%       without enough time points will not be calculated. ie. the beginning
%       and end of a recording. (ms)
%
% Output:
%   [output_data]: Output data (1 by time). Format defined by outputType.
%   [preproc_struct]: structure contains eye related information
%       pipeline_pars: parameters setting
%       time_stamps: time stamps calculated by sampling rate
%       srate: sampling rate
%       gap_detection: binary confidence index. 1 as gap.
%       reconstruct_data: data after noise_reduction
%       dispersion: dispersion, speed, angle and angular speed

    %% parameter setting
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p,'test_data');
    addRequired(p,'srate');
    addOptional(p,'conf_idx',[]) % confidence index [0, 1]
    addOptional(p,'max_gap_length',75) % ms (max gap length to be filled in, otherwise treat as losing data.)
    addOptional(p,'thres_open',0.1) % label data as "gap (losing)" when confidence index is smaller than this threshold
    addOptional(p,'noise_reduction',5) % moving average with +/- 5 samples
    addOptional(p,'outputType','angle') % determing the return format
    addOptional(p,'velocity_smooth_win_len',40) % ms (calculate angular velocity based on a sliding window)
    parse(p,test_data,srate,varargin{:})
    
    % initialize fix struct
    pipe_pars = p.Results;
    preproc_struct = struct('pipeline_pars',pipe_pars,'time_stamps',[],'srate',[],...
                         'conf_idx',pipe_pars.conf_idx,'gap_detection',[],...
                         'reconstruct_data',[],...
                         'dispersion',struct('dispersion',[],'speed',[],'ang',[],'v_ang',[]));
                                       
    %% extract data from parse
    if isempty(pipe_pars.conf_idx)
        disp('Eye openess index not found in test data. Assume eyes always open.')
        conf_idx = true(1,size(test_data,2));
    else
        conf_idx = pipe_pars.conf_idx;
    end
    pt_eg = [1:size(test_data,2)]/srate; % time stamps
    
    % =====================================
    preproc_struct.time_stamps = pt_eg;
    preproc_struct.srate = srate;

    %% based on eye tracker measurement confidence and eye position to identify gaps (missing points) in data
    % eye position will go to [0,0,1]' when losing data. Emperical data
    % shows that eye openese index is superset of eye position index but I
    % preserve the statement in case.
    % =====================================
    % if eye_open_idx is not given, calculate eye openess based on pupil
    % location only
    disp('Check data confidence')
    [reconst_data,gap_idx] = identify_gaps(test_data,conf_idx,srate,pipe_pars.thres_open,pipe_pars.max_gap_length);
    % gap_idx now labels gap as 0.
    % =====================================
%     % classify gap into blink and data lose
%     blink_idx = [];
%     dataLose_idx = [];
%     bf_l = 1; % floor 
%     for g_i = 1:length(gap_idx)
%         bc_l = g_i; % ceiling
%         if ~gap_idx(g_i) == 1
%             if ~gap_idx(bf_l) == 0
%                 bf_l = g_i;
%             end
%         else
%             % classify gap
%             if ~gap_idx(bf_l) == 1
%                 if bc_l - bf_l < pipe_pars.blink_length/1000*srate
%                     blink_idx = [blink_idx, {bf_l:bc_l-1}];
%                 else
%                     dataLose_idx = [dataLose_idx, {bf_l:bc_l-1}];
%                 end
%             end
%             bf_l = bc_l;
%         end
%     end
    % =====================================
    preproc_struct.gap_detection = ~gap_idx;
    % record gap_idx as gap equals to 1.
    disp('Done.')
    
    %% smoothing eye location and gip using moving average
    disp('Smoothing data by moving average.')
    mv_test_data = smoothing_mv_avg(reconst_data, gap_idx, pipe_pars.noise_reduction);
    preproc_struct.reconstruct_data = mv_test_data;
    disp('Done.')
    
    %% calculate angle and angular speed
    disp('Cacluate angle and angular speed.')
	[ang, v_ang] = cal_ang(mv_test_data,srate,pipe_pars.velocity_smooth_win_len); % deg
    % =====================================
    preproc_struct.dispersion.ang = ang;
    preproc_struct.dispersion.v_ang = v_ang;
    
    %% calculate dispersion and speed
    disp('Cacluate dispersion and speed.')
	[dispersion, speed] = cal_speed(mv_test_data,srate,pipe_pars.velocity_smooth_win_len);
    % =====================================
    preproc_struct.dispersion.dispersion = dispersion;
    preproc_struct.dispersion.speed= speed;
    
    disp('Done.')
    
    %% output data
    switch pipe_pars.outputType
        case 'dispersion'
            output_data = dispersion;
        case 'speed'
            output_data = speed;
        case 'angle'
            output_data = ang;
        case 'v_ang'
            output_data = v_ang;
    end     
    
end

