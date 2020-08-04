function pipe_pars = cal_threshold(cali_ang_l,cali_ang_r,cali_v_ang_l,cali_v_ang_r,pipe_pars)
%% This function will add two fields to pipe_pars:
%   cali_thres_ang: angle threshold from calibration data.
%   cali_thres_ang_v: angular speed threshold from calibraiton data.

%% calculate threshold based on calibration data
disp('Calculate angle threshold from calibration data.')
% assume 95% of calibration data are fixation
cali_thres_ang_l = quantile(cali_ang_l(isnan(cali_ang_l)),0.95);
cali_thres_ang_r = quantile(cali_ang_r(isnan(cali_ang_r)),0.95);
cali_thres_ang_v_l = quantile(cali_v_ang_l(isnan(cali_v_ang_l)),0.95);
cali_thres_ang_v_r = quantile(cali_v_ang_r(isnan(cali_v_ang_r)),0.95);
cali_thres_ang = max(cali_thres_ang_l, cali_thres_ang_r);
cali_thres_ang_v = max(cali_thres_ang_v_l, cali_thres_ang_v_r);
pipe_pars.cali_thres_ang = cali_thres_ang;
pipe_pars.cali_thres_ang_v = cali_thres_ang_v;
fprintf('[Threshold setting]: Angle threshold from calibration data = %.2f deg.\n',cali_thres_ang/pi*180);
fprintf('[Threshold setting]: Angular speed threshold from calibration data = %.2f deg/sec.\n',cali_thres_ang_v/pi*180);
if pipe_pars.thres_ang ~= 0
    disp('Exam user input angle threshold.')
    cali_ang_fix_l = cali_ang_l/pi*180 < pipe_pars.thres_ang;
    cali_ang_fix_r = cali_ang_r/pi*180 < pipe_pars.thres_ang;
    thres_test = sum(cali_ang_fix_l & cali_ang_fix_r)/sum(~isnan(cali_ang_fix_l)|~isnan(cali_ang_fix_r));
    fprintf('%2d\% of calibration data are labeled as fixation with input angle threshold.\n',...
              thres_test);
    s_flag = input('Do you want to use calibraion-data driven threshold? [Y/N] (Default: N)','s');
    if isempty(s_flag)
        s_flag = 'N';
    end
    if strcmpi(s_flag,'Y')
        pipe_pars.thres_ang = cali_thres_ang;
    end
end
if pipe_pars.thres_ang_v ~= 0
    disp('Exam user input angular speed threshold.')
    cali_v_ang_fix_l = cali_v_ang_l/pi*180 < pipe_pars.thres_ang_v;
    cali_v_ang_fix_r = cali_v_ang_r/pi*180 < pipe_pars.thres_ang_v;
    thres_test = sum(cali_v_ang_fix_l & cali_v_ang_fix_r)/sum(~isnan(cali_v_ang_fix_l)|~isnan(cali_v_ang_fix_r));
    fprintf('[Threshold setting]: %2d\% of calibration data are labeled as fixation with input angular speed threshold.\n',...
              thres_test);
    s_flag = input('Do you want to use calibraion-data driven threshold? [Y/N] (Default: N)','s');
    if isempty(s_flag)
        s_flag = 'N';
    end
    if strcmpi(s_flag,'Y')
        pipe_pars.thres_ang_v = cali_thres_ang_v;
    end
end
disp('Done.')

end