%% Compare head rotation between fixing on targets / distractors
%% Open EEGLAB
restoredefaultpath
addpath('/home/yuan/Documents/Tool/eeglab_current/'); eeglab

%% define path
filepath = './';
saveParaPath = [filepath,'parameters/'];
if ~exist(saveParaPath,'dir')
    mkdir(saveParaPath)
end
addpath('dependencies/')

%% parameter setting
% preprocessing
noise_reduction = 5; % moving average with +/- n samples, applying on all the data streams
% plotting
lw = 3;
ms = 15;

%% load stream
% ======= data stream in eyeGaze stream (36 Chs) ======== 04/23/2020
% 0 - 2d coordinate of left eye
% 2 - 2d coordinate of right eye
% 4 - 3d direction of left eye
% 7 - 3d direction of right eye
% 10 - 3d position of combined hit spot
% 13 - 3d position of head
% 16 - 3d forward direction of head
% 19 - 3d velocity of head
% 22 - 3d angular velocity of head
% 25 - left eye openness
% 26 - right eye openness
% 27 - 3d position of chest IMU
% 30 - 3d forward direction of chest IMU
% 33 - 3d velocity of chest IMU
streams = load_xdf([filepath,'bullet01.xdf']);

%% extract streams
s_eyeMarker = streams{cellfun(@(x) strcmp(x.info.name,'ProEyeMarker'), streams)};
s_eyeGaze = streams{cellfun(@(x) strcmp(x.info.name,'ProEyeGaze'), streams)};
s_grab = streams{cellfun(@(x) strcmp(x.info.name,'GrabMarker'), streams)};
s_EEG = streams{cellfun(@(x) strcmp(x.info.name,'EEG'), streams)};
% experiment segment 
seg_range = s_eyeGaze.segments(1).index_range;
% channel and data length
[nbchan, pnts] = size(s_eyeGaze.time_series(:,seg_range(1):seg_range(2)));
% GIP fix index
fgip_idx = cal_fix_index(streams);

%% smoothing all the data streams by moving average
ori_data = s_eyeGaze.time_series(:,seg_range(1):seg_range(2));
smooth_data = zeros(size(ori_data));
mv_avg_win_len = floor(noise_reduction/2);
for m_i = mv_avg_win_len+1:pnts-mv_avg_win_len
    if all(~isnan(smooth_data(:,m_i+(-mv_avg_win_len:mv_avg_win_len)))) % ensure there is no missing signals
        smooth_data(:,m_i) = mean(ori_data(:,m_i+(-mv_avg_win_len:mv_avg_win_len)),2);
    end
end

%% extract data from eye Gaze stream
eye_2D_pos = s_eyeGaze.time_series(1:4,seg_range(1):seg_range(2)); % left_xy, right_xy
eye_3D_pos = s_eyeGaze.time_series(5:10,seg_range(1):seg_range(2)); % left_xyz, right_xyz
gip_3D_pos = s_eyeGaze.time_series(11:13,seg_range(1):seg_range(2));
head_loc = s_eyeGaze.time_series(14:16,seg_range(1):seg_range(2));
head_direct = s_eyeGaze.time_series(17:19,seg_range(1):seg_range(2));
head_vel = s_eyeGaze.time_series(20:22,seg_range(1):seg_range(2));
head_rot = s_eyeGaze.time_series(23:25,seg_range(1):seg_range(2));
eye_open_l = s_eyeGaze.time_series(26,seg_range(1):seg_range(2));
eye_open_r = s_eyeGaze.time_series(27,seg_range(1):seg_range(2));
chest_loc = s_eyeGaze.time_series(28:30,seg_range(1):seg_range(2));
chest_direct = s_eyeGaze.time_series(31:33,seg_range(1):seg_range(2));
chest_rot = s_eyeGaze.time_series(34:36,seg_range(1):seg_range(2));
% time axis for ploting
pt_eg = s_eyeGaze.time_stamps(seg_range(1):seg_range(2))-s_eyeGaze.time_stamps(seg_range(1));
% corrected time axes between eyeMarker and eyeGaze streams
pt_em = s_eyeMarker.time_stamps-s_eyeGaze.time_stamps(seg_range(1));
% time difference
diff_eg = diff(pt_eg);
% round up eye marker stream time stamps with eye gaze stream time stamps
for t_i = 1:length(pt_em)
    pt_em(t_i) = pt_eg(find(pt_eg>pt_em(t_i),1,'first'));
end
% sampling rate
srate = 1/mean(diff(pt_eg));

%% find out targets and distractors time points 
idx_tar = find(cellfun(@(x) contains(x,'Target'),s_eyeMarker.time_series));
idx_dis = find(cellfun(@(x) contains(x,'Distractor'),s_eyeMarker.time_series));
tar_name = s_eyeMarker.time_series(idx_tar);
dis_name = s_eyeMarker.time_series(idx_dis);
uni_tar = unique(tar_name);
uni_dis = unique(dis_name);
% merge markers with small gap
thres_MarkerGap = 5; % sec
diff_t_tar = diff(pt_em(idx_tar)) > thres_MarkerGap;
diff_t_dis = diff(pt_em(idx_dis)) > thres_MarkerGap;
diff_n_tar = ~cellfun(@(x, y) strcmp(x, y), tar_name(1:end-1), tar_name(2:end));
diff_n_dis = ~cellfun(@(x, y) strcmp(x, y), dis_name(1:end-1), dis_name(2:end));
merg_tar = [true diff_t_tar | diff_n_tar];
merg_dis = [true diff_t_dis | diff_n_dis];
% event time
t_tar = pt_em(idx_tar(merg_tar));
t_dis = pt_em(idx_dis(merg_dis));
t_interest = [idx_tar(merg_tar), idx_dis(merg_dis); t_tar, t_dis;...
              ones(size(t_tar)), zeros(size(t_dis))]';
t_interest = sortrows(t_interest, 2); % [idx in eventMarker series, time stamps in eyeTracker, labels for tar/dis]

%% centralize head location
% head_loc = head_loc - mean(head_loc,2);
ds = 10;
ds_h = head_loc(:,1:ds:end);
cmap = jet(size(ds_h,2));
ms_list = 15*ones(1,size(ds_h,2));
figure
scatter(ds_h(1,:),ds_h(3,:),ms_list,cmap)
% scatter3(ds_h(1,:),ds_h(2,:),ds_h(3,:))
% scatter3(head_loc(1,:),head_loc(2,:),head_loc(3,:));

%% head rotation behaviors before and after finding tar
ev_duration = [-1 2]; % sec before and after finding target/ distractor
sample_duration = round(ev_duration*srate);
rot_tar = cal_epoch_ev(head_rot, pt_eg, t_tar, ev_duration, srate);
rot_dis = cal_epoch_ev(head_rot, pt_eg, t_dis, ev_duration, srate);
fr_tar = cal_epoch_ev(fgip_idx, pt_eg, t_tar, ev_duration, srate);
fr_dis = cal_epoch_ev(fgip_idx, pt_eg, t_dis, ev_duration, srate);


%% plot epoch
% shaded_method = {@median, @(x) [quantile(x,0.75)-nanmedian(x);nanmedian(x)-quantile(x,0.25)]};
shaded_method = {@mean, @(x) [quantile(x,0.9)-nanmean(x);nanmean(x)-quantile(x,0.1)]};
t_ruler = (sample_duration(1):sample_duration(2)-1)/srate;
% plt_tar = abs(squeeze(rot_tar(1,:,:)));
% plt_dis = abs(squeeze(rot_dis(1,:,:)));

plt_tar = squeeze(sqrt(sum(rot_tar.^2,1)));
plt_dis = squeeze(sqrt(sum(rot_dis.^2,1)));

% statistical test
% tar_before = reshape(plt_tar(1:abs(sample_duration(1)),:),1,[]);
% dis_before = reshape(plt_dis(1:abs(sample_duration(1)),:),1,[]);
% tar_after = reshape(plt_tar(abs(sample_duration(1))+1:end,:),1,[]);
% dis_after = reshape(plt_dis(abs(sample_duration(1))+1:end,:),1,[]);
% [p_before,h_before] = ranksum(tar_before,dis_before);
% [p_after,h_after] = ranksum(tar_after,dis_after);

figure
hold on
grid on
ftar = shadedErrorBar(t_ruler,plt_tar',shaded_method,'lineprops','-b');
ftar.mainLine.LineWidth = lw;
ftar.mainLine.DisplayName = 'Target';
fdis = shadedErrorBar(t_ruler,plt_dis',shaded_method,'lineprops','-r');
fdis.mainLine.LineWidth = lw;
fdis.mainLine.DisplayName = 'Distractor';
plot([0 0],get(gca,'YLim'),'--k','linewidth', 3,'DisplayName','Onset');
legend(flipud(findobj(gca,'-regexp','DisplayName', '[^'']')),'location','northwest')
ylabel('Angular Speed (\pi/s)')
xlabel('Time (s)')
title('Head Rot. (all)')
% set(gca,'xTick',round(t_ruler(1)):round(t_ruler(end)))
set(gca,'xTick',round(t_ruler(1)):0.1:round(t_ruler(end)))
ax = gca;
xName = repmat({''},1,length(ax.XTick));
tmp = arrayfun(@(x) num2str(x),round(t_ruler(1)):0.5:round(t_ruler(end)),'uniformoutput',0);
[xName{1:5:end}] = deal(tmp{:});
set(gca,'xTickLabel',xName)
set(gca,'fontsize',30)
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
set(gcf,'color',[1 1 1])

%% plot GIP fixation epoch
% shaded_method = {@median, @(x) [quantile(x,0.75)-nanmedian(x);nanmedian(x)-quantile(x,0.25)]};
% shaded_method = {@mean, @(x) [quantile(x,0.9)-nanmean(x);nanmean(x)-quantile(x,0.1)]};
shaded_method = {@mean, @std};
t_ruler = (sample_duration(1):sample_duration(2)-1)/srate;
plt_tar = fr_tar;
plt_dis = fr_dis;

% statistical test
% tar_before = reshape(plt_tar(1:abs(sample_duration(1)),:),1,[]);
% dis_before = reshape(plt_dis(1:abs(sample_duration(1)),:),1,[]);
% tar_after = reshape(plt_tar(abs(sample_duration(1))+1:end,:),1,[]);
% dis_after = reshape(plt_dis(abs(sample_duration(1))+1:end,:),1,[]);
% [p_before,h_before] = ranksum(tar_before,dis_before);
% [p_after,h_after] = ranksum(tar_after,dis_after);

figure
hold on
grid on
ftar = shadedErrorBar(t_ruler,plt_tar',shaded_method,'lineprops','-b');
ftar.mainLine.LineWidth = lw;
ftar.mainLine.DisplayName = 'Target';
fdis = shadedErrorBar(t_ruler,plt_dis',shaded_method,'lineprops','-r');
fdis.mainLine.LineWidth = lw;
fdis.mainLine.DisplayName = 'Distractor';
plot([0 0],get(gca,'YLim'),'--k','linewidth', 3,'DisplayName','Onset');
legend(flipud(findobj(gca,'-regexp','DisplayName', '[^'']')),'location','northwest')
ylabel('Fixation Index')
xlabel('Time (s)')
title('GIP Fixation')
% set(gca,'xTick',round(t_ruler(1)):round(t_ruler(end)))
set(gca,'xTick',round(t_ruler(1)):0.1:round(t_ruler(end)))
ax = gca;
xName = repmat({''},1,length(ax.XTick));
tmp = arrayfun(@(x) num2str(x),round(t_ruler(1)):0.5:round(t_ruler(end)),'uniformoutput',0);
[xName{1:5:end}] = deal(tmp{:});
set(gca,'xTickLabel',xName)
set(gca,'fontsize',30)
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
set(gcf,'color',[1 1 1])

%% overlap two plot
% shaded_method = {@median, @(x) [quantile(x,0.75)-nanmedian(x);nanmedian(x)-quantile(x,0.25)]};
shaded_method1 = {@mean, @std};
shaded_method2 = {@mean, @(x) [quantile(x,0.9)-nanmean(x);nanmean(x)-quantile(x,0.1)]};
t_ruler = (sample_duration(1):sample_duration(2)-1)/srate;
plt_1 = fr_dis;
plt_2 = squeeze(sqrt(sum(rot_dis.^2,1)));

figure
hold on
grid on
ftar = shadedErrorBar(t_ruler,plt_1',shaded_method1,'lineprops','-b');
ftar.mainLine.LineWidth = lw;
ftar.mainLine.DisplayName = 'Fixation';
fdis = shadedErrorBar(t_ruler,plt_2',shaded_method2,'lineprops','-r');
fdis.mainLine.LineWidth = lw;
fdis.mainLine.DisplayName = 'Head Rot.';
plot([0 0],get(gca,'YLim'),'--k','linewidth', 3,'DisplayName','Onset');
[ax,h1,h2] = plotyy(t_ruler,zeros(size(t_ruler)),t_ruler,zeros(size(t_ruler)));
set([h1,h2],'DisplayName','')
set(ax,'fontsize',30);
ax(1).YLim = [0 2];
ax(1).YTick = 0:0.5:2;
set(ax(1).YLabel,'String','Fixation Index');
set(ax(1).YLabel,'Color','b');
set(ax(1),'YColor','b');
set(ax(2).YLabel,'String','Angular Speed (\pi/s)');
set(ax(2).YLabel,'Color','r');
set(ax(2),'YColor','r');
set([h1,h2],'Visible','off')
legend(flipud(findobj(gca,'-regexp','DisplayName', '[^'']')),'location','northwest')
xlabel('Time (s)')
title('Distractor')
% set(gca,'xTick',round(t_ruler(1)):round(t_ruler(end)))
set(gca,'xTick',round(t_ruler(1)):0.1:round(t_ruler(end)))
ax = gca;
xName = repmat({''},1,length(ax.XTick));
tmp = arrayfun(@(x) num2str(x),round(t_ruler(1)):0.5:round(t_ruler(end)),'uniformoutput',0);
[xName{1:5:end}] = deal(tmp{:});
set(gca,'xTickLabel',xName)
set(gca,'fontsize',30)
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
set(gcf,'color',[1 1 1])


%% look into head direction to see if it point straight toward GIP

