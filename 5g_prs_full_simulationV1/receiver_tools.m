
function toa_list = detectTOA(rx, gnbList, fs)
    toa_list = zeros(1, length(gnbList));
    for i = 1:length(gnbList)
        ref = gnbList(i).transmit();
        corr = abs(xcorr(rx, ref));
        [~, idx] = max(corr);
        toa_samples = idx - length(ref);
        toa_list(i) = toa_samples / fs;
    end
end
