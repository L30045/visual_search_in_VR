function plt_fix_epoch(s_eyeMarker, pt_em, pt_eg, srate, eye_fix_idx, ev_duration)
%% Plot target epoch with fixation and object label
% Input:
%   s_eyeMarker: eyeMarker stream
%   pt_em: time stamps for event marker of interest
%   pt_eg: time stamps for eye Gaze stream of interest
%   srate: sampling rate
%   eye_fix_idx: fixation index from cal_fix_pupil function
%   ev_duration: epoch length for plotting


if ~exist('ev_duration','var')
    ev_duration = [-5 5];
end

all_target = cellfun(@(x) strcmp(x(1:3),'Tar'),s_eyeMarker.time_series(1:length(pt_em)));
all_distractor = cellfun(@(x) strcmp(x(1:3),'Dis'),s_eyeMarker.time_series(1:length(pt_em)));
target = all_target & ismember(pt_em, pt_eg(eye_fix_idx));
distractor = all_distractor & ismember(pt_em, pt_eg(eye_fix_idx));
miss_tar = (all_target - ismember(pt_em, pt_eg(eye_fix_idx))) > 0;


obj_fix_idx = ismember(pt_eg, pt_em) & eye_fix_idx;
tar_fix = ismember(pt_eg, pt_em(target));
tar_miss = ismember(pt_eg, pt_em(miss_tar));
dis_fix = ismember(pt_eg, pt_em(distractor));
vis_fix = double([eye_fix_idx; obj_fix_idx; tar_fix; tar_miss; dis_fix]);

tar_ep = cal_epoch_ev(vis_fix, pt_eg, pt_eg(tar_miss|tar_fix), ev_duration, srate);
[nr, nc] = size(tar_ep,[2,3]);
t_ruler = ev_duration(1):(1/srate):ev_duration(2);
cmap = [0.5 0.5 0.5; 0 1 0; 0 0 1; 0 0.3 1; 1 0 0; 0 0 0];
name_tag = {'fix','obj','fix tar','miss tar','fix dis'};
plt_idx = sum(sum(tar_ep,2),3)~=0;
plt_tar = squeeze(sum(tar_ep(plt_idx,:,:),1));
if any(plt_idx([4,5])~=0)
    plt_tar = plt_tar + squeeze(tar_ep(4,:,:))*(plt_idx(4)+2);
    plt_tar = plt_tar + squeeze(tar_ep(5,:,:))*sum(plt_idx([4,5]));
end
plt_tar(plt_tar==0) = NaN;
h = pcolor(t_ruler, 1:nc+1, [plt_tar, nan(nr,1);nan(1, 1+nc)]');
set(h,'EdgeColor','none')
colormap(cmap(plt_idx,:))
ch = colorbar;
ch.Ticks = 1:sum(plt_idx);
ch.TickLabels = name_tag(plt_idx);
xlabel('Time (s)')
ylabel('Trials')
set(gca,'YTick',[1:nc]+0.5)
tar_name = cellfun(@(x,y) ['tar-',x(end),sprintf('(%d sec)',y)],s_eyeMarker.time_series(all_target),num2cell(round(pt_em(all_target))), 'uniformoutput',0);
set(gca,'YTickLabel',tar_name)
set(gca,'fontsize',20)
set(gcf,'color',[1 1 1])


end