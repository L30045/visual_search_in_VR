function [v_head_loc, dist_head]= cal_head_mv_speed(mv_avg_head_3D_loc,srate,velocity_smooth_win_len)

dist_head = nan(size(mv_avg_head_3D_loc));
v_head_loc = nan(size(mv_avg_head_3D_loc));
vel_win_len = round(0.001*velocity_smooth_win_len*srate/2);
for v_i = vel_win_len+1:size(mv_avg_head_3D_loc,2)-vel_win_len
    if ~isnan(mv_avg_head_3D_loc(1,v_i+[-vel_win_len,vel_win_len]))
        dist_head(:,v_i) = diff(mv_avg_head_3D_loc(:,v_i+[-vel_win_len,vel_win_len]),[],2);
        v_head_loc(:,v_i) = dist_head(:,v_i) / (0.001*velocity_smooth_win_len);
    end
end

end