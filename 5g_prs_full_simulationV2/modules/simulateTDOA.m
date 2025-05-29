function simulateTDOA(ax, gnb, steps, radius, thick_cm, scene, infoText, walls)
    global SimRunning;

    % 頻率組合（Hz）與對應顏色（合法 RGB）
    freqs = [700e6, 3.5e9, 28e9, 1.8e9, 2.6e9];
    colors = [
        0, 0, 1;        % blue
        1, 0.5, 0;      % orange
        1, 1, 0;        % yellow
        0.5, 0, 0.5;    % purple
        0, 1, 0         % green
    ];
    color_names = {'blue', 'orange', 'yellow', 'purple', 'green'};

    errs = zeros(length(freqs), 1);
    lost_cnt = zeros(length(freqs), 1);

    % UE 圓形軌跡
    theta = linspace(0, 2*pi, steps);
    pathX = radius * cos(theta);
    pathY = radius * sin(theta);

    % 畫出 UE 真實位置
    hUE = plot(ax, 0, 0, 'ko', 'MarkerSize', 8, 'MarkerFaceColor','k');
    hold(ax, 'on');
    legend(ax, 'Location', 'northeastoutside');

    for i = 1:steps
        if ~SimRunning, break; end
        xUE = pathX(i); yUE = pathY(i);
        hUE.XData = xUE; hUE.YData = yUE;

        % 計算真實距離 → TDOA
        dists = sqrt(sum((gnb - [xUE yUE]).^2, 2));
        refDist = dists(1);
        true_tdoa = (dists - refDist) / 3e8;

        for f = 1:length(freqs)
            tdoa = true_tdoa;
            freqGHz = freqs(f) / 1e9;

            % 穿牆延遲補償 + 頻率敏感雜訊
            for k = 1:3
                nCross = isPathBlocked([gnb(k,1), gnb(k,2)], [xUE, yUE], walls);
                delay_wall = nCross * (0.3e-9 * freqGHz + randn * 0.2e-9);
                tdoa(k) = tdoa(k) + delay_wall;
            end

            % 加入雜訊（高頻更敏感）
            noise_sigma = 2e-9 * (freqs(end) / freqs(f));
            tdoa = tdoa + randn(3,1) * noise_sigma;

            % 預測位置
            p_est = estimatePosition(gnb, tdoa);

            % 若估不準或跑掉太遠則記 lost
            if any(isnan(p_est)) || norm(p_est - [xUE; yUE]') > 50
                lost_cnt(f) = lost_cnt(f) + 1;
                errs(f) = errs(f) + 100; % 誤差上限加法
            else
                plot(ax, p_est(1), p_est(2), '.', ...
                    'Color', colors(f,:), ...
                    'MarkerSize', 10, ...
                    'DisplayName', sprintf('%.1fGHz', freqs(f)/1e9));
                errs(f) = errs(f) + norm(p_est - [xUE; yUE]');
            end
        end

        % 顯示累加誤差與 lost 次數
        msg = {};
        for j = 1:length(freqs)
            msg{end+1} = sprintf('%s - %.1f GHz Sum error: %.2f m, Lost: %d', ...
                color_names{j}, freqs(j)/1e9, errs(j), lost_cnt(j));
        end
        infoText.Value = msg;

        pause(0.01);
    end
end
