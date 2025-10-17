clc; clear; close all;
rng(9);

% parameter
              % R = 0 -> CR = 256/1024 = 1024/4096 =  1/4 | R = 1 -> CR = 384/1024 = 1536/4096 = 3/8
K = 1024;
N = 4096;
llr_bits = 5;        % LLR量化比特
SNR_range = 1;       % SNR范围（Eb/N0, dB）
num_frame = 1;    % 每个SNR点仿真帧数

save_interval = 1;  % 保存数据的帧间隔
save_data = 1;    % 控制是否保存数据
save_root = "./data";
if ~exist(save_root, 'dir')
    mkdir(save_root);
end

load('WQ_LIST_4096');

PER_record = zeros(size(SNR_range));

for idx = 1:length(SNR_range)
    SNR = SNR_range(idx);
    err_frame = 0;

    for frm = 1:num_frame
        %% 0. Create save directory for this SNR
%         save_dir = sprintf('%s/rng_%d_R_%d_K_%d_N_%d_llr_%d_SNR_%.1f', ...
%                               save_root, rng().Seed, R, K, N, llr_bits, SNR);
%         if save_data && ~exist(save_dir, 'dir')
%             mkdir(save_dir);
%         end

        %% 1. 随机比特生成
        enc_in = randi([0 1], K, 1);

        %% 2. 编码算法
        enc_out = polarEncode(N,K, enc_in, WQ_LIST_4096);

        %% 3. 数据链路：BPSK Modulation、AWGN Channel、BPSK Demodulation
        out_bits = data_link(enc_out, SNR, K/N);

        %% 4. 量化：8bit/5bit
%         dec_in = quantize(out_bits, llr_bits, 1);
        dec_in = out_bits;
        %% 5. 解码算法
        dec_out = polarDecoder(N,K, dec_in, WQ_LIST_4096);

        %% 6. 误帧率统计
        if any(enc_in ~= dec_out(:))
            err_frame = err_frame + 1;
        end

        %% 7. 定期保存数据
        if save_data && mod(frm, save_interval) == 0
            % Create filename prefix with frame number
            file_prefix = fullfile(save_dir, sprintf('frame_%d_', frm));
            
            % Save enc_in as binary bits (one bit per line)
            fid = fopen([file_prefix 'enc_in.txt'], 'w');
            fprintf(fid, '%d\n', enc_in);
            fclose(fid);
            
            % Save enc_out as binary bits (one bit per line)
            fid = fopen([file_prefix 'enc_out.txt'], 'w');
            fprintf(fid, '%d\n', enc_out);
            fclose(fid);
            
            % Save dec_in as signed hexadecimal (llr_bits width)
            % Convert to fixed-width hex with sign
            dec_in_hex = cellstr(dec2hex(dec_in, 2));
            fid = fopen([file_prefix 'dec_in.txt'], 'w');
            fprintf(fid, '%d\n', dec_in);
            fclose(fid);
            
            % Save dec_out as binary bits (one bit per line)
            fid = fopen([file_prefix 'dec_out.txt'], 'w');
            fprintf(fid, '%d\n', dec_out(:));
            fclose(fid);
        end
    end
    PER_record(idx) = err_frame / num_frame;
    fprintf('SNR=%.2f dB, PER=%.4f\n', SNR, PER_record(idx));
end


figure; semilogy(SNR_range, PER_record, 'o-'); grid on;
xlabel('SNR (dB)'); ylabel('PER');
title('Polar帧错误率曲线');

PER_target = [0.1, 0.001]; % 10%、0.1%
SNR_at_PER = zeros(size(PER_target));

for k = 1:length(PER_target)
    [~, idx] = min(abs(PER_record - PER_target(k)));
    SNR_at_PER(k) = SNR_range(idx);
    fprintf('PER=%.3f时SNR=%.2f dB\n', PER_target(k), SNR_at_PER(k));
end

delta_SNR = SNR_at_PER(2) - SNR_at_PER(1);
fprintf('\nSNR提升=%.2f dB（PER从10%%降到0.1%%时）\n', delta_SNR);

if delta_SNR <= 2.4
    fprintf('满足“提升不超过2.4dB”要求！\n');
else
    fprintf('不满足“提升不超过2.4dB”要求！\n');
end