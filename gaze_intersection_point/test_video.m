%% test gip fixation
ori_video = VideoReader('DOWNTOWN DAY.mp4');
nb_frame = ceil(ori_video.FrameRate*ori_video.Duration);
frate = ori_video.FrameRate;

%% load GIP data
addpath(xdf_path)
streams = load_xdf('pilot01_street_day.xdf');
s_GIP = streams{2};
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

x_gip = s_GIP.time_series(2,:);
y_gip = s_GIP.time_series(3,:);
srate = round(s_GIP.info.effective_srate);

if (round(length(x_gip)/srate) - round(nb_frame/frate)) > 1 %sec
    disp('Recording lengths of eye tracker and video are different.')
end

figure
scatter(x_gip(1:100),y_gip(1:100))