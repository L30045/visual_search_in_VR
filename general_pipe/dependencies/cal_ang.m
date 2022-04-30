function [ang, v_ang] = cal_ang(mv_test_data,srate,velocity_smooth_win_len,varargin)
if isempty(varargin)
    ang_tolerance = 0.1;
else
    ang_tolerance = varargin{1};
end
ang = nan(1,size(mv_test_data,2));
v_ang = nan(1,size(mv_test_data,2));
vel_win_len = round(0.001*velocity_smooth_win_len*srate/2);

% if the input test data only have one channel, return it as angle
% directly.
if size(mv_test_data,1)==1
    ang = mv_test_data;
    v_ang = mv_test_data/(0.001*velocity_smooth_win_len);
else
    for v_i = vel_win_len+1:size(mv_test_data,2)-vel_win_len
        if ~isnan(mv_test_data(1,v_i+[-vel_win_len,vel_win_len]))
            nomi = double(mv_test_data(:,v_i-vel_win_len)'*mv_test_data(:,v_i+vel_win_len));
            denomi = double((norm(mv_test_data(:,v_i-vel_win_len))*norm(mv_test_data(:,v_i+vel_win_len))));
            tolerance = 1 - cos(pi/180*ang_tolerance); % adding tolerance (degree) when calculating acos
            % if the angle between two vectors are smaller than this tolerance,
            % return 0.
            if 1-nomi/denomi <= tolerance
                ang(v_i) = 0;
                v_ang(v_i) = 0;
            else
                ang(v_i) = acos(nomi/denomi)/pi*180; % (degree)
                v_ang(v_i) = ang(v_i)/(0.001*velocity_smooth_win_len); % (degree/sec)
            end
        end
    end
end

% check if angle are all real number
if ~isreal(ang)
    error('[Calculate angular velocity]: dot product of 2 eye gaze position (left) is greater than 1.')
end

end