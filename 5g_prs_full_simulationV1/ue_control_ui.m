function ue_control_ui()

    global uePos ueDot ueLabel gnbList fs snr numRx scs ...
           ax gnbDots gnbLabels freqList scsList

  
    uePos    = [100 100];            
    scs      = 15;                   
    scsList  = [15 30 60];            
    freqList = [2.5 3.5 4.0]*1e9;     
    fs       = scs_to_fs(scs);        
    snr      = 20;                    
    numRx    = 2;                    

 
    gnbList = gNodeB.empty;
    try
        gnbList(1) = gNodeB(0, [20 100], scs, freqList(2));
    catch
        warning('無法建立初始 gNB0');
    end

    % 創建主視窗與地圖軸
    f = figure('Name','UE 控制模擬','Position',[100 100 1200 600],...
               'KeyPressFcn',@onKeyPress);
    ax = axes(f,'Units','pixels','Position',[50 50 800 500]);
    axis(ax,[0 200 0 200]); grid(ax,'on'); hold(ax,'on');
    title(ax,'地圖 (點擊移動 UE)');
    set(ax,'ButtonDownFcn',@onMapClick);

    % 繪製 gNB
    gnbDots = []; gnbLabels = [];
    drawAllGnb();

    % 繪製 UE
    ueDot   = scatter(ax,uePos(1),uePos(2),100,'b','filled');
    ueLabel = text(ax,uePos(1)+2,uePos(2),'UE');

    % 建立控制面板
    buildPanel(f);

    % 初始化 Viewer 窗口
    viewer_init();

    % 首次更新
    refresh_rx();

    %% 建立控制面板
    function buildPanel(figH)
        % SNR 控制
        uicontrol(figH,'Style','text','String','SNR (dB):','Position',[900 480 60 20]);
        txt_snr = uicontrol(figH,'Style','text','String',num2str(snr),'Position',[970 480 40 20]);
        uicontrol(figH,'Style','slider','Min',0,'Max',30,'Value',snr,...
                  'Position',[900 460 200 20],'Callback',@(s,~)updSNR(s,txt_snr));
        % MIMO 控制
        uicontrol(figH,'Style','text','String','MIMO:','Position',[900 420 60 20]);
        txt_mimo = uicontrol(figH,'Style','text','String',num2str(numRx),'Position',[970 420 40 20]);
        optsMIMO = [1 2 4];
        uicontrol(figH,'Style','popupmenu','String',{'1','2','4'},'Value',find(optsMIMO==numRx),...
                  'Position',[900 400 200 20],'Callback',@(s,~)updMIMO(s,txt_mimo));
        % SCS 控制
        uicontrol(figH,'Style','text','String','SCS (kHz):','Position',[900 360 80 20]);
        txt_scs = uicontrol(figH,'Style','text','String',num2str(scs),'Position',[990 360 40 20]);
        uicontrol(figH,'Style','popupmenu','String',{'15','30','60'},'Value',find(scsList==scs),...
                  'Position',[900 340 200 20],'Callback',@(s,~)updSCS(s,txt_scs));
        % gNB 新增/刪除
        uicontrol(figH,'Style','pushbutton','String','新增 gNB','Position',[900 220 100 30],...
                  'Callback',@addGnb);
        uicontrol(figH,'Style','pushbutton','String','刪除 gNB','Position',[1010 220 100 30],...
                  'Callback',@delGnb);
    end

    %% SNR 更新
    function updSNR(src,txt)
        snr = round(src.Value);
        txt.String = num2str(snr);
        refresh_rx();
    end

    %% MIMO 更新
    function updMIMO(src,txt)
        opts = [1 2 4];
        numRx = opts(src.Value);
        txt.String = num2str(numRx);
        refresh_rx();
    end

    %% SCS 更新
    function updSCS(src,txt)
        scs = scsList(src.Value);
        txt.String = num2str(scs);
        fs = scs_to_fs(scs);
        refresh_rx();
    end

    %% 點擊地圖移動 UE
    function onMapClick(~,~)
        pt = get(ax,'CurrentPoint');
        newPos = pt(1,1:2);
        uePos = max(min(newPos,[200 200]),[0 0]);
        set(ueDot,'XData',uePos(1),'YData',uePos(2));
        set(ueLabel,'Position',uePos+[2 0]);
        refresh_rx();
    end

    %% 鍵盤控制 UE
    function onKeyPress(~,evt)
        step = 2;
        switch evt.Key
            case 'w', uePos(2)=uePos(2)+step;
            case 's', uePos(2)=uePos(2)-step;
            case 'a', uePos(1)=uePos(1)-step;
            case 'd', uePos(1)=uePos(1)+step;
            otherwise, return;
        end
        uePos = max(min(uePos,[200 200]),[0 0]);
        set(ueDot,'XData',uePos(1),'YData',uePos(2));
        set(ueLabel,'Position',uePos+[2 0]);
        refresh_rx();
    end

    %% 新增 gNB
    function addGnb(~,~)
        [x,y] = ginput(1);
        if isempty(x), return; end
        idx = numel(gnbList);
        gnbList(idx+1) = gNodeB(idx, [x y], scs, freqList(2));
        drawAllGnb();
        refresh_rx();
    end

    %% 刪除 gNB
    function delGnb(~,~)
        if numel(gnbList)<=1, return; end
        gnbList(end)=[];
        drawAllGnb();
        refresh_rx();
    end

    %% 繪製所有 gNB
    function drawAllGnb()
        delete(gnbDots); delete(gnbLabels);
        gnbDots=[]; gnbLabels=[];
        for i=1:numel(gnbList)
            pos = gnbList(i).Position;
            gnbDots(i)   = scatter(ax,pos(1),pos(2),100,'r','filled');
            gnbLabels(i) = text(ax,pos(1)+2,pos(2),sprintf('gNB%d',i-1));
        end
    end

    %% 刷新接收與定位
    function refresh_rx()
    if isempty(gnbList) || numel(gnbList)<3
        disp('★ 需至少 3 顆 gNB 才能定位！');
        return;
    end

    c0 = 3e8;                  % 光速
    M  = numel(freqList);      % 三個頻段
    predPos = zeros(M,2);      % 儲存三頻預測
    rxMid   = [];              % 用中頻繪波形

    for fi = 1:M
        % -- 對應頻段 / SCS 與取樣率 --
        scsNow = scsList(fi);
        fsNow  = scs_to_fs(scsNow);
        fNow   = freqList(fi);

        % -- 重建同頻 gNB 波形 --
        tmp(1) = gNodeB(0, gnbList(1).Position, scsNow, fNow);
        for k = 2:numel(gnbList)
            tmp(k) = gNodeB(gnbList(k).ID, gnbList(k).Position, scsNow, fNow);
        end

        % -- 以目前 UE 位置產生接收信號 --
        ue      = UE(0, uePos, numRx);        % ★ 每圈重建 UE 物件
        [rx,~]  = ue.receive(tmp, fsNow, snr);
        if fi == 2, rxMid = rx; end           % 中頻用來畫波形

        % -- 計算 TOA（含拋物線插值）→ 轉 TDOA --
        tau  = detectTOA(rx, tmp, fsNow);     % 絕對 TOA
        tdoa = tau - tau(1);                  % 以 gNB0 為參考 Δτ

        % -- TDOA 定位 --
        xs = arrayfun(@(g) g.Position(1), tmp);
        ys = arrayfun(@(g) g.Position(2), tmp);
        predPos(fi,:) = locateByTDOA(xs, ys, tdoa, c0);
    end

    % -- 更新視覺化 --
    viewer_update(rxMid, gnbList, fsNow, uePos, predPos, freqList);
end
end % ue_control_ui

%% 本地函數：scs_to_fs
function fs = scs_to_fs(kHz)
    switch kHz
        case 15, fs = 15.36e6;
        case 30, fs = 30.72e6;
        case 60, fs = 61.44e6;
        otherwise, error('不支援此 SCS');
    end
end
