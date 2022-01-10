%% calculate fixation based on threshold and fixation duration
function fix_idx = cal_fix_general(test_data,srate,thres_fix,varargin)
%% calculate fixation based on given dispersion/velocity threshold and fixation duration.
% Input:
%   [test_data]: 1-channel input data (1 by time)
%   [srate]: sampling rate
%   [thres_fix]: test_data higher than this threshold will be marked as
%   moving.
% Optional
%   [max_fix_interval]: merge adjacent fixations if the interval is smaller
%   than this threshold. (ms) (Default: 75 ms) Disable function by input
%   NaN.
%   [max_fix_ang]: merge adjacent fixations if the angle difference is
%   smaller than this threshold) (0.5 deg ref. Tobii default) (deg) Disable
%   function by input NaN.
%   [min_fix_len]: discard fixations if shorter than this threshold. (60 ms
%   ref. Tobii) (ms) Disable function by input NaN.
%
% Output:
%   fix_idx: fixation index (binary, fixation as 1)

    %% parameter setting
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p,'test_data');
    addRequired(p,'srate');
    addRequired(p,'thres_fix');
    addOptional(p,'max_fix_interval',75) % ms (merge adjacent fixations if the interval is smaller than 75 ms)
    addOptional(p,'max_fix_ang',1) % deg (merge adjacent fixations if the angle difference is smaller than 1 deg) (0.5 deg for tobii default)
    addOptional(p,'min_fix_len',150) % ms (discard fixations if shorter than 150ms. Tobii uses 60 ms instead)
    parse(p,test_data,srate,thres_fix,varargin{:})
    
    pipe_pars = p.Results;
    
    %% calculate fixation
    disp('Calculate fixation.')
    fix_idx = test_data < thres_fix;
    disp('Done.')    
  
    %% merge adjacent fixation
    if ~isnan(pipe_pars.max_fix_ang)
        disp('Merge adjacent fixation.')
        max_fix_interval = pipe_pars.max_fix_interval/1000*srate;
        fix_idx = merge_adj_fix(fix_idx,test_data,max_fix_interval,pipe_pars.max_fix_ang);
        disp('Done.')
    end
    
    %% remove fixation with short period
    disp('Remove fixation with short period.')
    min_fix_len = pipe_pars.min_fix_len/1000*srate;
    fix_idx = rm_short_fix(fix_idx,min_fix_len);
    
    disp('Done.')
    
end

