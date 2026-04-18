function [info_esti, denoised_llr, error, iter_this_time] = SR_HR_Decoder_LLR(K,WQ_LIST_4096, enc_out,info_bits, frozen_bits, llr, max_iter, M_right_up, M_right_down)
N = length(frozen_bits);
n = log2(N);
R = zeros(N, n + 1);
L = zeros(N, n + 1);
internal_bits = zeros(N, n + 1);
%Initialize R
for i = 1:N
    if frozen_bits(i) == 1
        R(i, 1) = realmax;
    end
end

% [dec_out_SSC] = SSC_Decoder_LLR(N,K, llr', WQ_LIST_4096);
% dec_out_SSC_up = dec_out_SSC(1:N/2);

% 初始化结果序列
result_llr = llr;
    
    % 遍历序列中的每个元素
for i = 1:N/2
    if  mod((enc_out(i)+enc_out(i+N/2)),2) == 0
        result_llr(i+N/2) = llr(i) + llr(i+N/2);
    else
        result_llr(i+N/2) = -llr(i) + llr(i+N/2);
    end
end




%Initialize L
L(:, n + 1) = result_llr;
%Iter
for iter = 1 : max_iter
    %Left Prop
    for j = n : -1 : 1 %for each layer
        for i = 1 : N/2 %for each 2*2 module in each layer
            up_index = M_right_up(i, j);
            down_index = M_right_down(i, j);
            R_up_j = R(up_index, j);
            R_down_j = R(down_index, j);
            L_up_j_plus_1 = L(up_index, j + 1);
            L_down_j_plus_1 = L(down_index, j + 1);
            L(up_index, j) = 0.9375 * sign(R_down_j + L_down_j_plus_1) * sign(L_up_j_plus_1) * min(abs(R_down_j + L_down_j_plus_1), abs(L_up_j_plus_1));
            L(down_index, j) = 0.9375 * sign(R_up_j) * sign(L_up_j_plus_1) * min(abs(R_up_j), abs(L_up_j_plus_1)) + L_down_j_plus_1;
        end
    end
    u_esti = (L(:, 1) + R(:, 1)) < 0;
    internal_bits(:, 1) =  u_esti;
    %Right Prop
    for j = 1 : n
        for i = 1 : N/2
            up_index = M_right_up(i, j);
            down_index = M_right_down(i, j);
            R_up_j = R(up_index, j);
            R_down_j = R(down_index, j);
            L_up_j_plus_1 = L(up_index, j + 1);
            L_down_j_plus_1 = L(down_index, j + 1);
            R(up_index, j + 1) = 0.9375 * sign(R_down_j + L_down_j_plus_1) * sign(R_up_j) * min(abs(R_down_j + L_down_j_plus_1), abs(R_up_j));
            R(down_index, j + 1) = 0.9375 * sign(R_up_j) * sign(L_up_j_plus_1) * min(abs(R_up_j), abs(L_up_j_plus_1)) + R_down_j;
            internal_bits(up_index, j + 1) = mod(internal_bits(up_index, j) + internal_bits(down_index, j), 2);
            internal_bits(down_index, j + 1) = internal_bits(down_index, j);
        end
    end
    x_esti = (L(:, n + 1) + R(:, n + 1)) < 0;
    x_enc = internal_bits(:, n + 1);
    if all(x_esti == x_enc)
        info_esti = u_esti(info_bits);
        denoised_llr = L(:, n + 1) + R(:, n + 1);
        error = 0;
        iter_this_time = iter;
        break;
    else
        if iter == max_iter
            info_esti = u_esti(info_bits);
            denoised_llr = L(:, n + 1) + R(:, n + 1);
            error = 1;
            iter_this_time = iter;
        end
    end
end
end
% 
% function result_llr = sequence_operation(info, llr)
% 
%     % 初始化结果序列
%     result_llr = llr;
%     
%     % 遍历序列中的每个元素
%     for i = 1:N/2
%         if info(i) == 0
%             result_llr(i+N/2) = llr(i) + llr(i+N/2);
%         else
%             result_llr(i+N/2) = -llr(i) + llr(i+N/2);
%         end
%     end
% end












% [dec_out] = SSC_Decoder_LLR(N,K, dec_in, WQ_LIST)
%     
% %     if R == 0
% %         K = 1024;
% %         N = 4096;
% %     else
% %         K = 384;
% %     end
%     counter=0;
%     reliability_seq = WQ_LIST(WQ_LIST(:,2)<N,:);
%     fzn_indices = reliability_seq(1:end-K, 2) + 1;
% 
%     idx_fzn = zeros(1, N);
%     idx_fzn(fzn_indices) = 1;
%     idx = 1 : length(idx_fzn);
%     code_struct = zeros(length(idx_fzn), 3); % start, end, type
%     cnt_struct = 1;
%     [code_struct, ~] = identify_node(idx_fzn, idx, code_struct, cnt_struct);
%     code_struct = code_struct(code_struct ~= 0);
%     code_struct = reshape(code_struct', length(code_struct)/3, 3);
%     dec_out = decoder(dec_in, N, K, code_struct, idx_fzn);
% end
% 
% function [code_struct, cnt_struct] = identify_node(idx_fzn, idx, code_struct, cnt_struct)
%     N = length(idx_fzn);
% % 
% %     if N > 128
% %         [code_struct, cnt_struct] = identify_node(idx_fzn(1 : N/2), idx(1 : N/2) ,code_struct, cnt_struct);
% %         [code_struct, cnt_struct] = identify_node(idx_fzn(N/2 + 1 : end), idx(N/2 + 1 : end),code_struct, cnt_struct);
% %     else
%         if all(idx_fzn(1 : end - 1) == 1) && (idx_fzn(end) == 0)        % Rep节点
%             code_struct(cnt_struct, :) = [idx(1), N, 2];
%             cnt_struct = cnt_struct + 1;
%         elseif (idx_fzn(1) == 1) && all(idx_fzn(2 : end) == 0)          % SPC节点
%             code_struct(cnt_struct, :) = [idx(1), N, 3];
%             cnt_struct = cnt_struct + 1;
%         elseif all(idx_fzn == 0)                                        % Rate-1节点
%             code_struct(cnt_struct, :) = [idx(1), N, 1];
%             cnt_struct = cnt_struct + 1;
%         elseif all(idx_fzn == 1)                                        % Rate-0节点
%             code_struct(cnt_struct, :) = [idx(1), N, -1];
%             cnt_struct = cnt_struct + 1;
%         else
%             if N > 32
%                 [code_struct, cnt_struct] = identify_node(idx_fzn(1 : N/2), idx(1 : N/2) ,code_struct, cnt_struct);
%                 [code_struct, cnt_struct] = identify_node(idx_fzn(N/2 + 1 : end), idx(N/2 + 1 : end),code_struct, cnt_struct);
%             elseif all(idx_fzn(1 : 2) == 1) && all(idx_fzn(3 : end) == 0)  % type-III节点 且 4 <= N <= 32
%                 code_struct(cnt_struct, :) = [idx(1), N, 4];
%                 cnt_struct = cnt_struct + 1;
%             elseif N > 4
%                 [code_struct, cnt_struct] = identify_node(idx_fzn(1 : N/2), idx(1 : N/2) ,code_struct, cnt_struct);
%                 [code_struct, cnt_struct] = identify_node(idx_fzn(N/2 + 1 : end), idx(N/2 + 1 : end),code_struct, cnt_struct);
%             else                                                            % Normal 节点
%                 code_struct(cnt_struct, :) = [idx(1), N, 5];
%                 cnt_struct = cnt_struct + 1;
%             end
%         end
% %     end
% end
% 
% 
% function [dec_out_all] = decoder(llr_in, N, Kr, node_type_structure, idx_fzn)
%     %--------------------------------------------------------------------------
%     % 输入参数：
%     %         llr_in：               信道llr
%     %         node_type_structure：  节点类型矩阵
%     %         frozen_ind：           冻结比特索引
%     % 输出参数：
%     %         dec_out_all：          译码输出比特
%     
%     % %---------------------------- 识别节点类型----------------------------% %
%     T = size(node_type_structure, 1);                            % T代表总的节点个数
%     
%     P = zeros(N - 1, 1);                % LLR internal buffer, exclude input LLR, each column for 1 list
%     C = zeros(N - 1, 2);                % judgment of each stage, 2 columns for left & right node of 1 list, exclude root node
%     u = zeros(1, N);                    % infomation bits buffer, each row for 1 list
%     dec_out_all = zeros(Kr, 1);         % output all decoded bits, for debug
%     n = log2(N);
% 
%     % % ----------------------------节点类型参数----------------------------% %
%     % for start_bit_idx = 1 : N
%     for i_node = 1 : T                                     
%         start_bit_idx = node_type_structure(i_node, 1);          % 矩阵第一列代表起始比特的位置 
%         M = node_type_structure(i_node, 2);                      % 矩阵第二列代表子节点长度
%         type = node_type_structure(i_node, 3);                   % 矩阵第三列代表节点类型                             
%     
%         % % ------------------------------参数设置------------------------------% %
%         m = log2(M);                          
%         c_out_idx = M : 2 * M - 1;
%         % % -----------------------------生成矩阵G------------------------------% %
%         G = calGMatric(m); 
%         % % ----------------------------计算f和g函数----------------------------% %
%         dec_idx = start_bit_idx : start_bit_idx + M - 1;
%         c_idx = mod(dec_idx(2^m)/2^m, 2);
%         start_stage = start_stage_calc(start_bit_idx - 1, m, n);
%         p_sum_stage = p_sum_stage_calc(start_bit_idx - 1, m);
%         stage = start_stage;       
%         while(stage ~= m)
% 	        num_pe = 2^(stage - 1);						    % number of PEs for one stage
% 	        if(stage == n)
% 		        p_in_idx = [];							    % row index of P input
% 	        else
% 		        p_in_idx = 2^stage : 2^(stage + 1) - 1;     % row index of P input
% 	        end
%             %% 
% 	        p_out_idx = 2^(stage - 1): 2^stage - 1; 	    % row index of P output
% 	        c_in_idx = 2^(stage - 1): 2^stage - 1;		    % row index of C input
%     
%             if(stage == start_stage)
%                 if(start_bit_idx == 1)                  
% 			        P(p_out_idx, 1) = pe(0, num_pe, llr_in, []);                           % first step of bit 0, f-pe
%                 elseif(start_bit_idx == N/2 + 1)
% 			        P(p_out_idx, 1) = pe(1, num_pe, llr_in, C(c_in_idx, 1));      % first step of bit N/2, g-pe
%                 else
%                     % first step of other bits, g-pe, use lazy copy indicator of P buffer, use left node value of C buffer 
% 			        P(p_out_idx, 1) = pe(1, num_pe, P(p_in_idx, 1), C(c_in_idx, 1)); 
%                 end
%             else
% 		        P(p_out_idx, 1) = pe(0, num_pe, P(p_in_idx, 1), []);                  % left steps, f-pe
%             end
% 	        stage = stage - 1;
%          end
%         % % --------------------------按节点类型分别译码------------------------% %
%         switch type
%             case -1 % Rate-0
%                 for i = 1 : M        
%                     C(c_out_idx(i), 2 - c_idx) = 0;
%                 end
%                 u(1, dec_idx) = zeros(1, M);
%             case 1 % Rate-1 
%                 for i = 1 : M
%                     if P(p_out_idx(i), 1) >= 0
%                         C(c_out_idx(i), 2 - c_idx) = 0;
%                     else
%                         C(c_out_idx(i), 2 - c_idx) = 1;
%                     end
%                 end
%                 u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2);
%              case 2 % Rep
%                 sum_llr = 0;
%                     for i = 1 : M                        
%                         llrwidth = 8;
%                         frac = 1;
% %                         P_fix = quantize(P(p_out_idx(i), 1),llrwidth,frac);
%                         sum_llr = sum_llr + P(p_out_idx(i),1);
%                     end
%                         if sum_llr >= 0
%                             C(c_out_idx, 2 - c_idx) = zeros(M, 1);
%                             u(1, dec_idx) = zeros(1, M);
%                         else
%                             C(c_out_idx, 2 - c_idx) = ones(M, 1);
%                             u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2); 
%                         end
%             case 3 % SPC
%                 llr_code = zeros(M, 1);
%                 x = zeros(1, M);
%                 sum_x = 0;
%                 for i = 1 : M
%                     llr_code(i, 1) = P(p_out_idx(i), 1);               % 对每一个接收信号进行硬判决        
%                     if llr_code(i, 1) >= 0
%                         x(1, i) = 0;
%                     else
%                         x(1, i) = 1;
%                     end                                                % x为硬判决比特序列
%                     sum_x = sum_x + x(1, i);                           % 对硬判决比特序列求和
%                 end
%                 if mod(sum_x, 2) == 0                                  % 如果模二和为0
%                     C(c_out_idx, 2 - c_idx) = x;                       % 硬判决序列即输出比特
%                     u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2);
%                 else                        
%                      if mod(sum_x, 2) ~= 0                                 % 如果和不为0
%                         alpha_abs = abs(llr_code);
%                         [~, min_index] = min(alpha_abs);                  % 找到llr绝对值最小的比特位置
%                         x(min_index) = mod(x(min_index) + 1, 2);          % 对该比特进行翻转                     
%                         C(c_out_idx, 2 - c_idx) = x;
%                         u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2);
%                      end
%                 end
%             case 4 % type-III
%                 llr_code_1 = zeros(M/2, 1);
%                 llr_code_2 = zeros(M/2, 1);
%                 x_1 = zeros(1, M/2);
%                 x_2 = zeros(1, M/2);
%                 x = zeros(1, M);
%                 sum_x1 = 0;
%                 sum_x2 = 0;
%                 j = 1;
%                 for i = 1 : 2 : M - 1
%                     if j <= M/2
%                         llr_code_1(j, 1) = P(p_out_idx(i), 1);                       
%     
%                         if llr_code_1(j, 1) >= 0
%                             x_1(1, j) = 0;
%                         else
%                             x_1(1, j) = 1;
%                         end
%                         sum_x1 = sum_x1 + x_1(1, j);
%                         j = j + 1;
%                     end
%                 end
%                 if mod(sum_x1, 2) ~= 0
%                     alpha_abs = abs(llr_code_1);
%                     [~, min_index] = min(alpha_abs);
%                     x_1(min_index) = mod(x_1(min_index) + 1, 2);
%                 end
% 
%                 j = 1;
% 
%                 for i = 2 : 2 : M
%                     if j <= M/2
%                         llr_code_2(j, 1) = P(p_out_idx(i), 1);
% 
%                         if llr_code_2(j, 1) >= 0
%                             x_2(1, j) = 0;
%                         else
%                             x_2(1, j) = 1;
%                         end
%                         sum_x2 = sum_x2 + x_2(1, j);
%                         j = j + 1;
%                     end
%                 
%                 end
%                     if mod(sum_x2, 2) ~= 0
%                         alpha_abs = abs(llr_code_2);
%                         [~, min_index] = min(alpha_abs);
%                         x_2(min_index) = mod(x_2(min_index) + 1, 2);
%                     end
%                 
%                 for x_idx = 1 : M/2
%                     x(2 * x_idx - 1) = x_1(x_idx);
%                     x(2 * x_idx) = x_2(x_idx);
%                 end
% 
%                 C(c_out_idx, 2 - c_idx) = x;                       
%                 u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2); 
%             case 5 % Normal
%                 for i = 1 : M        
%                     C(c_out_idx(i), 2 - c_idx) = 0;
%                 end
%                 u(1, dec_idx) = zeros(1, M);
%         end
%                     
%         % % -------------------------------求部分和-----------------------------% %
%         if((c_idx == 0)&&(dec_idx(end) ~= N))                       % calculate partial-sum at right child node
%             u_stage = p_sum_stage;
%             stage = m;
%             while(u_stage ~= 0)
%                 phi = (u_stage == 1);                               % left or right indicator of column, left for last step, right for other steps
%                 p_sum_in_idx = 2^stage : 2^(stage + 1) - 1;         % row index of partial-sum input
%                 p_sum_out_idx = 2^(stage + 1) : 2^(stage + 2) - 1;  % row index of partial-sum output
%                 for i = 1 : 2^stage
%                     C(p_sum_out_idx(i), 2 - phi) = mod(C(p_sum_in_idx(i), 1) + C(p_sum_in_idx(i), 2), 2);
%                     C(p_sum_out_idx(i + 2^stage), 2 - phi) = C(p_sum_in_idx(i), 2);
%                 end
%                 stage = stage + 1;
%                 u_stage = u_stage - 1;
%             end  
%         end
%     end
% 
%     % % ---------------------------提取信息比特-----------------------------% %
%         cnt = 1;
%         for i = 1 : N
%             if(idx_fzn(i) == 0)
%                 dec_out_all(cnt, 1) = u(1, i); 
%                 cnt = cnt + 1;
%             end
%         end
% end
% 
% function [start_stage] = start_stage_calc(index, m, n)
%     if index == 0
%         start_stage = n;
%     else
%         batch_id = floor(index / 2^m); % 当前batch编号
%         stage = 0;
%         % 统计最低位连续0个数
%         while bitand(batch_id, 1) == 0 && batch_id ~= 0
%             batch_id = bitshift(batch_id, -1); % 右移一位
%             stage = stage + 1;
%         end
%         start_stage = stage + 1 + m;
%     end
% end
% 
% function [p_sum_stage] = p_sum_stage_calc(index, m)
%     index_tmp = floor(index / 2^m);
%     p_sum_stage = 0;
%     
%     while bitand(index_tmp, 1) % 等价于 mod(index_tmp,2)==1
%         index_tmp = bitshift(index_tmp, -1); % 右移1位
%         p_sum_stage = p_sum_stage + 1;
%     end
% 
% end
% 	
% function [llr_out] = pe(f_g, num, llr_in, bit_in)
%     width_llr = 10;
%     frac_llr = 2;
%     
%     % 预分块
%     llr_in = llr_in(:);
%     a = llr_in(1:num);
%     b = llr_in(num+1:end);
%     
%     if f_g == 0
%         % f-PE: min-sum近似
%         llr_out = 0.9375 * sign(a) .* sign(b) .* min(abs(a), abs(b));
%     else
%         % g-PE: 结合译码比特
%         u = bit_in(:); % 保证列向量
%         llr_out = (1 - 2 * u) .* a + b;
%         % 定点量化
%         %llr_out = arrayfun(@(x) quantize(x, width_llr, frac_llr), llr_out); % -512 ~ 511
%     end
% end





