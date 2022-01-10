function [dispersion, speed] = cal_speed(mv_test_data,srate,velocity_smooth_win_len)

dispersion = nan(1,size(mv_test_data,2));
speed = nan(1,size(mv_test_data,2));
vel_win_len = round(0.001*velocity_smooth_win_len*srate/2);
for v_i = vel_win_len+1:size(mv_test_data,2)-vel_win_len
    if ~isnan(mv_test_data(1,v_i+[-vel_win_len,vel_win_len]))
        dispersion(v_i) = norm(mv_test_data(:,v_i+vel_win_len) - mv_test_data(:,v_i-vel_win_len)); % (unit distance)
        speed(v_i) = dispersion(v_i)/(0.001*velocity_smooth_win_len)/pi*180; % (unit distance/sec)
    end
end

end