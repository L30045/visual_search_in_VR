function [reconst_data,gap_idx] = identify_gaps(test_data,conf_idx,srate,thres_open,max_gap_length)
%% identify gaps (missing points) in data based on confidence index
% Input:
%   test_data: test_data (n by times)
%   conf_idx: confidence index [0,1]
%   srate: sampling rate
%   thres_open: conf_idx smaller than this threshold will be defined as gap
%   max_gap_length: maximum gap length to be fixed. Gaps with duration
%   longer than this threshold will be considered as missing data.
% Output:
%   reconst_data: linear reconstructed data
%   gap_idx (binary)

%%
reconst_data = test_data;
gap_idx = conf_idx < thres_open;
% fix gap that is not shorter than threshold
bf_l = 1; % floor 
for g_i = 1:length(gap_idx)
    bc_l = g_i; % ceiling
    if gap_idx(g_i)
        if ~gap_idx(bf_l)
            bf_l = g_i;
        end
    else
        if bc_l - bf_l < max_gap_length/1000*srate && gap_idx(bf_l)
            % fix small gap
            reconst_data(:,bf_l:bc_l-1) = test_data(:,max([1,bf_l-1])) + (test_data(:,bc_l)-test_data(:,max([1,bf_l-1])))*(1:(bc_l-bf_l))/(bc_l-bf_l+1);
            gap_idx(bf_l:bc_l-1) = false;
        else
            bf_l = bc_l;
        end
    end
end
% label eye open points
gap_idx = ~gap_idx;
fprintf('Eye open portion in the data: %2.f%%\n', 100*(sum(gap_idx)/length(conf_idx)));

end