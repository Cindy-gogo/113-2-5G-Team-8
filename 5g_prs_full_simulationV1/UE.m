% ===================== File: UE.m =====================
classdef UE
    properties
        ID          % UE 编号
        Position    % UE 位置 [x y]
        NumRx       % 接收天线数
    end

    methods
        function obj = UE(id, pos, numRx)
            if nargin < 3
                numRx = 1;
            end
            obj.ID       = id;
            obj.Position = pos;
            obj.NumRx    = numRx;
        end

        function [rxSum, rxMat] = receive(obj, gnbList, fs, snr_dB)
     
            c0     = 3e8;
            numG   = numel(gnbList);
            maxLen = max([gnbList.Lwave]) + 300;
     
            rxMat = zeros(numG, maxLen, obj.NumRx);

            for g = 1:numG
          
                d    = norm(obj.Position - gnbList(g).Position);
                fc   = gnbList(g).CenterFreq;
                PLdB = 32.4 + 21*log10(d) + 20*log10(fc/1e9);
                gain = 10^(-PLdB/20);  

                tdl = nrTDLChannel;
                tdl.DelayProfile       = "TDL-C";
                tdl.DelaySpread        = 30e-9;
                tdl.SampleRate         = fs;
                tdl.NormalizePathGains = false;
                if isprop(tdl,'CarrierFrequency')
                    tdl.CarrierFrequency = fc;
                end

   
                tx = gnbList(g).Waveform(:);  
                y  = tdl(tx);

           
                y = gain * y;

                
                delaySamples = round(d/c0*fs);
         
                y = [zeros(delaySamples,1); y(:)];
                if numel(y) < maxLen
                    y(end+1:maxLen,1) = 0;
                else
                    y = y(1:maxLen);
                end

             
                for r = 1:obj.NumRx
                    rxMat(g, :, r) = y;
                end
            end

           
            sigP   = mean(abs(rxMat(:)).^2);
            noiseP = sigP / 10^(snr_dB/10);
            rxMat  = rxMat + sqrt(noiseP/2) * (randn(size(rxMat)) + 1i*randn(size(rxMat)));

          
            rxSum = squeeze(sum(rxMat, 1)); 
            if obj.NumRx == 1
                rxSum = rxSum.';             
            end
        end
    end
end
