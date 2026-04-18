function out_bits = data_link(enc_out, SNR, R)
    %% BPSK调制
    tx_sym = 1 - 2 * enc_out;

    %% 4. AWGN信道
    EsN0dB = SNR + 10*log10(R);
    noise_var = 1/(2*(10.^(EsN0dB/10)));
    noise = sqrt(noise_var)*randn(size(tx_sym));
    rx_sym = tx_sym + noise;

    %% BPSK 解调
    out_bits = 2*rx_sym/noise_var;
end