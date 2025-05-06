function viewer_update(rx, gnbList, fs, truePos)
    if isempty(getappdata(0, 'ue_axes'))
        return;
    end
    axesList = getappdata(0, 'ue_axes');
    ax1 = axesList{1}; ax2 = axesList{2}; ax3 = axesList{3}; ax4 = axesList{4};

    axes(ax1); cla(ax1); plot(ax1, real(rx)); title(ax1, '接收波形 Real Part');

    toa = zeros(1,length(gnbList));
    for i = 1:length(gnbList)
        ref = reshape(gnbList(i).transmit(), 1, []);
        ref = [ref zeros(1,300)];

        c = abs(xcorr(rx, ref));
        [~, peakIdx] = max(c);
        if peakIdx > 1 && peakIdx < length(c)
            y1 = c(peakIdx - 1);
            y2 = c(peakIdx);
            y3 = c(peakIdx + 1);
            d = 0.5 * (y1 - y3) / (y1 - 2*y2 + y3);
        else
            d = 0;
        end
        toa(i) = (peakIdx + d - length(ref)) / fs;
        if i+1 <= length(axesList)
            axes(axesList{i+1}); cla(axesList{i+1}); plot(axesList{i+1}, c); title(axesList{i+1}, sprintf('gNB%d 解波 xcorr', i-1));
        end
    end

    h_toa = findobj('Tag','toaText');
    if ishandle(h_toa)
        h_toa.String = join(string(round(toa,6)), ', ');
    end

    c = 3e8;
    estD = toa * c;
    px_to_meter = 1;  % 假設畫面單位就是公尺
    xs = arrayfun(@(g) g.Position(1), gnbList) * px_to_meter;
    ys = arrayfun(@(g) g.Position(2), gnbList) * px_to_meter;

    estPos = [0, 0];
    if length(gnbList) >= 3
        initPos = [mean(xs), mean(ys)];
        estFun = @(p) sum((sqrt((p(1) - xs).^2 + (p(2) - ys).^2) - estD).^2);
        estPos = fminsearch(estFun, initPos);
    end

    h_pos = findobj('Tag','posText');
    if ishandle(h_pos)
        h_pos.String = sprintf('[%.2f, %.2f]', estPos(1), estPos(2));
    end

    if isempty(getappdata(0, 'ue_map_fig')) || ~ishandle(getappdata(0, 'ue_map_fig'))
        fig2 = figure('Name','UE Map','Position',[1400 100 400 400]);
        setappdata(0, 'ue_map_fig', fig2);
        setappdata(0, 'ue_map_ax', axes('Parent', fig2));
    end
    axMap = getappdata(0, 'ue_map_ax');
    axes(axMap);
    cla(axMap);
    hold(axMap, 'on');
    axis(axMap, [0 200 0 200]);
    title(axMap, '預測位置圖');

    for i = 1:length(gnbList)
        plot(axMap, gnbList(i).Position(1), gnbList(i).Position(2), 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
        text(gnbList(i).Position(1)+2, gnbList(i).Position(2), sprintf('gNB%d', i-1), 'Parent', axMap);
    end

    plot(axMap, estPos(1), estPos(2), 'bx', 'MarkerSize', 10, 'LineWidth', 2);
    text(estPos(1)+2, estPos(2), '預測 UE', 'Parent', axMap);

    if ~isempty(truePos)
        plot(axMap, truePos(1), truePos(2), 'g+', 'MarkerSize', 10, 'LineWidth', 2);
        text(truePos(1)+2, truePos(2), '實際 UE', 'Parent', axMap);
        err = norm(truePos * px_to_meter - estPos);
        text(10, 190, sprintf('誤差: %.2f m', err), 'Parent', axMap, 'FontSize', 10, 'FontWeight', 'bold');
    end

    hold(axMap, 'off');
end
