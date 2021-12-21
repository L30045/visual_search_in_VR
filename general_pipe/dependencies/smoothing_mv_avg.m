function mv_avg_eye_3D_pos = smoothing_mv_avg(eye_3D_pos, eye_open_idx, noise_reduction)

mv_avg_eye_3D_pos = eye_3D_pos;
mv_avg_eye_3D_pos(:,~eye_open_idx) = NaN;
mv_avg_win_len = floor(noise_reduction/2);
for m_i = mv_avg_win_len+1:size(eye_3D_pos,2)-mv_avg_win_len
    if ~isnan(mv_avg_eye_3D_pos(1,m_i+(-mv_avg_win_len:mv_avg_win_len)))
        % only reconstruct eye open sections
        mv_avg_eye_3D_pos(:,m_i) = mean(eye_3D_pos(:,m_i+(-mv_avg_win_len:mv_avg_win_len)),2);
    end
end

end