function [dec_out] = SR_Only_Decoder(N,K, dec_in, WQ_LIST)

    

    counter=0;
    reliability_seq = WQ_LIST(WQ_LIST(:,2)<N,:);
    fzn_indices = reliability_seq(1:end-K, 2) + 1;
    source_len = 4;
    idx_fzn = zeros(1, N);
    idx_fzn(fzn_indices) = 1;
    idx = 1 : length(idx_fzn);
    code_struct = zeros(length(idx_fzn), 4); % start, end, type
    SR_struct = {};
    cnt_struct = 1;
    [SR_struct, code_struct, ~] = identify_node(~idx_fzn, idx, code_struct, cnt_struct,SR_struct, source_len);
    code_struct = code_struct(code_struct ~= 0);
    code_struct = reshape(code_struct', length(code_struct)/4, 4);
    SR_struct = SR_struct';
    dec_out = decoder(dec_in, N, K, code_struct, idx_fzn,SR_struct,source_len);
end

function [SR_struct,  code_struct, cnt_struct] = identify_node(idx_fzn, idx, code_struct, cnt_struct,SR_struct, source_len)
    N = length(idx_fzn);
        if (idx_fzn(1) == 0) && all(idx_fzn(2 : end) == 1)          % SPC节点
            code_struct(cnt_struct, :) = [idx(1), N, 3,7];
            cnt_struct = cnt_struct + 1;
        elseif all(idx_fzn == 1)                                        % Rate-1节点
            code_struct(cnt_struct, :) = [idx(1), N, 1,7];
            cnt_struct = cnt_struct + 1;
        elseif all(idx_fzn(1 : 2) == 0) && all(idx_fzn(3 : end) == 1)  % type-III节点  
            code_struct(cnt_struct, :) = [idx(1), N, 4,7];
            cnt_struct = cnt_struct + 1;
        elseif is_segment_SR(idx_fzn,source_len)                            %SR节点
            [~,SR_struct{cnt_struct},type_source] = is_segment_SR(idx_fzn,source_len);
            code_struct(cnt_struct, :) = [idx(1), N, -1,type_source];
            cnt_struct = cnt_struct + 1;
        elseif N > source_len
            [SR_struct, code_struct, cnt_struct] = identify_node(idx_fzn(1 : N/2), idx(1 : N/2) ,code_struct, cnt_struct,SR_struct, source_len);
            [SR_struct, code_struct, cnt_struct] = identify_node(idx_fzn(N/2 + 1 : end), idx(N/2 + 1 : end),code_struct, cnt_struct,SR_struct, source_len);
        else                                                           
            code_struct(cnt_struct, :) = [idx(1), N, 5,7];
            cnt_struct = cnt_struct + 1;
        end
end
    

function [result,SR_struct_r,type_source] = is_segment_SR(sequence,source_len)

n = length(sequence);
segment_start_SR = 1;
segment_number_SR = 1;

% 存储所有分段信息
all_segments_SR = {};

% 分段模式的分母序列：2,4,8,16...
denominator = 2;

while true
    % 计算当前分段结束位置
    segment_end_SR = floor(n * (1 - 1/denominator));
    
    % 确保分段长度至少为4
    if (segment_end_SR - segment_start_SR + 1) < source_len
        all_segments_SR{end+1} = struct('number',segment_number_SR,'start',segment_start_SR,'end',segment_end_SR,'content',sequence(segment_start_SR:segment_start_SR+source_len-1));
        break;
    end
    
    % 提取当前分段
    current_segment_SR = sequence(segment_start_SR:segment_end_SR);
    
    % 存储分段信息
    segment_info_SR = struct();
    segment_info_SR.number = segment_number_SR;
    segment_info_SR.start = segment_start_SR;
    segment_info_SR.end = segment_end_SR;
    segment_info_SR.content = current_segment_SR;
    all_segments_SR{end+1} = segment_info_SR;
    
%     % 显示分段信息
%     fprintf('分段%d: 位置[%d-%d], 长度=%d\n', ...
%         segment_number_SR, segment_start_SR, segment_end_SR, length(current_segment_SR));
%     fprintf('  内容: %s\n', mat2str(current_segment_SR));
%     fprintf('  范围: 前%.3f到前%.3f\n\n', ...
%         1 - (segment_start_SR-1)/n, 1 - segment_end_SR/n);
    
    % 更新下一个分段的起始位置
    segment_start_SR = segment_end_SR + 1;
    segment_number_SR = segment_number_SR + 1;
    denominator = denominator * 2;
    
    % 检查是否到达序列末尾
    if segment_start_SR > n
        break;
    end
end

[result,SR_struct_r,type_source] = check_all_segments_SR(all_segments_SR);

end

function [result,SR_struct_r,type_source] = check_all_segments_SR(all_segments_SR)
    % 检查除最后一个分段外的所有分段是否全为0或全为1
    SR_struct_r = [];
    type_source = 0 ;
    if isempty(all_segments_SR)
%         fprintf('没有可检查的分段\n');
        result = 0;
        return;
    end
    
%     fprintf('\n=== 开始分段检查 ===\n');
    
    % 检查除最后一个分段外的所有分段
    for i = 1:length(all_segments_SR)-1
        segment = all_segments_SR{i};
        current_segment_SR = segment.content;
        
        % 检查是否全为0或全为1
        boool = all(~current_segment_SR) || ((current_segment_SR(end) == 1) && all(current_segment_SR(1:end-1) == 0));
%         fprintf('检查分段%d [%d-%d]: ', ...
%             segment.number, segment.start, segment.end);
        
        if ~boool
            result = 0;
            SR_struct_r = zeros;
            return;
        else
            if all(~current_segment_SR)
                SR_struct_r = [SR_struct_r,0];
            else
                SR_struct_r = [SR_struct_r,1];
            end
        end
    end
    
    % 最后一个分段检查
    if length(all_segments_SR) > 0
        last_segment = all_segments_SR{end}.content;
         if all(last_segment(1 : end - 1) == 0) && (last_segment(end) == 1)        % Rep节点
            type_source = 2;
        elseif (last_segment(1) == 0) && all(last_segment(2 : end) == 1)          % SPC节点
            type_source = 3;
        elseif all(last_segment == 1)                                        % Rate-1节点
            type_source = 1;
        elseif all(last_segment == 0)                                        % Rate-0节点
            type_source = -1;
         elseif all(last_segment(1 : 2) == 0) && all(last_segment(3 : end) == 1)  % type-III节点
            type_source = 4;
         else                                                            % Normal 节点
            type_source = 5;
        end
    end
%     fprintf('=== 所有分段检查通过 ===\n');
    result = 1;
end


function [dec_out_all] = decoder(llr_in, N, Kr, node_type_structure, idx_fzn,SR_struct,source_len)
    %--------------------------------------------------------------------------
    % 输入参数：
    %         llr_in：               信道llr
    %         node_type_structure：  节点类型矩阵
    %         frozen_ind：           冻结比特索引
    % 输出参数：
    %         dec_out_all：          译码输出比特
    
    % %---------------------------- 识别节点类型----------------------------% %
    T = size(node_type_structure, 1);                            % T代表总的节点个数
    
    P = zeros(N - 1, 1);                % LLR internal buffer, exclude input LLR, each column for 1 list
    C = zeros(N - 1, 2);                % judgment of each stage, 2 columns for left & right node of 1 list, exclude root node
    u = zeros(1, N);                    % infomation bits buffer, each row for 1 list
    dec_out_all = zeros(Kr, 1);         % output all decoded bits, for debug
    n = log2(N);

    % % ----------------------------节点类型参数----------------------------% %
    % for start_bit_idx = 1 : N
    for i_node = 1 : T                                     
        start_bit_idx = node_type_structure(i_node, 1);          % 矩阵第一列代表起始比特的位置 
        M = node_type_structure(i_node, 2);                      % 矩阵第二列代表子节点长度
        type = node_type_structure(i_node, 3);                   % 矩阵第三列代表节点类型                             
    
        % % ------------------------------参数设置------------------------------% %
        m = log2(M);                          
        c_out_idx = M : 2 * M - 1;
        % % -----------------------------生成矩阵G------------------------------% %
        G = calGMatric(m); 
        % % ----------------------------计算f和g函数----------------------------% %
        dec_idx = start_bit_idx : start_bit_idx + M - 1;
        c_idx = mod(dec_idx(2^m)/2^m, 2);
        start_stage = start_stage_calc(start_bit_idx - 1, m, n);
        p_sum_stage = p_sum_stage_calc(start_bit_idx - 1, m);
        stage = start_stage;       
        while(stage ~= m)
	        num_pe = 2^(stage - 1);						    % number of PEs for one stage
	        if(stage == n)
		        p_in_idx = [];							    % row index of P input
	        else
		        p_in_idx = 2^stage : 2^(stage + 1) - 1;     % row index of P input
	        end
            %% 
	        p_out_idx = 2^(stage - 1): 2^stage - 1; 	    % row index of P output
	        c_in_idx = 2^(stage - 1): 2^stage - 1;		    % row index of C input
    
            if(stage == start_stage)
                if(start_bit_idx == 1)                  
			        P(p_out_idx, 1) = pe(0, num_pe, llr_in, []);                           % first step of bit 0, f-pe
                elseif(start_bit_idx == N/2 + 1)
			        P(p_out_idx, 1) = pe(1, num_pe, llr_in, C(c_in_idx, 1));      % first step of bit N/2, g-pe
                else
                    % first step of other bits, g-pe, use lazy copy indicator of P buffer, use left node value of C buffer 
			        P(p_out_idx, 1) = pe(1, num_pe, P(p_in_idx, 1), C(c_in_idx, 1)); 
                end
            else
		        P(p_out_idx, 1) = pe(0, num_pe, P(p_in_idx, 1), []);                  % left steps, f-pe
            end
	        stage = stage - 1;
         end
        % % --------------------------按节点类型分别译码------------------------% %
        switch type
            case -1 % SR_node
                sr_x = SR_decode(P(p_out_idx,1),SR_struct{i_node},node_type_structure(i_node ,4),source_len);
                for i = 1 : M        
                    C(c_out_idx(i), 2 - c_idx) = sr_x(1,i);
                end
                u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2);
            case 1 % Rate-1 
                for i = 1 : M
                    if P(p_out_idx(i), 1) >= 0
                        C(c_out_idx(i), 2 - c_idx) = 0;
                    else
                        C(c_out_idx(i), 2 - c_idx) = 1;
                    end
                end
                u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2);
            case 3 % SPC
                llr_code = zeros(M, 1);
                x = zeros(1, M);
                sum_x = 0;
                for i = 1 : M
                    llr_code(i, 1) = P(p_out_idx(i), 1);               % 对每一个接收信号进行硬判决        
                    if llr_code(i, 1) >= 0
                        x(1, i) = 0;
                    else
                        x(1, i) = 1;
                    end                                                % x为硬判决比特序列
                    sum_x = sum_x + x(1, i);                           % 对硬判决比特序列求和
                end
                if mod(sum_x, 2) == 0                                  % 如果模二和为0
                    C(c_out_idx, 2 - c_idx) = x;                       % 硬判决序列即输出比特
                    u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2);
                else                        
                     if mod(sum_x, 2) ~= 0                                 % 如果和不为0
                        alpha_abs = abs(llr_code);
                        [~, min_index] = min(alpha_abs);                  % 找到llr绝对值最小的比特位置
                        x(min_index) = mod(x(min_index) + 1, 2);          % 对该比特进行翻转                     
                        C(c_out_idx, 2 - c_idx) = x;
                        u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2);
                     end
                end
            case 4 % type-III
                llr_code_1 = zeros(M/2, 1);
                llr_code_2 = zeros(M/2, 1);
                x_1 = zeros(1, M/2);
                x_2 = zeros(1, M/2);
                x = zeros(1, M);
                sum_x1 = 0;
                sum_x2 = 0;
                j = 1;
                for i = 1 : 2 : M - 1
                    if j <= M/2
                        llr_code_1(j, 1) = P(p_out_idx(i), 1);                       
    
                        if llr_code_1(j, 1) >= 0
                            x_1(1, j) = 0;
                        else
                            x_1(1, j) = 1;
                        end
                        sum_x1 = sum_x1 + x_1(1, j);
                        j = j + 1;
                    end
                end
                if mod(sum_x1, 2) ~= 0
                    alpha_abs = abs(llr_code_1);
                    [~, min_index] = min(alpha_abs);
                    x_1(min_index) = mod(x_1(min_index) + 1, 2);
                end

                j = 1;

                for i = 2 : 2 : M
                    if j <= M/2
                        llr_code_2(j, 1) = P(p_out_idx(i), 1);

                        if llr_code_2(j, 1) >= 0
                            x_2(1, j) = 0;
                        else
                            x_2(1, j) = 1;
                        end
                        sum_x2 = sum_x2 + x_2(1, j);
                        j = j + 1;
                    end
                
                end
                    if mod(sum_x2, 2) ~= 0
                        alpha_abs = abs(llr_code_2);
                        [~, min_index] = min(alpha_abs);
                        x_2(min_index) = mod(x_2(min_index) + 1, 2);
                    end
                
                for x_idx = 1 : M/2
                    x(2 * x_idx - 1) = x_1(x_idx);
                    x(2 * x_idx) = x_2(x_idx);
                end

                C(c_out_idx, 2 - c_idx) = x;                       
                u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2); 
            case 5 % Normal
                for i = 1 : M        
                    C(c_out_idx(i), 2 - c_idx) = 0;
                end
                u(1, dec_idx) = zeros(1, M);
        end
                    
        % % -------------------------------求部分和-----------------------------% %
        if((c_idx == 0)&&(dec_idx(end) ~= N))                       % calculate partial-sum at right child node
            u_stage = p_sum_stage;
            stage = m;
            while(u_stage ~= 0)
                phi = (u_stage == 1);                               % left or right indicator of column, left for last step, right for other steps
                p_sum_in_idx = 2^stage : 2^(stage + 1) - 1;         % row index of partial-sum input
                p_sum_out_idx = 2^(stage + 1) : 2^(stage + 2) - 1;  % row index of partial-sum output
                for i = 1 : 2^stage
                    C(p_sum_out_idx(i), 2 - phi) = mod(C(p_sum_in_idx(i), 1) + C(p_sum_in_idx(i), 2), 2);
                    C(p_sum_out_idx(i + 2^stage), 2 - phi) = C(p_sum_in_idx(i), 2);
                end
                stage = stage + 1;
                u_stage = u_stage - 1;
            end  
        end
    end

    % % ---------------------------提取信息比特-----------------------------% %
        cnt = 1;
        for i = 1 : N
            if(idx_fzn(i) == 0)
                dec_out_all(cnt, 1) = u(1, i); 
                cnt = cnt + 1;
            end
        end
end

function [SR_X] = SR_decode(LLR,SR_struct,type_source,source_len)
    % 示例输入向量（仅包含0和1）
    v = SR_struct;  % 可替换为任意0-1向量
    
    % 找出值为1的位置
    ones_pos = find(v == 1);
    k = length(ones_pos);  % 1的个数

    % 生成所有可能的0-1组合（共2^k种）
    combinations = dec2bin(0:2^k-1, k) - '0';  % 转换为数值矩阵
    
    % 生成所有可能的序列
    num_sequences = size(combinations, 1);
    sequences = repmat(v, num_sequences, 1);  % 初始化序列矩阵
    SR_path = [];
    SR_path_max = [];
    source_LLR_allpath = [];
    source_LLR = [];
    SR_X = [];
    % 填充所有组合
    for i = 1:num_sequences
        sequences(i, ones_pos) = combinations(i, :);
        SR_path(i,:) = kroneckerSumSequence(sequences(i,:));
        source_LLR_allpath(i,:) = funcGG(LLR,SR_path(i,:));
    end
    
    row_abs_sum = sum(abs(source_LLR_allpath), 2);
    % 找到绝对值和最大的行索引
    [~, max_idx] = max(row_abs_sum);
    
    % 提取对应的行
    SR_path_max = SR_path(max_idx,:);
    source_LLR = source_LLR_allpath(max_idx, :);
    x_source = zeros(1,source_len);
    
    % decode source
    switch type_source
        case -1
            x_source = zeros(1,source_len);
        case 1
            x_source(source_LLR(1,:) < 0) = 1;
        case 2
            sum_llr = sum(source_LLR);
            if sum_llr >= 0
                x_source = zeros(1,source_len);
            else
                x_source = ones(1,source_len);
            end
        case 3
            x_source = spc_decode(source_LLR);
        case 4
            odd_LLR = source_LLR(1:2:end);
            % 偶数位置向量（2,4,6...）
            even_LLR = source_LLR(2:2:end);
            % 对奇偶向量分别执行原处理操作
            odd_result = spc_decode(odd_LLR);
            even_result = spc_decode(even_LLR);
            % 合并处理结果（保持原位置顺序）
            x_source(1:2:end) = odd_result;  % 奇数位置填充奇数向量结果
            x_source(2:2:end) = even_result;  % 偶数位置填充偶数向量结果
    end
   
    % 按B的每个元素生成对应A或-A，再按列拼接为行向量
    for i = 1:length(SR_path_max)
    % 根据B(i)选择A或-A，转换为字符串后拼接
    if SR_path_max(i) == 0
        vec = xor(x_source,zeros(1,source_len));
    else
        vec = xor(x_source,ones(1,source_len));
    end
    % 将当前向量的元素转换为字符串并拼接（无分隔符）
    SR_X = [SR_X, vec];
    end
end



function C = kroneckerSumSequence(A)
    % 输入：0/1序列A
    % 输出：所有二元组依次做克罗内克和的结果C
    
    % 步骤1：生成二元组序列B
    B = cell(size(A));
    for i = 1:length(A)
        if A(i) == 1
            B{i} = [1, 0];  % 1对应(1,0)
        else
            B{i} = [0, 0];  % 0对应(0,0)
        end
    end
    
    % 步骤2：依次计算克罗内克和（#操作）
    % 初始值为第一个二元组
    C = B{1};
    % 从第二个元素开始迭代计算
    for i = 2:length(B)
        % 取出当前两个待运算的向量
        X = C;
        Y = B{i};
        % 克罗内克和：X中每个元素分别与Y中每个元素相加，生成新向量
        % 例如(1,0)#(1,0) = [1+1, 1+0, 0+1, 0+0] = [2,1,1,0]
        C = arrayfun(@(x) mod((x + Y),2), X, 'UniformOutput', false);
        C = cell2mat(C');  % 转换为行向量
        C = reshape(C.',[],1);
    end
end

function C = funcGG(A, B)
    % 检查输入有效性
    M = length(A);
    N = length(B);
    if mod(M, N) ~= 0
        error('A的长度必须是B长度的正整数倍');
    end
    K = M / N;  % C的长度
    
    % 将A按列分为N组（每组K个元素）
    A_matrix = reshape(A, K, N);  % K行N列矩阵，每列对应一组
    
    % 计算C：每组按B的符号运算（B=0为加，B=1为减）
    C = zeros(1, K);
    for k = 1:K  % 遍历C的每个位置
        sum_val = 0;
        for n = 1:N  % 遍历每组
            if B(n) == 0
                sum_val = sum_val + A_matrix(k, n);  % 加第n组的第k个元素
            else
                sum_val = sum_val - A_matrix(k, n);  % 减第n组的第k个元素
            end
        end
        C(k) = sum_val;
    end
end

function [start_stage] = start_stage_calc(index, m, n)
    if index == 0
        start_stage = n;
    else
        batch_id = floor(index / 2^m); % 当前batch编号
        stage = 0;
        % 统计最低位连续0个数
        while bitand(batch_id, 1) == 0 && batch_id ~= 0
            batch_id = bitshift(batch_id, -1); % 右移一位
            stage = stage + 1;
        end
        start_stage = stage + 1 + m;
    end
end

function [p_sum_stage] = p_sum_stage_calc(index, m)
    index_tmp = floor(index / 2^m);
    p_sum_stage = 0;
    
    while bitand(index_tmp, 1) % 等价于 mod(index_tmp,2)==1
        index_tmp = bitshift(index_tmp, -1); % 右移1位
        p_sum_stage = p_sum_stage + 1;
    end

end

function [llr_out] = pe(f_g, num, llr_in, bit_in)
    width_llr = 10;
    frac_llr = 2;
    
    % 预分块
    llr_in = llr_in(:);
    a = llr_in(1:num);
    b = llr_in(num+1:end);
    
    if f_g == 0
        % f-PE: min-sum近似
        llr_out = 0.9375 * sign(a) .* sign(b) .* min(abs(a), abs(b));
    else
        % g-PE: 结合译码比特
        u = bit_in(:); % 保证列向量
        llr_out = (1 - 2 * u) .* a + b;
        % 定点量化
        %llr_out = arrayfun(@(x) quantize(x, width_llr, frac_llr), llr_out); % -512 ~ 511
    end
end

% SPC处理逻辑封装为子函数
function spc_result = spc_decode(spc_LLR)
    % 第一步：大于等于0判0，小于0判1
    step1 = (spc_LLR < 0);  % 逻辑判断转换为0/1
    
    % 第二步：判断和的奇偶性，若为奇数则翻转绝对值最小元素对应的值
    s = sum(step1);
    if mod(s, 2) ~= 0
        % 找到绝对值最小的元素索引（若有多个，取第一个）
        [~, minIdx] = min(abs(spc_LLR));
        % 翻转对应的值（0变1，1变0）
        step1(minIdx) = 1 - step1(minIdx);
    end
    
    spc_result = step1;
end