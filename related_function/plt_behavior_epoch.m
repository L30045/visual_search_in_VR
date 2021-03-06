function plt_behavior_epoch(epoch_lib, behavior_idx, shaded_method, varargin)
%% Plotting function for behavior matrice
lw = 3;
ms = 15;
t_ruler = (epoch_lib.sample_duration(1):epoch_lib.sample_duration(2)-1)/epoch_lib.srate;

% behavior to plot (1: head rotation, 2: fixation index, 3: GIP_HD angle,
% 4: GIP_HD angle 2D
switch behavior_idx
    case 1
        % ------------------
        % plot head rotation
        % ------------------
        plt_1 = squeeze(sqrt(sum(epoch_lib.rot_tar.^2,1)))/pi*180;
        plt_2 = squeeze(sqrt(sum(epoch_lib.rot_dis.^2,1)))/pi*180;
        tname = 'Head Rot.';
        yname = 'Angular Speed (degree/s)';
        p1_name = sprintf('Target (%d)',size(plt_1,2));
        p2_name = sprintf('Distractor (%d)',size(plt_2,2));
    case 2
        % ------------------
        % plot fixation index
        % ------------------
        plt_1 = epoch_lib.fi_tar;
        plt_2 = epoch_lib.fi_dis;
        tname = 'Fixation';
        yname = 'Fixation index';
        p1_name = sprintf('Target (%d)',size(plt_1,2));
        p2_name = sprintf('Distractor (%d)',size(plt_2,2));
    case 3
        % ------------------
        % plot angle between GIP vector and head direct
        % ------------------
        plt_1 = epoch_lib.ang_tar;
        plt_2 = epoch_lib.ang_dis;
        tname = 'Angle between GIP and Head Direct.';
        yname = 'Angule (degree)';
        p1_name = sprintf('Target (%d)',size(plt_1,2));
        p2_name = sprintf('Distractor (%d)',size(plt_2,2));
    case 4
        % ------------------
        % plot angle between GIP vector and head direct
        % ------------------
        plt_1 = epoch_lib.ang2d_tar;
        plt_2 = epoch_lib.ang2d_dis;
        tname = 'Angle between GIP and Head Direct.';
        yname = 'Angule (degree)';
        p1_name = sprintf('Target (%d)',size(plt_1,2));
        p2_name = sprintf('Distractor (%d)',size(plt_2,2));
    case 0
        % ------------------
        % compare 2 given epochs
        % ------------------
        if ~all([isa(varargin{1},'double'), isa(varargin{2},'double')])
            error('Invalid input format: Please provide 2 epochs for comparison.')
        end
        plt_1 = varargin{1};
        plt_2 = varargin{2};
        tname = varargin{3};
        yname = varargin{4};
        p1_name = varargin{5};
        p2_name = varargin{6};
end
    
figure
hold on
grid on
ftar = shadedErrorBar(t_ruler,plt_1',shaded_method,'lineprops','-b');
ftar.mainLine.LineWidth = lw;
ftar.mainLine.DisplayName = p1_name;
fdis = shadedErrorBar(t_ruler,plt_2',shaded_method,'lineprops','-r');
fdis.mainLine.LineWidth = lw;
fdis.mainLine.DisplayName = p2_name;
% plot([0 0],get(gca,'YLim'),'--k','linewidth', 3,'DisplayName','Onset');
plot([0 0],get(gca,'YLim'),'--k','linewidth', 3);
% [ax,h1,h2] = plotyy(t_ruler,zeros(size(t_ruler)),t_ruler,zeros(size(t_ruler)));
% set([h1,h2],'DisplayName','')
% set(ax,'fontsize',30);
% ax(1).YLim = [0 2];
% ax(1).YTick = 0:0.5:2;
% set(ax(1).YLabel,'String','Fixation Index');
% set(ax(1).YLabel,'Color','b');
% set(ax(1),'YColor','b');
% set(ax(2).YLabel,'String','Angular Speed (\pi/s)');
% set(ax(2).YLabel,'Color','r');
% set(ax(2),'YColor','r');
% set([h1,h2],'Visible','off')
% --------
% yline(cali_ang_mean, 'k-','linewidth',lw,'DisplayName','Mean');
% yline(cali_ang_mean+3*cali_ang_std, 'k--','linewidth',lw,'DisplayName','3 std');
% yline(cali_ang_mean-3*cali_ang_std, 'k--','linewidth',lw);
% --------
legend(flipud(findobj(gca,'-regexp','DisplayName', '[^'']')),'location','northwest')
xlabel('Time (s)')
% title('Distractor')
% set(gca,'xTick',round(t_ruler(1)):round(t_ruler(end)))
set(gca,'xTick',round(t_ruler(1)):0.1:round(t_ruler(end)))
ax = gca;
xName = repmat({''},1,length(ax.XTick));
tmp_i = arrayfun(@(x) num2str(x),round(t_ruler(1)):0.5:round(t_ruler(end)),'uniformoutput',0);
[xName{1:5:end}] = deal(tmp_i{:});
xlim([-1 1.7])
title(tname)
ylabel(yname)
set(gca,'xTickLabel',xName)
set(gca,'fontsize',30)
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]);
set(gcf,'color',[1 1 1])

end