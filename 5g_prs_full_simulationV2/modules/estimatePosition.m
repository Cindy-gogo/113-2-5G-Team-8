function pos = estimatePosition(gnb, tdoa)
    % 使用非線性最小平方擬合估計 UE 位置
    % gnb: 3x2 基站位置
    % tdoa: 3x1 相對於 gNB1 的 TDOA（秒）

    c = 3e8;              % 光速
    ref_pos = gnb(1,:);   % 參考 gNB
    tdoa = tdoa(:);       % 確保列向量

    % 目標函數：估計點 p = [x, y]
    loss_fn = @(p) ...
        ( ((norm(p - gnb(2,:)) - norm(p - ref_pos))/c - tdoa(2))^2 + ...
          ((norm(p - gnb(3,:)) - norm(p - ref_pos))/c - tdoa(3))^2 );

    % 初始猜測：三個 gNB 的幾何中心
    init = mean(gnb);
    options = optimset('Display','off');

    % 執行最佳化
    [pos, ~] = fminsearch(loss_fn, init, options);
    pos = pos(:);  % 回傳為 column vector
end
