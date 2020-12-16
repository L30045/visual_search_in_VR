function animate_2D(head_loc, head_direct, srate, bg_gip, ev_idx, varargin)
%% This function animate the subject's movement in the VR room
% Input:
%   head_loc: head location
%   head_direct: head direction
%   srate: sampling rate
%   bg_gip: background GIP for plotting the room outline.
%   ev_idx: index for target/distractor event from extract_tar_idx.m
%   ds_rate: downsampling rate (optional)
%   playback_speed: playback_speed (optional)
%   t_tail: animation tail length in sec (optional)

%% Parameters input
p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'head_loc');
addRequired(p,'head_direct');
addRequired(p,'srate');
addRequired(p,'bg_gip');
addRequired(p,'ev_idx'); % ev_idx = [all_idx_tar; tar_fix; all_idx_dis; dis_fix];
addOptional(p,'ds_rate',[]);
addOptional(p,'playback_speed',1);
addOptional(p,'t_tail',1); % (sec)
parse(p,head_loc,head_direct,srate,bg_gip,ev_idx,varargin{:})
ds_rate = p.Results.ds_rate;
playback_speed = p.Results.playback_speed;
t_tail = p.Results.t_tail;
% time length
fprintf('real-world time length: %.f sec\n', size(head_loc,2)/srate)

%% extract target/distractor GIP
all_idx_tar = ev_idx(1,:);
tar_fix = ev_idx(2,:);
all_idx_dis = ev_idx(3,:);
dis_fix = ev_idx(4,:);
bg_tar_gip = bg_gip(:,all_idx_tar);
bg_dis_gip = bg_gip(:,all_idx_dis);
tar_gip = bg_gip(:,tar_fix);
dis_gip = bg_gip(:,dis_fix);

%% plotting parameters setting
if ~isempty(ds_rate)
    len_ds = length(1:srate/ds_rate:size(bg_gip,2));
    head_loc = head_loc(:,round(1:srate/ds_rate:end));
    head_direct = head_direct(:,round(1:srate/ds_rate:end));
    [ds_idx_tar, uni_idx_tar] = unique(arrayfun(@(x) max([1 x]), round(find(tar_fix)/(srate/ds_rate))));
    [ds_idx_dis, uni_idx_dis] = unique(arrayfun(@(x) max([1 x]), round(find(dis_fix)/(srate/ds_rate))));
    tar_fix = false(1,len_ds);
    tar_fix(ds_idx_tar) = true;
    dis_fix = false(1,len_ds);
    dis_fix(ds_idx_dis) = true;
    tar_gip = tar_gip(:,uni_idx_tar);
    dis_gip = dis_gip(:,uni_idx_dis);
    srate = ds_rate;
end
% transform direction into angle
head_ang = atan(head_direct(1,:)./head_direct(2,:));
head_ang(head_direct(2,:) < 0) = head_ang(head_direct(2,:) < 0)+pi;

% time pause for playback
t_pause = 1/(srate*playback_speed);

lw = 3;
ms = 15;

%% create clip video
% video_name = 'bullet_demo_test.avi';
% c_i = 1;
% while exist(video_name,'file')
%     video_name = [video_name(1:16),sprintf('(%d).avi',c_i)];
%     c_i = c_i+1;
% end
% clip_video = VideoWriter(video_name,'Motion JPEG AVI');
% open(clip_video)

%% initialize animation
% counter for buffer index
bh_c = 1;
be_c = 1;
% figure
anime_fig = figure;
daspect([1 1 1])
hold on
set(gcf,'color',[1 1 1]);
% initialize the tail
% for head location
anime_head = scatter(head_loc(1,1)*ones(1,round(t_tail*srate)),...
                     head_loc(2,1)*ones(1,round(t_tail*srate)),...
                     50,'k','o','filled','DisplayName','Head Location');
% for event marker, [subject loc; target loc]
anime_event = plot(head_loc(1,1)*ones(2,round(t_tail*srate)),...
                   head_loc(2,1)*ones(2,round(t_tail*srate)),...
                   'b-d','markersize',ms,'linewidth',lw);
% background
h1 = scatter(bg_gip(1,:),bg_gip(2,:),10,'x','DisplayName','GIP (all)');
h1.CData = [0.7 0.7 0.7];
% target
h1 = scatter(bg_tar_gip(1,:),bg_tar_gip(2,:),100*ones(1,size(bg_tar_gip,2)),'b','d','filled','DisplayName','Target');
h1.LineWidth = lw;
h1.MarkerEdgeColor = 'k';
% distractor
h2 = scatter(bg_dis_gip(1,:),bg_dis_gip(2,:),100*ones(1,size(bg_dis_gip,2)),'r','s','filled','DisplayName','Distractor');
h2.LineWidth = lw;
h2.MarkerEdgeColor = 'k';
% starting point
h_head = drawHeadCartoon(head_loc(1,1),head_loc(2,1),head_ang(1));
anime_head.XData(bh_c) = head_loc(1,1);
anime_head.YData(bh_c) = head_loc(2,1);
% l1 = legend(flipud(findobj(gca,'-regexp','DisplayName', '[^'']')));
% l1.String = {'GIP (all)','Target (GIP)','Distractor (GIP)','Head Location'};
set(anime_fig,'defaultLegendAutoUpdate','off')
set(gca,'fontsize',20);
set(gca,'visible','off');
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
% record video
% input_frame = getframe(gcf);
% writeVideo(clip_video,input_frame);
pause()

%% animation
tic
for i = 2:size(head_loc,2)
%     if i == 18
%         pause()
%     end
    % update buffer counters (the counters are operating independently in
    % case we want to modify the tail length separately in the future)
    bh_c = bh_c+1;
    be_c = be_c+1;
    if bh_c > size(anime_head.XData,2)
        bh_c = 1;
    end
    if be_c > length(anime_event)
        be_c = 1;
    end
    % plot current head location
    delete(h_head)
    h_head = drawHeadCartoon(head_loc(1,i),head_loc(2,i),head_ang(i));
    drawnow
    anime_head.XData(bh_c) = head_loc(1,i);
    anime_head.YData(bh_c) = head_loc(2,i);
    % update event buffer
    anime_event(be_c).XData = nan(2,1);
    % plot target event
    if tar_fix(i)
        anime_event(be_c).XData = [head_loc(1,i), tar_gip(1,1)];
        anime_event(be_c).YData = [head_loc(2,i), tar_gip(2,1)];
        tar_gip(:,1) = [];
        anime_event(be_c).Color = [0 0 1];
        anime_event(be_c).Marker = 'diamond';
        anime_event(be_c).MarkerEdgeColor = [1 1 1];
        anime_event(be_c).MarkerFaceColor = [0 0 1];
%         anime_event{1,end} = scatter(ds_h(1,i),ds_h(3,i),100,'b','d','filled');
%         anime_event{2,end} = scatter(tar_gip(1,pc_i),tar_gip(3,pc_i),100,'b','d','filled');
%         anime_event{2,end}.LineWidth = lw;
%         anime_event{2,end}.MarkerEdgeColor = 'k';
%         anime_event{3,end} = plot([ds_h(1,i),tar_gip(1,pc_i)],[ds_h(3,i),tar_gip(3,pc_i)],'b-','linewidth',2);
    elseif dis_fix(i)
        anime_event(be_c).XData = [head_loc(1,i), dis_gip(1,1)];
        anime_event(be_c).YData = [head_loc(2,i), dis_gip(2,1)];
        dis_gip(:,1) = [];
        anime_event(be_c).Color = [1 0 0 ];
        anime_event(be_c).Marker = 'square';
        anime_event(be_c).MarkerEdgeColor = [1 1 1];
        anime_event(be_c).MarkerFaceColor = [1 0 0];
%         anime_event{1,end} = scatter(ds_h(1,i),ds_h(3,i),100,'r','s','filled');
%         anime_event{2,end} = scatter(dis_gip(1,1),dis_gip(3,1),100,'r','s','filled');
%         anime_event{2,end}.LineWidth = lw;
%         anime_event{2,end}.MarkerEdgeColor = 'k';
%         anime_event{3,end} = plot([ds_h(1,i),dis_gip(1,1)],[ds_h(3,i),dis_gip(3,1)],'r-','linewidth',2);
    end
    pause(t_pause)
%     drawnow

    %% record video
%     input_frame = getframe(gcf);
%     writeVideo(clip_video,input_frame);

end
t_end = toc;
fprintf('playback time length: %.f sec\n',t_end)
close(gcf)
close(clip_video)

end