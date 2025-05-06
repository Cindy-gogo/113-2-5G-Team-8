function ue_control_ui()
    global uePos ueDot ueLabel gnbList fs snr numRx ax gnbDots gnbLabels
    uePos = [100 100];
    fs = 15.36e6;
    snr = 20;
    numRx = 2;
    gnbList = gNodeB.empty;
    gnbList(1) = gNodeB(0,[20,100]);

    f = figure('KeyPressFcn', @onKeyPress, 'Name', 'UE 控制模擬', 'Position', [100 100 1200 600]);
    ax = axes(f, 'Units', 'pixels', 'Position', [50 50 800 500]);
    axis(ax, [0 200 0 200]); grid on; hold on;
    title(ax, '地圖 (WASD 或滑鼠控制 UE)');
    gnbDots = [];
    gnbLabels = [];

    % 畫初始 gNB
    for i = 1:length(gnbList)
        pos = gnbList(i).Position;
        gnbDots(i) = scatter(ax, pos(1), pos(2), 100, 'r', 'filled');
        gnbLabels(i) = text(ax, pos(1)+2, pos(2), sprintf('gNB%d', i-1));
    end

    % 畫 UE
    ueDot = scatter(ax, uePos(1), uePos(2), 100, 'b', 'filled');
    ueLabel = text(ax, uePos(1)+2, uePos(2), 'UE');

    % 控制面板
    uicontrol(f, 'Style', 'text', 'String', 'SNR (dB):', 'Position', [900 480 60 20]);
    snrVal = uicontrol(f, 'Style', 'text', 'String', num2str(snr), 'Position', [970 480 40 20]);
    uicontrol(f, 'Style', 'slider', 'Min', 0, 'Max', 30, 'Value', snr,...
        'Position', [900 460 200 20], 'Callback', @(s,~) updateSNR(s, snrVal));

    uicontrol(f, 'Style', 'text', 'String', 'MIMO:', 'Position', [900 420 60 20]);
    mimoVal = uicontrol(f, 'Style', 'text', 'String', num2str(numRx), 'Position', [970 420 40 20]);
    uicontrol(f, 'Style', 'popupmenu', 'String', {'1','2','4'},...
        'Position', [900 400 200 20], 'Callback', @(s,~) updateMIMO(s, mimoVal));

    uicontrol(f, 'Style', 'pushbutton', 'String', '新增 gNB', ...
        'Position', [900 280 100 30], 'Callback', @addGnb);
    uicontrol(f, 'Style', 'pushbutton', 'String', '刪除最後 gNB', ...
        'Position', [900 240 100 30], 'Callback', @delGnb);
    uicontrol(f, 'Style', 'pushbutton', 'String', '移動 UE', ...
        'Position', [900 200 100 30], 'Callback', @moveUe);

    % 初始化 viewer
    viewer_init();

    % 首次顯示
    ue = UE(0, uePos, numRx);
    [rx, ~] = ue.receive(gnbList, fs, snr);
    viewer_update(rx, gnbList, fs, uePos);
end

function updateSNR(slider, label)
    global snr
    snr = round(slider.Value);
    label.String = num2str(snr);
end

function updateMIMO(menu, label)
    global numRx
    val = menu.Value;
    opt = [1 2 4];
    numRx = opt(val);
    label.String = num2str(numRx);
end

function onKeyPress(~, event)
    global uePos ueDot ueLabel fs snr gnbList numRx
    step = 2;
    switch event.Key
        case 'w', uePos(2) = uePos(2)+step;
        case 's', uePos(2) = uePos(2)-step;
        case 'a', uePos(1) = uePos(1)-step;
        case 'd', uePos(1) = uePos(1)+step;
        otherwise, return
    end
    uePos = max(min(uePos,[200 200]), [0 0]);
    set(ueDot, 'XData', uePos(1), 'YData', uePos(2));
    set(ueLabel, 'Position', uePos + [2 0]);

    ue = UE(0, uePos, numRx);
    [rx, ~] = ue.receive(gnbList, fs, snr);
    viewer_update(rx, gnbList, fs, uePos);
end

function moveUe(~,~)
    global uePos ueDot ueLabel fs snr gnbList numRx
    p = ginput(1);
    uePos = max(min(p,[200 200]), [0 0]);
    set(ueDot, 'XData', uePos(1), 'YData', uePos(2));
    set(ueLabel, 'Position', uePos + [2 0]);

    ue = UE(0, uePos, numRx);
    [rx, ~] = ue.receive(gnbList, fs, snr);
    viewer_update(rx, gnbList, fs, uePos);
end

function addGnb(~,~)
    global gnbList ax gnbDots gnbLabels fs snr uePos numRx
    p = ginput(1);
    newId = length(gnbList);
    gnbList(end+1) = gNodeB(newId, p);
    gnbDots(end+1) = scatter(ax, p(1), p(2), 100, 'r', 'filled');
    gnbLabels(end+1) = text(ax, p(1)+2, p(2), sprintf('gNB%d', newId));

    ue = UE(0, uePos, numRx);
    [rx, ~] = ue.receive(gnbList, fs, snr);
    viewer_update(rx, gnbList, fs, uePos);
end

function delGnb(~,~)
    global gnbList gnbDots gnbLabels fs snr uePos numRx
    if length(gnbList) <= 1, return; end
    gnbList(end) = [];
    delete(gnbDots(end)); gnbDots(end) = [];
    delete(gnbLabels(end)); gnbLabels(end) = [];

    ue = UE(0, uePos, numRx);
    [rx, ~] = ue.receive(gnbList, fs, snr);
    viewer_update(rx, gnbList, fs, uePos);
end
