% ===================== File: gNodeB.m =====================
classdef gNodeB
    properties
        ID
        Position            % [x y]  (畫素座標)
        CenterFreq          % Hz
        SubcarrierSpacing   % kHz
        Waveform            % row‑vector
        Lwave               % 波形長度
    end
    methods
        function obj = gNodeB(id,pos,scs_kHz,fc)
            if nargin<3, scs_kHz = 15;  end
            if nargin<4, fc      = 3.5e9; end

            obj.ID               = id;
            obj.Position         = pos;
            obj.SubcarrierSpacing= scs_kHz;
            obj.CenterFreq       = fc;

            % --- 產生簡易 PRS 波形 (6 OFDM, 52 RB BPSK) ----------
            Nsc = 12*52;                    % 子載波數
            prsBits = randi([0 1],Nsc,1)*2-1;     % ±1
            ofdmSym = ifft(prsBits,Nsc);          % 一個 symbol
            tx = repmat(ofdmSym.',1,6);           % 6 symbols
            obj.Waveform = tx(:).';               % row
            obj.Lwave    = numel(obj.Waveform);
        end

        function w = transmit(obj)
            w = obj.Waveform;
        end
    end
end
