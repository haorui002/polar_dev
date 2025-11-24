clear;
%% 加载可靠度排序表。
addpath('Decoding_Index/')
addpath('GA/')
load('WQ_LIST_4096');
load('WQ_LIST_1024');
WQ_LIST = WQ_LIST_4096;
% WQ_LIST = WQ_LIST_4096;

%% 配置仿真基本信息：码长，码率，最大仿真循环次数，打印信息频率，信噪比范围。
n = 12;
N = 2^n;
K = N*1/2;
bp_max_iter = 20;
max_runs = 1e8;
resolution = 1e5;
ebno_vec = 1 : 0.5 : 6;

%% 信道仿真
num_block_err = zeros(length(ebno_vec), 8);
num_bit_err = zeros(length(ebno_vec), 8);
num_runs = zeros(length(ebno_vec), 8);

[M_up, M_down] = index_Matrix(N);

tic
for i_run = 1 : max_runs 
    if mod(i_run, ceil(max_runs/resolution)) == 1   %% 取1000个中第几次循环
        disp(['Sim iteration running = ', num2str(i_run)]);
        disp(['N = ' num2str(N) ' K = ' num2str(K) ' BP Max Iter Number = ' num2str(bp_max_iter)]);
        disp('  SNR    SSC BLER   SR_HR BLER     BP BLER   SR_Only_BLER  HR_Only_BLER  My_SR_BLER  My_HR_BLER');
        disp(num2str([ebno_vec' num_block_err./num_runs]));
    end

%% 生成源码序列 u
%  rng(7);
info = randi([0 1], K, 1);

%% 码字构造
[enc_out,info_bits,frozen_bits] = polarEncode(N, K, info, WQ_LIST);
    for i_ebno = 1 : length(ebno_vec) 

        num_runs(i_ebno, :) = num_runs(i_ebno, :) + 1;
         
%% 一次循环的一个信噪比，过信道
        llr = data_link(enc_out, ebno_vec(i_ebno), K/N);

%% 三种译码方法
        [info_esti_ssc] = SSC_Decoder_LLR(N, K, llr, WQ_LIST);
        [info_esti_sr_hr] = SR_HR_Decoder_LLR(N, K, llr, WQ_LIST);
%         [info_esti_bp, ~, ~, ~] = BP_Decoder_LLR(info_bits, frozen_bits, llr', bp_max_iter, M_up, M_down);
        [info_esti_sr_only] = SR_Only_Decoder(N, K, llr, WQ_LIST);
        [info_esti_hr_only] = HR_Only_Decoder(N, K, llr, WQ_LIST);
        [info_esti_my_sr] = My_SR_Decoder(N, K, llr, WQ_LIST);
        [info_esti_my_hr] = My_HR_Decoder(N, K, llr, WQ_LIST);
%% 计算误块率，误码率
        if any(info_esti_ssc ~= info)
            num_block_err(i_ebno,1) =  num_block_err(i_ebno,1) + 1;
            num_bit_err(i_ebno,1) = num_bit_err(i_ebno,1) + sum(info ~= info_esti_ssc);
        end
        if any(info_esti_sr_hr ~= info)
            num_block_err(i_ebno,2) =  num_block_err(i_ebno,2) + 1;
            num_bit_err(i_ebno,2) = num_bit_err(i_ebno,2) + sum(info ~= info_esti_sr_hr);
        end        
%         if any(info_esti_bp ~= info)
%             num_block_err(i_ebno,3) =  num_block_err(i_ebno,3) + 1;
%             num_bit_err(i_ebno,3) = num_bit_err(i_ebno,3) + sum(info ~= info_esti_bp);
%         end
        if any(info_esti_sr_only ~= info)
            num_block_err(i_ebno,4) =  num_block_err(i_ebno,4) + 1;
            num_bit_err(i_ebno,4) = num_bit_err(i_ebno,4) + sum(info ~= info_esti_sr_only);
        end
        if any(info_esti_hr_only ~= info)
            num_block_err(i_ebno,5) =  num_block_err(i_ebno,5) + 1;
            num_bit_err(i_ebno,5) = num_bit_err(i_ebno,5) + sum(info ~= info_esti_hr_only);
        end
        if any(info_esti_my_sr ~= info)
            num_block_err(i_ebno,6) =  num_block_err(i_ebno,6) + 1;
            num_bit_err(i_ebno,6) = num_bit_err(i_ebno,6) + sum(info ~= info_esti_my_sr);
        end
        if any(info_esti_my_hr ~= info)
            num_block_err(i_ebno,7) =  num_block_err(i_ebno,7) + 1;
            num_bit_err(i_ebno,7) = num_bit_err(i_ebno,7) + sum(info ~= info_esti_my_hr);
        end
    end
end
toc
[bler, ber] = Simulation(max_iter, max_err, max_runs, resolution, ebno_vec, N, K);




