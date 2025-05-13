% ===================== File: locateByTDOA.m =====================
function pos = locateByTDOA(xs,ys,tdoa,c)
% NLS 解 2‑D TDOA 位置，不需 UE 時鐘同步
% --------------------------------------------------------------
% xs,ys : gNB 座標 (m)     [N×1]，N ≥ 3
% tdoa  : Δτ = τ_i − τ_0 (s) [N×1]，必令第 1 個元素 = 0
% c     : 光速 (m/s)
% 回傳  : pos = [x y] (m)

    if numel(xs) < 3
        error('locateByTDOA 需要至少 3 顆 gNB');
    end
    if abs(tdoa(1)) > 1e-12
        error('tdoa(1) 必須為 0 (以 gNB0 為參考)');
    end

    x = xs(:);  y = ys(:);  dT = tdoa(:);

    % ---- 非線性最小平方 (fminsearch) ----
    fun = @(p) sum( ( sqrt((p(1)-x).^2 + (p(2)-y).^2) ...
                   - c*(dT + p(3)) ).^2 );     % p = [x y b]，b=時鐘偏差
    p0  = [mean(x)+1 , mean(y)+1 , 0];         % 起點避免落在奇異點
    p   = fminsearch(fun, p0, optimset('Display','off'));

    pos = p(1:2);                              % 只回傳 [x y]
end
