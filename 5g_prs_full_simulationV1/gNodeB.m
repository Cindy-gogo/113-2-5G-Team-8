
classdef gNodeB
    properties
        ID
        Position
        Carrier
        PRSConfig
    end

    methods
        function obj = gNodeB(id, pos)
            obj.ID = id;
            obj.Position = pos;

            obj.Carrier = nrCarrierConfig;
            obj.Carrier.NSizeGrid = 52;
            obj.Carrier.SubcarrierSpacing = 15;

            prs = nrPRSConfig;
            prs.PRSResourceSetPeriod = [1 0];
            prs.NumRB = 52;
            prs.RBOffset = 0;
            prs.SymbolStart = 0;
            prs.NumPRSSymbols = 6;
            prs.NPRSID = id;

            obj.PRSConfig = prs;
        end

        function waveform = transmit(obj)
            grid = nrResourceGrid(obj.Carrier, 1);
            ind = nrPRSIndices(obj.Carrier, obj.PRSConfig);
            sym = nrPRS(obj.Carrier, obj.PRSConfig);
            grid(ind) = sym;
            waveform = nrOFDMModulate(obj.Carrier, grid);
        end
    end
end
