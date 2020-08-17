function sanity_check(fix_struct)
logicalStr = {'False','True'};
t_ruler = fix_struct.time_stamps;
lw = 3;
ms = 15;
thres_ang = fix_struct.pipeline_pars.thres_ang;
thres_ang_v = fix_struct.pipeline_pars.thres_ang_v;
        
%% General report
disp('[General information]');
disp('---------------------');
exp_time = t_ruler(end)/60;
fprintf('Exeriment length: %.2f min\n',exp_time);
fprintf('Calibration data: %s\n',logicalStr{~isempty(fix_struct.pipeline_pars.calibration_data)+1});
fprintf('Eye open index: %s\n',logicalStr{~isempty(fix_struct.pipeline_pars.eye_open_idx)+1});
fprintf('Fix definition: %s\n',fix_struct.pipeline_pars.fix_selection);
% blink exam
% Generally, between each blink is an interval of 210 seconds; actual rates
% vary by individual averaging around 10 blinks per minute in a laboratory
% setting. However, when the eyes are focused on an object for an extended
% period of time, such as when reading, the rate of blinking decreases to
% about 3 to 4 times per minute.
% ref: Bentivoglio, Analysis of blink rate patterns in normal subjects,
% 2004.
avg_blink = length(fix_struct.gap_detection.blink_idx)/exp_time;
fprintf('Average number of blink per min: %.2f (average for adults: 10)\n',avg_blink);
% data missing rate
avg_miss = length([fix_struct.gap_detection.dataLose_idx{:}])/length(t_ruler)*100;
fprintf('Data missing rate: %.3f%%\n',avg_miss);
disp('====================');

%% exam threshold
disp('[Threshold setting]');
disp('---------------------');
fprintf('Angle threshold: %.2f deg\n',thres_ang);
fprintf('Angular speed threshold: %.2f deg/sec\n',thres_ang_v);
if ~isempty(fix_struct.pipeline_pars.calibration_data)
    fprintf('Calibration-data-driven Angle threshold: %.2f deg\n',fix_struct.pipeline_pars.cali_thres_ang);
    fprintf('Calibration-data-driven Angular speed threshold: %.2f deg/sec\n',fix_struct.pipeline_pars.cali_thres_ang_v);
end
% fixation portion
fix_rate = sum(fix_struct.eye_fixation.eye_fix_idx)/length(t_ruler)*100;
fprintf('Fixation portion: %2.1f%%\n',fix_rate);
disp('====================');

%% visualization
switch lower(fix_struct.pipeline_pars.eye_selection)
    case 'left'
        plt_ang = fix_struct.eye_movement.left_ang;
        plt_ang_v = fix_struct.eye_movement.left_ang_vel;
    case 'right'
        plt_ang = fix_struct.eye_movement.right_ang;
        plt_ang_v = fix_struct.eye_movement.right_ang_vel;
    case 'strictboth'
        plt_ang = mean([fix_struct.eye_movement.left_ang,fix_struct.eye_movement.right_ang]);
        plt_ang_v = mean([fix_struct.eye_movement.left_ang_vel,fix_struct.eye_movement.right_ang_vel]);
    case 'looseboth'
        plt_ang = mean([fix_struct.eye_movement.left_ang,fix_struct.eye_movement.right_ang]);
        plt_ang_v = mean([fix_struct.eye_movement.left_ang_vel,fix_struct.eye_movement.right_ang_vel]);
end
plt_fix_ang = fix_struct.eye_fixation.eye_fix_idx .* plt_ang;
plt_fix_ang_v = fix_struct.eye_fixation.eye_fix_idx .* plt_ang_v;

switch lower(fix_struct.pipeline_pars.fix_selection)
    case 'velocity'
        fix_flag = 1;
        plt_a = thres_ang_v;
        plt_av = thres_ang_v;
        plt_thres_ang = thres_ang_v*fix_struct.eye_fixation.eye_fix_idx;
        plt_thres_ang_v = thres_ang_v*fix_struct.eye_fixation.eye_fix_idx;
    case 'dispersion'
        fix_flag = 2;
        plt_a = thres_ang;
        plt_av = thres_ang;
        plt_thres_ang = thres_ang*fix_struct.eye_fixation.eye_fix_idx;
        plt_thres_ang_v = thres_ang*fix_struct.eye_fixation.eye_fix_idx;
    case 'strictvd'
        fix_flag = 3;
        plt_a = thres_ang;
        plt_av = thres_ang_v;
        plt_thres_ang = thres_ang*fix_struct.eye_fixation.eye_fix_idx;
        plt_thres_ang_v = thres_ang_v*fix_struct.eye_fixation.eye_fix_idx;
    case 'loosevd'
        fix_flag = 3;
        plt_a = thres_ang;
        plt_av = thres_ang_v;
        plt_thres_ang = thres_ang*fix_struct.eye_fixation.eye_fix_idx;
        plt_thres_ang_v = thres_ang_v*fix_struct.eye_fixation.eye_fix_idx;
end
plt_thres_ang(plt_thres_ang==0) = NaN;
plt_thres_ang_v(plt_thres_ang_v==0) = NaN;

% angle vs eye_open_idx
figure
plot(t_ruler, plt_ang, '-', 'DisplayName', 'Angle','Color',[0.5 0.5 1],'LineWidth',lw);
hold on
grid on
plot(t_ruler, plt_fix_ang, 'b-', 'DisplayName', 'Fix','LineWidth',lw);
if fix_flag ~=1
    plot(t_ruler, plt_thres_ang,'r-','DisplayName',sprintf('Threshold = %.2f deg',plt_a),'LineWidth',lw)
end
xlabel('Time (sec)')
ylabel('Deg')
ylim([0 10])
xlim([0 15])
legend('show')
set(gca,'fontsize',20)
title('Angle vs Time')

% angle vs eye_open_idx
figure
plot(t_ruler, plt_ang_v, '-', 'DisplayName', 'Angular speed','Color',[0.5 0.5 1],'LineWidth',lw);
hold on
grid on
plot(t_ruler, plt_fix_ang_v, 'b-', 'DisplayName', 'Fix','LineWidth',lw);
if fix_flag ~=2
    plot(t_ruler, plt_thres_ang_v,'r-','DisplayName',sprintf('Threshold = %.2f deg/sec',plt_av),'LineWidth',lw)
end
xlabel('Time (sec)')
ylabel('Deg/sec')
ylim([0 150])
xlim([0 15])
legend('show')
set(gca,'fontsize',20)
title('Angular speed vs Time')

end