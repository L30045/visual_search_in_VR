function [fix_idx, speed_gip] = cal_fix_gip(test_data, srate, calibration_data, noise_reduction, velocity_smooth_win_len, thres_v, thres_portion, max_fix_interval, min_fix_len, san_check)
%% calculate fixation based on GIP
% This function will calculation fixation based on the speed of GIP. The
% function assumes the data has been preprocessed and noise free.
% Input:
%   test_data:   dimension by samples (2D by times or 3D by times)
%   calibration_data:   fixation period for threshold calculation if
%   available.
%   srate:  sampling rate
%   noise_reduction:    moving average with +/- samples (default: 5 samples)
%   velocity_smooth_win_len:    window length to calculate velocity (default: 40 ms)
%   thres_v:    threshold for GIP speed (default: 0)
%   thres_portion:  data driven threshold setting by assuming portion of fixation in the data (default: 0.8) 
%   max_fix_interval:   % ms (merge adjacent fixations if the interval is smaller than 75 ms)
%   min_fix_len:    % ms (discard fixations if shorter than 150ms. Tobii uses 60 ms istead)
%   san_check:  sanity check for threshold setting
% Output:
%   idx_fix: binary array. (1 by samples)
%   speed_gip: GIP speed. (1 by samples)

%% parameter setting
if ~exist('calibration_data','var')
    calibration_data = [];
end
if ~exist('test_data','var') || isempty(test_data)
    error('test data required');
end
% merge calibration and test data
data = [calibration_data,test_data];
if size(data,1) > 3
    error('data dimension error');
end
if ~exist('srate','var') || isempty(srate)
    error('sampling rate required');
end
if ~exist('noise_reduction','var') || isempty(noise_reduction)
    noise_reduction = 5;
end
if ~exist('velocity_smooth_win_len','var') || isempty(velocity_smooth_win_len)
    velocity_smooth_win_len = 40;
end
if ~exist('thres_v','var') || isempty(thres_v)
    thres_v = 0;
end
if ~exist('thres_portion','var') || isempty(thres_portion)
    thres_portion = 0.7;
end
if ~exist('max_fix_interval','var') || isempty(max_fix_interval)
    max_fix_interval = 75;
end
if ~exist('min_fix_len','var') || isempty(min_fix_len)
    min_fix_len = 150;
end
if ~exist('san_check','var') || isempty(san_check)
    san_check = 0;
end

%% noise reduction by moving average
mv_avg_data = data;
mv_avg_win_len = floor(noise_reduction/2);
for m_i = mv_avg_win_len+1:size(data,2)-mv_avg_win_len
    if ~isnan(mv_avg_data(1,m_i+(-mv_avg_win_len:mv_avg_win_len)))
        % only reconstruct valid points
        mv_avg_data(:,m_i) = mean(data(:,m_i+(-mv_avg_win_len:mv_avg_win_len)),2);
    end
end

%% calculate GIP speed
dist = nan(1,size(data,2));
vel_win_len = round(0.001*velocity_smooth_win_len*srate/2);
for v_i = vel_win_len+1:size(data,2)-vel_win_len
     if ~isnan(mv_avg_data(1,v_i+[-vel_win_len,vel_win_len]))
        dist(v_i) = sqrt(sum(diff(mv_avg_data(:,[v_i-vel_win_len,v_i+vel_win_len])').^2));
     end
end
speed_gip = dist / velocity_smooth_win_len;

%% calculate GIP fixation based on speed
if thres_v == 0
    [n, edges] = histcounts(speed_gip, 'BinWidth', 0.001);
    portion = cumsum(n)/sum(n);
    if isempty(calibration_data)
        % use data driven threshold, assume 70%(thres_portion) of data are fixation.
        thres_v = edges(find(portion >= thres_portion, 1));
    else
        % use calibration data to calculate threshold
        % ============
        % method 1: assume data is normal distributed.
        % ============
%         thres_v = mean(speed_gip(vel_win_len+1:size(calibration_data,2)-vel_win_len))...
%                   + 2*std(speed_gip(vel_win_len+1:size(calibration_data,2)-vel_win_len));
        % ============
        % method 2: use median + 3 * quantile
        % ============
        tmp = speed_gip(vel_win_len+1:size(calibration_data,2)-vel_win_len);
        thres_v = nanmedian(tmp) + 3*diff(quantile(tmp,[0.5, 0.95]));
    end
end

fix_idx = speed_gip <= thres_v;

%% merge adjacent fixation
gap_floor = 1; % floor 
for f_i = 1:length(fix_idx)
    gap_ceiling = f_i; % ceiling
    if fix_idx(f_i) == 0
        if fix_idx(gap_floor) == 1
            gap_floor = f_i;
        end
    else
        if gap_ceiling - gap_floor < max_fix_interval/1000*srate ...
            && fix_idx(gap_floor) == 0 ...
            % merge adjacent fixation
            fix_idx(gap_floor:gap_ceiling-1) = 1;
        else
            gap_floor = gap_ceiling;
        end
    end
end

%% remove fixation with short period
fix_floor = 1; % floor 
for f_i = 1:length(fix_idx)
    fix_ceiling = f_i; % ceiling
    if fix_idx(f_i) == 1
        if fix_idx(fix_floor) == 0
            fix_floor = f_i;
        end
    else
        if fix_ceiling - fix_floor < min_fix_len/1000*srate && fix_idx(fix_floor) == 1
            % delete short fixation
            fix_idx(fix_floor:fix_ceiling-1) = 0;
        else
            fix_floor = fix_ceiling;
        end
    end
end

%% sanity check
if san_check == 0
    fprintf('\n Portion of fixation found: %.2f\n', sum(fix_idx)/size(data,2));
    fprintf('Thres Vel.: %f\n', thres_v);
    % fixation count distrubtion
    figure
    hold on
    grid on
    plot(edges(2:end), portion);
    plot(edges(2:end), thres_portion * ones(1,length(edges)-1))
    plot(thres_v, thres_portion, 'ro', 'DisplayName', sprintf('%f', thres_v))
    legend(findobj(gca,'-regexp','DisplayName', '[^'']'))
    title('Speed count distribution')
    ylabel('Portion')
    xlabel('Speed (unit/sec)')
    set(gca, 'fontsize', 20)
    % fixation time
    pt_eg = [1:size(data,2)]/srate;
    figure
    hold on
    grid on
    plot(pt_eg, speed_gip)
    plot(pt_eg(1:size(calibration_data,2)), speed_gip(1:size(calibration_data,2)), 'g-')
    plot(pt_eg, thres_v*fix_idx,'r-')
end

end