clear;
%% 加载可靠度排序表。
addpath('Decoding_Index/')
addpath('GA/')
load('WQ_LIST_4096');
load('WQ_LIST_1024');
WQ_LIST = WQ_LIST_1024;
% WQ_LIST = WQ_LIST_4096;

%% 配置仿真基本信息：码长，码率，最大仿真循环次数，打印信息频率，信噪比范围。
n = 10;
N = 2^n;
% k_list = [ 3/8 , 1/2 , 5/8 , 3/4];
d_list = 0.2 : 0.05 : 0.8;
k_list = [   1/4];
K_list = N*k_list;
bp_max_iter = 10;
max_runs = 10000;
resolution = 10;
ebno_vec = 1 : 0.2 : 3;

%% 信道仿真
num_block_err = zeros(length(ebno_vec), 8);
num_bit_err = zeros(length(ebno_vec), 8);
num_runs = zeros(length(ebno_vec), 8);

[M_up, M_down] = index_Matrix(N);

% 新增：定义译码方法名称（用于保存文件的标识）
decoder_names = {'BP', 'SSC', 'SR_HR', 'MY_SR_HR', 'SR_Only', 'My_SR', 'HR_Only', 'My_HR'};
% 新增：创建数据保存目录（避免文件散落）
if ~exist('sim_data_saved', 'dir')
    mkdir('sim_data_saved');
end

tic
for i = 1 : length(K_list)
    K = K_list(i);
    % 新增：为当前码率初始化临时统计数组（避免多码率数据叠加）
    temp_num_block_err = zeros(length(ebno_vec), 8);
    temp_num_bit_err = zeros(length(ebno_vec), 8);
    temp_num_runs = zeros(length(ebno_vec), 8);
    
    for i_run = 1 : max_runs 
        if mod(i_run, ceil(max_runs/resolution)) == 1   %% 取1000个中第几次循环
            disp(['Sim iteration running = ', num2str(i_run)]);
            disp(['N = ' num2str(N) ' K = ' num2str(K) '        BP Max Iter Number = ' num2str(bp_max_iter)]);
            disp('  SNR       BP          SSC       SR_HR      MY_SR_HR     SR_Only     My_SR      HR_Only      My_HR');
            disp(num2str([ebno_vec' temp_num_block_err./temp_num_runs]));  % 修改：显示当前码率的临时数据
        end
    
    %% 生成源码序列 u
    %  rng(7);
    info = randi([0 1], K, 1);
    
    %% 码字构造
    [enc_out,info_bits,frozen_bits] = polarEncode(N, K, info, WQ_LIST);
        for i_ebno = 1 : length(ebno_vec) 
    
            temp_num_runs(i_ebno, :) = temp_num_runs(i_ebno, :) + 1;  % 修改：更新临时统计数组
             
    %% 一次循环的一个信噪比，过信道
             llr = data_link(enc_out, ebno_vec(i_ebno), K/N);

    
    %% 八种译码方法

            [info_esti_bp] = SR_Only_Decoder(N, K, llr, WQ_LIST);
            [info_esti_ssc] = My_SR_Decoder(N, K, llr, WQ_LIST,0.1);
            [info_esti_sr_hr] = My_SR_Decoder(N, K, llr, WQ_LIST,0.2);
            [info_esti_my_sr_hr] = My_SR_Decoder(N, K, llr, WQ_LIST,0.3);
            [info_esti_sr_only] = My_SR_Decoder(N, K, llr, WQ_LIST,0.4);
            [info_esti_my_sr] = My_SR_Decoder(N, K, llr, WQ_LIST,0.5);
            [info_esti_hr_only] = My_SR_Decoder(N, K, llr, WQ_LIST,0.6);
            [info_esti_my_hr] = My_SR_Decoder(N, K, llr, WQ_LIST,0.7);

            
    %% 计算误块率，误码率        
            if any(info_esti_bp ~= info)
                temp_num_block_err(i_ebno,1) =  temp_num_block_err(i_ebno,1) + 1;  % 修改：更新临时统计数组
                temp_num_bit_err(i_ebno,1) = temp_num_bit_err(i_ebno,1) + sum(info ~= info_esti_bp);  % 修改：更新临时统计数组
            end
            if any(info_esti_ssc ~= info)
                temp_num_block_err(i_ebno,2) =  temp_num_block_err(i_ebno,2) + 1;  % 修改：更新临时统计数组
                temp_num_bit_err(i_ebno,2) = temp_num_bit_err(i_ebno,2) + sum(info ~= info_esti_ssc);  % 修改：更新临时统计数组
            end
            if any(info_esti_sr_hr ~= info)
                temp_num_block_err(i_ebno,3) =  temp_num_block_err(i_ebno,3) + 1;  % 修改：更新临时统计数组
                temp_num_bit_err(i_ebno,3) = temp_num_bit_err(i_ebno,3) + sum(info ~= info_esti_sr_hr);  % 修改：更新临时统计数组
            end        
            if any(info_esti_my_sr_hr ~= info)
                temp_num_block_err(i_ebno,4) =  temp_num_block_err(i_ebno,4) + 1;  % 修改：更新临时统计数组
                temp_num_bit_err(i_ebno,4) = temp_num_bit_err(i_ebno,4) + sum(info ~= info_esti_my_sr_hr);  % 修改：更新临时统计数组
            end 
            if any(info_esti_sr_only ~= info)
                temp_num_block_err(i_ebno,5) =  temp_num_block_err(i_ebno,5) + 1;  % 修改：更新临时统计数组
                temp_num_bit_err(i_ebno,5) = temp_num_bit_err(i_ebno,5) + sum(info ~= info_esti_sr_only);  % 修改：更新临时统计数组
            end        
            if any(info_esti_my_sr ~= info)
                temp_num_block_err(i_ebno,6) =  temp_num_block_err(i_ebno,6) + 1;  % 修改：更新临时统计数组
                temp_num_bit_err(i_ebno,6) = temp_num_bit_err(i_ebno,6) + sum(info ~= info_esti_my_sr);  % 修改：更新临时统计数组
            end
            if any(info_esti_hr_only ~= info)
                temp_num_block_err(i_ebno,7) =  temp_num_block_err(i_ebno,7) + 1;  % 修改：更新临时统计数组
                temp_num_bit_err(i_ebno,7) = temp_num_bit_err(i_ebno,7) + sum(info ~= info_esti_hr_only);  % 修改：更新临时统计数组
            end
            if any(info_esti_my_hr ~= info)
                temp_num_block_err(i_ebno,8) =  temp_num_block_err(i_ebno,8) + 1;  % 修改：更新临时统计数组
                temp_num_bit_err(i_ebno,8) = temp_num_bit_err(i_ebno,8) + sum(info ~= info_esti_my_hr);  % 修改：更新临时统计数组
            end
        end
    end
    
    %% 新增保存逻辑：当前码率完成max_runs次仿真后保存数据
    disp(['=== 码率 K/N = ' num2str(K/N) ' 仿真完成，开始保存数据 ===']);
    % 1. 组织数据结构
    sim_data.N = N;
    sim_data.K = K;
    sim_data.rate = K/N;
    sim_data.ebno_vec = ebno_vec;
    sim_data.decoder_names = decoder_names;
    sim_data.max_runs = max_runs;
    sim_data.num_block_err = temp_num_block_err;  % 保存当前码率的误块数
    sim_data.num_bit_err = temp_num_bit_err;      % 保存当前码率的误码数
    sim_data.num_runs = temp_num_runs;            % 保存当前码率的仿真次数
    sim_data.bler = temp_num_block_err ./ temp_num_runs;  % 计算误块率
    sim_data.ber = temp_num_bit_err ./ (temp_num_runs * K);  % 计算误码率
    sim_data.timestamp = datetime;  % 添加时间戳
    
    % 2. 生成唯一文件名（包含码长、码率、时间戳）
    g = gcd(K,N);
    timestamp_str = datestr(now, 'yyyy_mmdd_HHMM');
    filename = sprintf('sim_data_saved/result__N_%d__rate_%d_%d__runtimes_%d__%s.mat', ...
                      N, K/g,N/g, max_runs, timestamp_str);
    
    % 3. 保存数据
    save(filename, 'sim_data');
    disp(['数据已保存至：' filename]);
    disp(' ');  % 空行分隔，便于日志阅读
    
    % 4. 更新全局统计数组（保持原有代码的全局统计功能）
    num_block_err = num_block_err + temp_num_block_err;
    num_bit_err = num_bit_err + temp_num_bit_err;
    num_runs = num_runs + temp_num_runs;
end
toc

%% 新增：所有码率仿真完成后，保存全局统计数据
disp('=== 所有码率仿真完成，保存全局统计数据 ===');
global_sim_data.N = N;
global_sim_data.K_list = K_list;
global_sim_data.rate_list = k_list;
global_sim_data.ebno_vec = ebno_vec;
global_sim_data.decoder_names = decoder_names;
global_sim_data.total_max_runs = max_runs;
global_sim_data.global_num_block_err = num_block_err;
global_sim_data.global_num_bit_err = num_bit_err;
global_sim_data.global_num_runs = num_runs;
global_sim_data.global_bler = num_block_err ./ num_runs;

all_bits = K_list * repmat(max_runs,length(K_list),1);
K_expanded = repmat(all_bits, length(ebno_vec), 8); 


global_sim_data.global_ber = num_bit_err ./ K_expanded;
global_sim_data.timestamp = datetime;

global_filename = sprintf('sim_data_saved/global_result__N_%d__runtimes_%d__%s.mat', ...
                          N, max_runs, datestr(now, 'yyyymmdd_HHMM'));
save(global_filename, 'global_sim_data');
disp(['全局数据已保存至：' global_filename]);