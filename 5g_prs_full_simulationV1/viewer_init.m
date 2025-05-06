function viewer_init()
    fig = figure('Name','UE Viewer','Position',[100 100 1200 600]);
    setappdata(0, 'ue_viewer_fig', fig);

    ax1 = subplot(2,2,1); title('接收波形 Real Part'); grid on;
    ax2 = subplot(2,2,2); title('gNB0 解波 xcorr'); grid on;
    ax3 = subplot(2,2,3); title('gNB1 解波 xcorr'); grid on;
    ax4 = subplot(2,2,4); title('gNB2 解波 xcorr'); grid on;

    setappdata(0, 'ue_axes', {ax1, ax2, ax3, ax4});

    uicontrol('Style','text','Position',[950 550 200 30],'String','TOA (s):');
    uicontrol('Style','text','Position',[950 530 200 30],'Tag','toaText','String','-');
    uicontrol('Style','text','Position',[950 490 200 30],'String','定位估計:');
    uicontrol('Style','text','Position',[950 470 200 30],'Tag','posText','String','[?,?]');
end