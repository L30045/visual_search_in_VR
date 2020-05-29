function ev_ep = cal_epoch_ev(data, pt_eg, t_ev, ev_duration, srate)
%% function for plotting event epoch
% This function will epoch data based on given event time points.
% Input:
%   data:   data streams to be processed (n by time matrix)
%   pt_eg:  time from eye gaze streams.
%   t_ev:   target event times
%   ev_duration:    epoch length
%
% Output:
%   ev_ep:  epoch based on target event.

%% Parameter setting
% get sample points for calculation
sample_duration = round(ev_duration*srate);
% storage for head rotation epoch [channels, epoch duration, # of event]
ev_ep = zeros(size(data,1), sum(abs(sample_duration)), length(t_ev));
% zero paddle to prevent data out of range
tmp_data = [zeros(size(data,1),abs(sample_duration(1))), data, zeros(size(data,1),sample_duration(2))];

% epoch extraction
for t_i = 1:length(t_ev)
    t_tmp = find(pt_eg == t_ev(t_i), 1)+abs(sample_duration(1));
    ev_ep(:,1:abs(sample_duration(1)),t_i) = tmp_data(:,t_tmp+sample_duration(1):(t_tmp-1));
    ev_ep(:,abs(sample_duration(1))+1:end, t_i) = tmp_data(:,t_tmp:(t_tmp+sample_duration(2)-1));
end

if size(ev_ep,1)==1
    ev_ep = squeeze(ev_ep);
end

end