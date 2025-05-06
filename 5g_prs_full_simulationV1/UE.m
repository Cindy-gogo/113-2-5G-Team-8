
classdef UE
    properties
        ID
        Position
        NumRx
    end

    methods
        function obj = UE(id, pos, numRx)
            obj.ID = id;
            obj.Position = pos;
            obj.NumRx = numRx;
        end

        function [rx, rx_each] = receive(obj, gnbList, fs, snr_db)
            c = 3e8;
            snr = 10^(snr_db/10);
            noisePower = 1 / snr;
            rx_each = [];
            for i = 1:length(gnbList)
                gnb = gnbList(i);
                d = norm(obj.Position - gnb.Position);
                delay_samples = round(d / c * fs);
                w = gnb.transmit();
                w = reshape(w, 1, []);
                w_delayed = [zeros(1, delay_samples), w];
                
                if length(w_delayed) < length(w)+300
                    w_delayed(end+1:length(w)+300) = 0;
                end
                rx_each(i,:) = w_delayed(1:length(w)+300);
            end
            rx = sum(rx_each, 1) + sqrt(noisePower)*randn(1, length(rx_each(1,:)));
        end
    end
end
