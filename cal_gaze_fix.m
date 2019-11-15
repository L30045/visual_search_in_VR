%% calculate fixation threshold for eye gaze
function gaze_struct = cal_gaze_fix(streams,varargin)
    %% parameter setting
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p,'streams');
    addOptional(p,'max_gap_length',75) % ms (max gap length to be filled in, otherwise treat as blink or losing data based on eye openess.)
    addOptional(p,'eye_selection','left') % calcualte velocity based on the position of left eye
    addOptional(p,'noise_reduction',5) % moving average with +/- 5 samples
    addOptional(p,'velocity_smooth_win_len',20) % ms (calculate angular velocity based on a sliding window, time point without enough samples to fill the window will not be calculated. ie. the beginning and end of a recording)
    addOptional(p,'thres_ang_v',30) % deg (angular velocity higher than this threshold will be marked as saccade)
    addOptional(p,'max_fix_interval',75) % ms (merge adjacent fixations if the interval is smaller than 75 ms)
    addOptional(p,'max_fix_ang',0.5) % deg (merge adjacent fixations if the angle difference is smaller than 0.5 deg)
    addOptional(p,'min_fix_len',150) % ms (discard fixations if shorter than 150ms. Tobii uses 60 ms istead)
    parse(p,streams,varargin{:})
    
    % initialize gaze struct
    pipe_pars = p.Results;
    gaze_struct = struct('pipeline_pars',pipe_pars,'time_stamps',[],'srate',[],'fixation_idx',[],'gap_idx',[],'reconstruct_3D_pos',[],'ang_v',[]);

    %% load stream
    s_eyeGaze = pipe_pars.streams{cellfun(@(x) strcmp(x.info.name,'ProEyeGaze'), pipe_pars.streams)}; % Accuracy:0.5 deg – 1.1 deg

    %% extract data from eye Gaze stream
    eye_3D_pos = s_eyeGaze.time_series(5:10,:); % left_xyz, right_xyz
    gip_3D_pos = s_eyeGaze.time_series(11:13,:); % left_xyz, right_xyz
    eye_open_idx = s_eyeGaze.time_series(26:27,:); % left, right
    pt_eg = s_eyeGaze.time_stamps-s_eyeGaze.time_stamps(1);
    srate = floor(1/mean(diff(pt_eg)));
    gaze_struct.time_stamps = pt_eg;
    gaze_struct.srate = srate;

    %% based on eye tracker measurement confidence to identify gaps (missing points) in data
    % since we don't have this index, here I use openess to identify gaps.
    gap_idx_l = eye_open_idx(1,:) < 0.1;
    gap_idx_r = eye_open_idx(2,:) < 0.1;
    % fix gap that is not shorter than threshold
    bf_l = 1;
    bc_l = 1;
    bf_r = 1;
    bc_r = 1;
    for g_i = 1:length(gap_idx_l)
        % left eye
        if gap_idx_l(g_i) == 1
            if gap_idx_l(bf_l) == 0
                bf_l = g_i;
            end
            bc_l = g_i;
        else
            if bc_l - bf_l < pipe_pars.max_gap_length && gap_idx_l(bf_l) == 1
                eye_3D_pos(1:3,bf_l:bc_l-1) = eye_3D_pos(1:3,bf_l) + (eye_3D_pos(1:3,bc_l)-eye_3D_pos(1:3,bf_l))*(1:(bc_l-bf_l))/(bc_l - bf_l);
                gip_3D_pos(:,bf_l:bc_l-1) = gip_3D_pos(:,bf_l) + (gip_3D_pos(:,bc_l)-gip_3D_pos(:,bf_l))*(1:(bc_l-bf_l))/(bc_l - bf_l);
                gap_idx_l(bf_l:bc_l-1) = 0;
            end
        end
        % right eye
        if gap_idx_r(g_i) == 1
            if gap_idx_r(bf_r) == 0
                bf_r = g_i;
            end
            bc_r = g_i;
        else
            if bc_r - bf_r < pipe_pars.max_gap_length && gap_idx_l(bf_r) == 1
                eye_3D_pos(4:6,bf_r:bc_r-1) = eye_3D_pos(4:6,bf_r) + (eye_3D_pos(4:6,bc_r)-eye_3D_pos(4:6,bf_r))*(1:(bc_r-bf_r))/(bc_r - bf_r);
                gip_3D_pos(:,bf_r:bc_r-1) = gip_3D_pos(:,bf_r) + (gip_3D_pos(:,bc_r)-gip_3D_pos(:,bf_r))*(1:(bc_r-bf_r))/(bc_r - bf_r);
                gap_idx_l(bf_r:bc_r-1) = 0;
            end
        end 
    end
    % label eye open points
    eye_open_idx = ~(gap_idx_r|gap_idx_l); % sanity check: 97% of data is labeled as eye open
    gaze_struct.gap_idx = ~eye_open_idx;
    
    %% smoothing eye location using moving average
    mv_avg_eye_3D_pos = eye_3D_pos;
    mv_avg_win_len = floor(pipe_pars.noise_reduction/2);
    for m_i = mv_avg_win_len+1:size(eye_3D_pos,2)-mv_avg_win_len
        mv_avg_eye_3D_pos(:,m_i) = mean(eye_3D_pos(:,m_i+(-mv_avg_win_len:mv_avg_win_len)),2);
    end
    
    %% calculate angular velocity
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
    vel_win_len = floor(pipe_pars.velocity_smooth_win_len*srate/2);
    for v_i = vel_win_len+1:size(eye_3D_pos,2)-vel_win_len
        dist = sqrt(sum(diff(e_pos(:,[v_i-vel_win_len,v_i+vel_win_len]),2).^2));
        ang(v_i) = 2*asin(dist/2);
        v_ang(v_i) = ang(v_i) / sum(pt_eg(v_i+(-vel_win_len:vel_win_len)));
    end
    
    %% converge eye 3D data from xyz to angle
    % The data has been normalized already.
    theta_x_l = zeros(1,size(eye_3D_pos,2));
    theta_z_l = zeros(1,size(eye_3D_pos,2));
    theta_x_r = zeros(1,size(eye_3D_pos,2));
    theta_z_r = zeros(1,size(eye_3D_pos,2));

    for t_i = 1:length(theta_x_l)
        theta_z_l = acos(eye_3D_pos(3,:));
        theta_z_r = acos(eye_3D_pos(6,:));
        theta_x_l(t_i) = acos(eye_3D_pos(1,t_i)./sqrt(sum(eye_3D_pos(1:2,t_i).^2)));
        theta_x_r(t_i) = acos(eye_3D_pos(4,t_i)./sqrt(sum(eye_3D_pos(4:5,t_i).^2)));
        if eye_3D_pos(2,t_i) < 0
            theta_x_l(t_i) = -theta_x_l(t_i);
        end
        if eye_3D_pos(5,t_i) < 0
            theta_x_r(t_i) = -theta_x_r(t_i);
        end
    end

    figure
    plot(pt_eg,theta_z_l/pi*180,'DisplayName','left')
    hold on
    grid on
    plot(pt_eg,theta_z_r/pi*180,'DisplayName','right')
    for s_i = 1:length(plt_snap)
        pt = s_snap.time_stamps(s_i)-s_eyeGaze.time_stamps(1);
        plot([pt,pt], get(gca,'YLim'), 'k--')
    end
    ytop = get(gca,'YLim');
    scatter(s_snap.time_stamps-s_eyeGaze.time_stamps(1), plt_snap/max(plt_snap)*ytop(2), 'r')

    %% get distribution at fixation state
    % fixation region
    pt_snap = s_snap.time_stamps(5:2:end)-s_eyeGaze.time_stamps(1);
    % round up snap time stamps with eye gaze stream time stamps
    for t_i = 1:length(pt_snap)
        pt_snap(t_i) = pt_eg(find(pt_eg>pt_snap(t_i),1,'first'));
    end
    interval_snap = diff(pt_snap);
    % sample from fixation region
    sample_fix_l = [];
    sample_fix_r = [];
    for int_i = 1:length(interval_snap)
        bl = find(pt_eg == pt_snap(int_i));
        br = find(pt_eg == (pt_snap(int_i)+interval_snap(int_i)));
        % shrink sampling window to reject samples near edges
        bl = round(mean([bl br]) - r_rej*(br-bl)/2);
        br = round(mean([bl br]) + r_rej*(br-bl)/2);
        tmp_sample_l = theta_z_l(bl:br);
        tmp_sample_r = theta_z_r(bl:br);
        % remove mean
        tmp_sample_l = tmp_sample_l - median(tmp_sample_l);
        tmp_sample_r = tmp_sample_r - median(tmp_sample_r);
        % add to sample distribution
        sample_fix_l = [sample_fix_l, tmp_sample_l];
        sample_fix_r = [sample_fix_r, tmp_sample_r];
    end

    % ====================
    % get angle threshold for eye gaze fixation (3 std)
    thres_eyeAng = mean([max(abs(sample_fix_l)),max(abs(sample_fix_r))]); % +/- 2.66 deg
    % ====================
    % calculate angular speed threshold
    speed_fix_l = diff(sample_fix_l)*floor(s_eyeGaze.info.effective_srate);
    speed_fix_r = diff(sample_fix_r)*floor(s_eyeGaze.info.effective_srate);
    thres_eyeAngSpeed = mean([max(abs(speed_fix_l)),max(abs(speed_fix_r))]); % 242 deg/s (previous reported threshold = 130 deg/s)

    %% cacluate fixation for eye gaze
    diff_eg = diff(pt_eg);
    speed_z_l = abs(diff(theta_z_l)*srate)/pi*180;
    speed_z_r = abs(diff(theta_z_r)*srate)/pi*180;
    eye_fix_l = speed_z_l <= thres_eyeAngSpeed/pi*180;
    eye_fix_r = speed_z_r <= thres_eyeAngSpeed/pi*180;
    eye_test = eye_fix_l & eye_fix_r;
    % filter by the minimum fixation length 150 ms (Irwin 1992)
    eye_fix = false(size(eye_test));
    bl = 1;
    br = 1;
    for b_i = 1:length(eye_test)
        if eye_test(br)~=1
            if sum(diff_eg(bl:br)) > min_fix_len
                eye_fix(bl:br) = true;
            end
            bl=br;
        end
        br = br+1;
    end
    % Assume fix at the beginning
    eye_fix = [true, eye_fix];

    %% ========
    speed_z = abs(diff(theta_z_l))*90;
    figure
    plot(pt_eg(1:end-1), speed_z/pi*180, 'linewidth', 3, 'DisplayName','Ang speed')
    grid on
    hold on
    for s_i = 3:2:length(plt_snap(3:end))
        pt = s_snap.time_stamps(s_i)-s_eyeGaze.time_stamps(1);
        plot([pt,pt], get(gca,'YLim'), 'k--')
    end
    plot(pt_eg, theta_z_l*300 + 500, 'DisplayName','Ang')
    plot(pt_eg,thres_eyeAngSpeed/pi*180*ones(size(pt_eg)),'r-','linewidth',3, 'DisplayName','Threshold')
    xlabel('Time (s)')
    ylabel('Ang speed (deg/s)')
    legend(flipud(findobj(gca,'-regexp','DisplayName', '[^'']')),'location','best');
    set(gcf, 'Color', [1 1 1])
    set(gca,'fontsize',20)
end
