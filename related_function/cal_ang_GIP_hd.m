function [ang_GIP_hd, ang_2d] = cal_ang_GIP_hd(data_struct)
%% calculate the angle between head-location-to-GIP vector and 
% head-direction vector. Both 3D angle and 2D angle (Bird view) are
% reported.
%% calculate the angle between  GIP vector and head direction
% create GIP vecotr
gip_vec = data_struct.ori_gip_3D_pos - data_struct.ori_head_3D_loc;
% normalized GIP vector
gip_vec = gip_vec./sqrt((sum(gip_vec.^2,1)));
% calculate the angle between GIP vector and head direction
ang_GIP_hd = acos(sum(gip_vec.*data_struct.ori_head_direct,1))/pi*180;
% 2D gip_vec
gip_vec_2d = data_struct.ori_gip_3D_pos([1,3],:) - data_struct.ori_head_3D_loc([1,3],:);
% gip_vec_2d = gip_vec_2d./sqrt(sum(gip_vec_2d.^2,1));
% norm head_direct
hd_2d = data_struct.ori_head_direct([1,3],:);
% hd_2d = hd_2d./sqrt(sum(hd_2d.^2,1));

numera = sum(gip_vec_2d.*hd_2d,1);
denomi = sqrt(sum(gip_vec_2d.^2,1)).*sqrt(sum(hd_2d.^2,1));
ang_2d = acos(numera./denomi)/pi*180;

end