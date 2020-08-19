function fix_edges = find_edges(eye_fix_idx, srate)
    % find the duration for each fixation
    % Input:
    %   eye_fix_idx: binary fixation index
    %   srate: sampling rate
    % Output:
    %   fix_edges: N by 2 matrix. N is the number of total fixation. The
    %   first column is the index when fixations start and the second
    %   column is the index when fixations end.
    fix_edges = xor([eye_fix_idx, false], [false eye_fix_idx]);
    fix_edges = reshape(find(fix_edges),2,[])';
    fix_edges(:,2) = fix_edges(:,2)-1;
    fprintf('Mean fix length: %.0f ms\n', mean(diff(fix_edges'))/srate*1000);
    fprintf('Max fix length: %.0f ms\n', max(diff(fix_edges'))/srate*1000);
    fprintf('Min fix length: %.0f ms\n', min(diff(fix_edges'))/srate*1000);
end