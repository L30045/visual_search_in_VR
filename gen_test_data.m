%% generate test data and calibration data
srate = 90; % Hz
data_length = 60; % sec
cali_data = zeros(3,data_length*srate);

%% calibration data
t_ruler = 0:1/srate:data_length-1/srate;
thres_fix_ang = 1; % deg
thres_fix_vang = 30; % deg/sec
cali_data(3,:) = 1;
% cali_data(3,:) = cos(thres_fix_ang/180*pi);
% cali_data(1,:) = cos(thres_fix_vang/180*pi*t_ruler);
% cali_data(2,:) = sin(thres_fix_vang/180*pi*t_ruler);
cali_data = cali_data./sqrt(sum(cali_data.^2,1));
test_data = cali_data;
% insert blink
blink_length = 0.5; % sec
blink_amp = 10;
blink = blink_amp*sin(2*pi*[0:1/srate:blink_length-1/srate]);
blink_time = 30:40;
for i = blink_time
    test_data(1,i*srate:(i+0.5)*srate-1) = blink;
%     test_data(2,i*srate:(i+0.5)*srate-1) = blink;
end
    
save('test_data_gen.mat','test_data','cali_data','srate');