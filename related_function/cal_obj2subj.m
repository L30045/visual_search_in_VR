function dist = cal_obj2subj(gip,head_loc,fix_idx)
%% calcuate distance between GIP and subject
gip_int = gip(:,fix_idx);
head_loc_int = head_loc(:,fix_idx);
dist = sqrt(sum((gip_int - head_loc_int).^2,1));

end