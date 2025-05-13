function viewer_update(rx, gnbList, fsNow, truePos, predList, freqList)



    axesList = getappdata(0,'ue_axes');
    vf = getappdata(0,'ue_viewer_fig');
    if isempty(axesList) || isempty(vf) || ~ishandle(vf)
        viewer_init();
        axesList = getappdata(0,'ue_axes');
    end

  
    rxVec = rx(:).';
    axW = axesList{1};
    if ~ishandle(axW)
        axW = subplot(2,2,1,'Parent',vf);
        axesList{1} = axW;
    end
    cla(axW);
    plot(axW, real(rxVec));
    title(axW,'接收波形 - Real');
    grid(axW,'on');

 
    Ngnb = min(3,numel(gnbList));
    for g = 1:Ngnb
        idx = g+1;
        if numel(axesList)<idx || ~ishandle(axesList{idx})
            axesList{idx} = subplot(2,2,idx,'Parent',vf);
        end
        axC = axesList{idx};
        cla(axC);
        ref = reshape(gnbList(g).transmit(),1,[]);
        c = abs(xcorr(rxVec, ref, 300, 'none'));
        plot(axC, c);
        title(axC,sprintf('gNB%d xcorr',g-1));
        grid(axC,'on');
    end
    setappdata(0,'ue_axes',axesList);

    mapFig = getappdata(0,'ue_map_fig');
    if isempty(mapFig) || ~ishandle(mapFig)
        mapFig = figure('Name','UE Map','Position',[1400 100 400 400]);
        setappdata(0,'ue_map_fig',mapFig);
        setappdata(0,'ue_map_ax',axes('Parent',mapFig));
    end
    axM = getappdata(0,'ue_map_ax');
    cla(axM); hold(axM,'on'); grid(axM,'on');
    axis(axM,[0 200 0 200]);
    title(axM,'真實 vs. 預測 UE');


    for k = 1:numel(gnbList)
        p = gnbList(k).Position;
        plot(axM, p(1), p(2), 'ro', 'MarkerSize',8,'LineWidth',1.5);
        text(axM, p(1)+2, p(2), sprintf('gNB%d',k-1));
    end

    cols = {'b','g','m'};
    for i = 1:size(predList,1)
        pp = predList(i,:);
        plot(axM, pp(1), pp(2), [cols{i} 'x'], 'MarkerSize',10,'LineWidth',2);

     
        fprintf('Pred @ %.1f GHz = [%.3f , %.3f] m\\n', ...
                freqList(i)/1e9, pp(1), pp(2));
      
        fprintf('True  = [%.3f , %.3f] m\\n', truePos);
        fprintf('Pred @ %.1f GHz = [%.3f , %.3f] m\\n',freqList(i)/1e9,pp(1),pp(2));

        text(axM, pp(1)+2, pp(2), sprintf('%.1fGHz',freqList(i)/1e9));
    end

    plot(axM, truePos(1), truePos(2), 'kx', 'MarkerSize',10,'LineWidth',2);
    text(axM, truePos(1)+2, truePos(2), 'True UE');
    hold(axM,'off');
    
end
