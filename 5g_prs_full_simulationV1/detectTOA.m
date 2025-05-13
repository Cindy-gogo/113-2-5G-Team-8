% ===================== File: detectTOA.m =====================
function toa_list = detectTOA(rx, gnbList, fs)
% detectTOA   互相關 + 拋物線插值估算每顆 gNB 的到達時間 (s)
    rxVec = rx(:).';           
    N     = numel(gnbList);
    toa_list = zeros(1,N);
    maxLag   = 300;

    for i = 1:N
        ref = reshape(gnbList(i).transmit(),1,[]);
        c   = xcorr(rxVec, ref, maxLag, 'none');
        mag = abs(c);
        [~,pk] = max(mag);
        if pk>1 && pk<length(mag)
            y1 = mag(pk-1); y2 = mag(pk); y3 = mag(pk+1);
            delta = 0.5*(y1 - y3)/(y1 - 2*y2 + y3);
        else
            delta = 0;
        end
        toa_list(i) = (pk - length(ref) + delta)/fs;
    end
end
