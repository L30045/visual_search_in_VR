function [ang_l, v_ang_l, ang_r, v_ang_r] = cal_ang(mv_avg_eye_3D_pos,srate,velocity_smooth_win_len)

e_pos_l = mv_avg_eye_3D_pos(1:3,:);
e_pos_r = mv_avg_eye_3D_pos(4:6,:);
ang_l = nan(1,size(mv_avg_eye_3D_pos,2));
v_ang_l = nan(1,size(mv_avg_eye_3D_pos,2));
ang_r = nan(1,size(mv_avg_eye_3D_pos,2));
v_ang_r = nan(1,size(mv_avg_eye_3D_pos,2));
vel_win_len = round(0.001*velocity_smooth_win_len*srate/2);
for v_i = vel_win_len+1:size(mv_avg_eye_3D_pos,2)-vel_win_len
    % left eye
    if ~isnan(e_pos_l(1,v_i+[-vel_win_len,vel_win_len]))
        ang_l(v_i) = acos(e_pos_l(:,v_i-vel_win_len)'*e_pos_l(:,v_i+vel_win_len));
        v_ang_l(v_i) = ang_l(v_i) / (0.001*velocity_smooth_win_len);
    end
    % right eye
    if ~isnan(e_pos_r(1,v_i+[-vel_win_len,vel_win_len]))
        ang_r(v_i) = acos(e_pos_r(:,v_i-vel_win_len)'*e_pos_r(:,v_i+vel_win_len));
        v_ang_r(v_i) = ang_r(v_i) / (0.001*velocity_smooth_win_len);
    end
end
% check if angle are all real number
if ~isreal(ang_l)
    error('[Calculate angular velocity]: dot product of 2 eye gaze position (left) is greater than 1.')
end
if ~isreal(ang_r)
    error('[Calculate angular velocity]: dot product of 2 eye gaze position (right) is greater than 1.')
end


end