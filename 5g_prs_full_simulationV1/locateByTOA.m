% ===================== File: locateByTOA.m =====================
function estPos = locateByTOA(xs, ys, ranges, px2m)


    % 初始猜測：gNB 平均位置
    x0 = mean(xs); y0 = mean(ys);
    init = [x0 y0];

    % 殘差平方和
    fun = @(p) sum((sqrt((p(1)-xs).^2 + (p(2)-ys).^2)*px2m - ranges).^2);

    % 用 fminsearch 最小化
    est = fminsearch(fun, init);

    estPos = est;
end