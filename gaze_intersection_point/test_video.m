%% test gip fixation
ori_video = VideoReader('DOWNTOWN DAY.mp4');
nb_frame = ceil(ori_video.FrameRate*ori_video.Duration);
frate = ori_video.FrameRate;
vHeight = ori_video.Height;
vWidth = ori_video.Width;
lw = 5;
ms = 200;

%% load GIP data
% addpath(xdf_path)
% streams = load_xdf('pilot01_street_day.xdf');
s_GIP = load('test_GIP_stream.mat');
s_GIP = s_GIP.s_GIP;
% channel information
% 1/ Video time stamp
% 2/ x-coordinate of GIP on screen [0-1] (-1 means the gaze is not intersecting with the screen)
% 3/ y-coordinate of GIP
% 4/ z-coordinate (always zero)
% 5/ Left eye openness [0-1] (-1 means the eye tracker loses pupil position)
% 6/ Right eye openness
% 7/ x-coordinate of left pupil position
% 8/ y-coordinate of left pupil position
% 9/ x-coordinate of right pupil position
% 10/ y-coordinate of right pupil position  

norm_x_gip = s_GIP.time_series(2,:);
norm_y_gip = s_GIP.time_series(3,:);
srate = round(s_GIP.info.effective_srate);
% transfer back to video size
v_x_gip = (norm_x_gip+1)*vWidth/2;
v_y_gip = (norm_y_gip+1)*vHeight/2;

% remove the recording before video start
pt_eg = s_GIP.time_stamps;

if (round(length(v_x_gip)/srate) - round(nb_frame/frate)) > 1 %sec
    disp('Recording lengths of eye tracker and video are different.')
end

%% play video
t_extract = [5 15]; %sec
ori_video.CurrentTime = t_extract(1);
t_pause = 1/frate;
countFrame = diff(t_extract)*frate;
tic
for i = 1:countFrame
    vFrame = readFrame(ori_video);
    image(vFrame)
%     pause(t_pause)
end
toc

%% create clip video
clip_video = VideoWriter('demo.avi','Motion JPEG AVI');

%% overlap video with gip for 20 sec (limited by memory)
d_srate = 30;
t_extract = [5 15]; %sec
ori_video.CurrentTime = t_extract(1);
t_pause = 1/d_srate;
idx_start = t_extract(1)*srate;
img_buffer = cell(1,2);
gip_buffer = cell(1,2);
buffer_flag = false;
open(clip_video)
% plot first plot
vFrame = readFrame(ori_video);
figure
set(gcf,'units','normalized','outerposition',[0 0 1 1])
img_buffer{1} = image(vFrame);
hold on
gip_buffer{1} = scatter(v_x_gip(idx_start),v_y_gip(idx_start),ms,'b','linewidth',lw);
hold off
input_frame = getframe(gcf);
writeVideo(clip_video,input_frame);
pause()
% animation
for p_i = 1:diff(t_extract)*d_srate
    ori_video.CurrentTime = t_extract(1)+p_i*(1/d_srate);
    vFrame = readFrame(ori_video);
    img_buffer{~buffer_flag+1} = image(vFrame);
    hold on
    idx_plot = round(ori_video.CurrentTime*srate);
    gip_buffer{~buffer_flag+1} = scatter(v_x_gip(idx_plot),v_y_gip(idx_plot),ms,'b','linewidth',lw);
    input_frame = getframe(gcf);
    writeVideo(clip_video,input_frame);
    delete(img_buffer{buffer_flag+1})
    delete(gip_buffer{buffer_flag+1})
    buffer_flag = ~buffer_flag;
    clf
    pause(t_pause)
end
close(gcf)
close(clip_video)