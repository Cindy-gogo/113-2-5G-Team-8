function prs_gui()
    f = uifigure('Name','5G PRS TDOA Simulator','Position',[100 100 1400 820]);
    grid = uigridlayout(f, [4, 4]);
    grid.RowHeight = {40, 40, '1x', 100};
    grid.ColumnWidth = {220, 220, 220, '1x'};

    uilabel(grid, 'Text','步數'); steps = uieditfield(grid, 'numeric','Value',180);
    uilabel(grid, 'Text','半徑（m）'); radius = uieditfield(grid, 'numeric','Value',30);
    uilabel(grid, 'Text','牆厚（cm）'); wallthick = uieditfield(grid, 'numeric','Value',20);
    uilabel(grid, 'Text','場景'); scene = uidropdown(grid,'Items',{'空地','單牆','多房'},'Value','空地');
    btnStart = uibutton(grid,'Text','開始模擬'); 
    btnStop  = uibutton(grid,'Text','停止');
    btnReset = uibutton(grid,'Text','重設');

    ax = uiaxes(grid); ax.Layout.Row = [1 4]; ax.Layout.Column = 4;
    xlim(ax, [-60,60]); ylim(ax, [-60,60]); axis(ax,'equal'); hold(ax,'on');
    xlabel(ax,'X (m)'); ylabel(ax,'Y (m)'); title(ax, '模擬圖');

    gnb = 40 * [cosd(90), cosd(210), cosd(330); sind(90), sind(210), sind(330)]';
    gnb_plot = plot(ax, gnb(:,1), gnb(:,2), 'rs', 'MarkerSize', 10, 'Tag', 'GNB');

    infoText = uitextarea(grid, 'Editable','off');
    infoText.Layout.Row = 4; infoText.Layout.Column = [1 3];
    infoText.Value = {'準備開始模擬...'};

    isLocked = false;
    ax.ButtonDownFcn = @(src,event) moveGNB(ax, event, gnb_plot, isLocked);

    btnStart.ButtonPushedFcn = @(~,~) startSim();
    btnStop.ButtonPushedFcn  = @(~,~) stopSim();
    btnReset.ButtonPushedFcn = @(~,~) resetSim();

    simData = struct('running', false);

    function startSim()
        if simData.running, return; end
        global SimRunning;
        SimRunning = true;
        isLocked = true;
        steps.Enable = 'off';
        radius.Enable = 'off';
        wallthick.Enable = 'off';
        scene.Enable = 'off';

        hGNB = findall(ax, 'Type', 'Line', 'Tag', 'GNB');
        if isempty(hGNB)
            error('無法取得 GNB 位置');
        end
        gnb_now = [hGNB.XData(:), hGNB.YData(:)];

        cla(ax);
        walls = drawScene(ax, scene.Value, wallthick.Value);
        gnb_plot = plot(ax, gnb_now(:,1), gnb_now(:,2), 'rs', 'MarkerSize', 10, 'Tag', 'GNB');

        simData.running = true;
        simulateTDOA(ax, gnb_now, steps.Value, radius.Value, wallthick.Value, scene.Value, infoText, walls);
        simData.running = false;
        SimRunning = false;
    end

    function stopSim()
        global SimRunning;
        SimRunning = false;
        simData.running = false;
    end

    function resetSim()
        if simData.running, return; end
        global SimRunning;
        SimRunning = false;
        isLocked = false;
        steps.Enable = 'on';
        radius.Enable = 'on';
        wallthick.Enable = 'on';
        scene.Enable = 'on';
        steps.Value = 180;
        radius.Value = 30;
        wallthick.Value = 20;
        scene.Value = '空地';
        infoText.Value = {'準備開始模擬...'};
        cla(ax);
        gnb = 40 * [cosd(90), cosd(210), cosd(330); sind(90), sind(210), sind(330)]';
        gnb_plot = plot(ax, gnb(:,1), gnb(:,2), 'rs', 'MarkerSize', 10, 'Tag', 'GNB');
    end
end

function moveGNB(ax, event, h, locked)
    if locked, return; end
    if ~isvalid(h)
        disp("GNB plot 已被刪除，請重新初始化");
        return;
    end
    cp = event.IntersectionPoint(1:2);
    d = vecnorm(([h.XData(:), h.YData(:)] - cp).^2, 2, 2);
    [~, idx] = min(d);
    h.XData(idx) = cp(1);
    h.YData(idx) = cp(2);
end
