function fs=scs_to_fs(kHz)
    switch kHz
        case 15, fs=15.36e6;
        case 30, fs=30.72e6;
        case 60, fs=61.44e6;
        otherwise, error('Unsupported SCS');
    end
end
