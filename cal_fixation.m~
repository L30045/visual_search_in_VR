%% calculate fixation for eye movement, GIP location, and head movement
function gaze_struct = cal_fixation(streams,varargin)
    %% parameter setting
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p,'streams');
    addOptional(p,'max_gap_length',75) % ms (max gap length to be filled in, otherwise treat as blink or losing data based on eye openess.)
    addOptional(p,'blink_length',150) % ms (max length for gap to classify as blink, otherwise data lose.)
    addOptional(p,'thres_open',0.1) % label data as "gap (eye close)" when eye openess is smaller than this threshold
    addOptional(p,'eye_selection','left') % calcualte velocity based on the position of left eye
    addOptional(p,'noise_reduction',5) % moving average with +/- 5 samples
    addOptional(p,'velocity_smooth_win_len',40) % ms (calculate angular velocity based on a sliding window, time point without enough samples to fill the window will not be calculated. ie. the beginning and end of a recording)
    addOptional(p,'thres_ang_v',30) % deg (angular velocity higher than this threshold will be marked as saccade)
    addOptional(p,'max_fix_interval',75) % ms (merge adjacent fixations if the interval is smaller than 75 ms)
    addOptional(p,'max_fix_ang',0.5) % deg (merge adjacent fixations if the angle difference is smaller than 0.5 deg)
    addOptional(p,'min_fix_len',150) % ms (discard fixations if shorter than 150ms. Tobii uses 60 ms istead)
    parse(p,streams,varargin{:})
    
    % initialize gaze struct
    pipe_pars = p.Results;
    gaze_struct = struct('pipeline_pars',pipe_pars,'time_stamps',[],'srate',[],...
                         'gap_detection',struct('eye_open_idx',[],'blink_idx',[],'dataLose_idx',[]),...
                         'reconstruct_3D_pos',struct('eye_pos',[],'gip_pos',[],'head_pos',[]),...
                         'eye_movement',struct('ang',[],'ang_vel',[]),...
                         'gip_movement',struct('head_obj_dist',[],'mv_dist',[],'mv_vel'),...
                         'head_movement',struct('mv_dist',[],'mv_vel',[],'ang',[],'ang_vel',[]),...
                         'fixation',struct('eye_fix_idx',[],'gip_fix_idx',[],'head_fix_idx',[]));

    %% load stream
    s_eyeGaze = pipe_pars.streams{cellfun(@(x) strcmp(x.info.name,'ProEyeGaze'), pipe_pars.streams)}; % Accuracy:0.5 deg – 1.1 deg

    %% extract data from eye Gaze stream
    eye_3D_pos = s_eyeGaze.time_series(5:10,:); % left_xyz, right_xyz
    gip_3D_pos = s_eyeGaze.time_series(11:13,:); % obj_xyz
    head_pos = s_eyeGaze.time_series(14:16,:); % head_xyz
    head_direct = s_eyeGaze.time_series(17:19,:); % head_direction_xyz
    v_head = s_eyeGaze.time_series(20:22,:); % head_vel_xyz
    v_ang_head = s_eyeGaze.time_series(23:25,:); % head_ang_vel_xyz
    eye_open_idx = s_eyeGaze.time_series(26:27,:); % left, right
    pt_eg = s_eyeGaze.time_stamps-s_eyeGaze.time_stamps(1);
    srate = floor(1/mean(diff(pt_eg)));
    % =====================================
    gaze_struct.time_stamps = pt_eg;
    gaze_struct.srate = srate;

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
    gaze_struct.gap_detection.eye_open_idx = eye_open_idx;
    gaze_struct.gap_detection.blink_idx = blink_idx;
    gaze_struct.gap_detection.dataLose_idx = dataLose_idx;
    
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
    gaze_struct.reconstruct_3D_pos.eye_pos = mv_avg_eye_3D_pos;
    gaze_struct.reconstruct_3D_pos.gip_pos = mv_avg_gip_3D_pos;
    
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
    gaze_struct.ang_movement.ang = ang;
    gaze_struct.ang_movement.ang_vel = v_ang;
    
    %% calculate eye fixation based on angular velocity
    
    
    
    
end
