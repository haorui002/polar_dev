function [dec_out] = HR_Only_Decoder(N,K, dec_in, WQ_LIST)

    

    counter=0;
    reliability_seq = WQ_LIST(WQ_LIST(:,2)<N,:);
    fzn_indices = reliability_seq(1:end-K, 2) + 1;
    source_len = 4;
    idx_fzn = zeros(1, N);
    idx_fzn(fzn_indices) = 1;
    idx = 1 : length(idx_fzn);
    code_struct = zeros(length(idx_fzn), 4); % start, end, type
    HR_struct = {};
    cnt_struct = 1;
    [HR_struct, code_struct, ~] = identify_node(~idx_fzn, idx, code_struct, cnt_struct,HR_struct, source_len);
    code_struct = code_struct(code_struct ~= 0);
    code_struct = reshape(code_struct', length(code_struct)/4, 4);
    HR_struct = HR_struct';
    dec_out = decoder(dec_in, N, K, code_struct, idx_fzn,HR_struct,source_len);
end

function [HR_struct,  code_struct, cnt_struct] = identify_node(idx_fzn, idx, code_struct, cnt_struct,HR_struct, source_len)
    N = length(idx_fzn);
        if all(idx_fzn(1 : end - 1) == 0) && (idx_fzn(end) == 1)        % Rep节点
            code_struct(cnt_struct, :) = [idx(1), N, 2,7];
            cnt_struct = cnt_struct + 1;
        elseif all(idx_fzn == 0)                                        % Rate-0节点
            code_struct(cnt_struct, :) = [idx(1), N, 1,7];
            cnt_struct = cnt_struct + 1;
        elseif all(idx_fzn(1 : 2) == 0) && all(idx_fzn(3 : end) == 1)  % type-III节点
            code_struct(cnt_struct, :) = [idx(1), N, 4,7];
            cnt_struct = cnt_struct + 1;
        elseif is_segment_HR(idx_fzn,source_len)                            %HR节点
            [~,HR_struct{cnt_struct},type_source] = is_segment_HR(idx_fzn,source_len);
            code_struct(cnt_struct, :) = [idx(1), N, -1,type_source];
            cnt_struct = cnt_struct + 1;
        elseif N > source_len
            [HR_struct, code_struct, cnt_struct] = identify_node(idx_fzn(1 : N/2), idx(1 : N/2) ,code_struct, cnt_struct,HR_struct, source_len);
            [HR_struct, code_struct, cnt_struct] = identify_node(idx_fzn(N/2 + 1 : end), idx(N/2 + 1 : end),code_struct, cnt_struct,HR_struct, source_len);
        else                                                           
            code_struct(cnt_struct, :) = [idx(1), N, 5,7];
            cnt_struct = cnt_struct + 1;
        end
end
    

function [result,HR_struct_r,type_source] = is_segment_HR(sequence,source_len)

n = length(sequence);
segment_end_HR = n;
segment_number_HR = 1;

% 存储所有分段信息
all_segments_HR = {};

% 分段模式的分母序列：2,4,8,16...
denominator = 2;

while true
    % 计算当前分段结束位置
    segment_start_HR = floor(n * 1/denominator) + 1;
    
    % 确保分段长度至少为4
    if (segment_end_HR - segment_start_HR + 1) < source_len
%         fprintf('分段%d (%d-%d) 长度小于4，停止遍历\n', ...
%         segment_number_HR, segment_start_HR, segment_end_HR);
        all_segments_HR{end+1} = struct('number',segment_number_HR,'start',segment_start_HR,'end',segment_end_HR,'content',sequence(segment_end_HR-source_len+1:segment_end_HR));
        break;
    end
    
    % 提取当前分段
    current_segment_HR = sequence(segment_start_HR:segment_end_HR);
    
    % 存储分段信息
    segment_info_HR = struct();
    segment_info_HR.number = segment_number_HR;
    segment_info_HR.start = segment_start_HR;
    segment_info_HR.end = segment_end_HR;
    segment_info_HR.content = current_segment_HR;
    all_segments_HR{end+1} = segment_info_HR;
    
%     % 显示分段信息
%     fprintf('分段%d: 位置[%d-%d], 长度=%d\n', ...
%         segment_number_HR, segment_start_HR, segment_end_HR, length(current_segment_HR));
%     fprintf('  内容: %s\n', mat2str(current_segment_HR));
%     fprintf('  范围: 前%.3f到前%.3f\n\n', ...
%         1 - (segment_start_HR-1)/n, 1 - segment_end_HR/n);
    
    % 更新下一个分段的起始位置
    segment_end_HR = segment_start_HR - 1;
    segment_number_HR = segment_number_HR + 1;
    denominator = denominator * 2;
    
    % 检查是否到达序列末尾
    if segment_end_HR < 1
        break;
    end
end

[result,HR_struct_r,type_source] = check_all_segments_HR(all_segments_HR);

end

function [result,HR_struct_r,type_source] = check_all_segments_HR(all_segments_HR)
    % 检查除最后一个分段外的所有分段是否全为0或全为1
    HR_struct_r = [];
    type_source = 0;

    if isempty(all_segments_HR)
%         fprintf('没有可检查的分段\n');
        result = 0;
        return;
    end
    
%     fprintf('\n=== 开始分段检查 ===\n');
    
    % 检查除最后一个分段外的所有分段
    for i = 1:length(all_segments_HR)-1
        segment = all_segments_HR{i};
        current_segment_HR = segment.content;
        
        % 检查是否全为0或全为1
        boool = all(current_segment_HR) || ((current_segment_HR(1) == 0) && all(current_segment_HR(2:end) == 1));
%         fprintf('检查分段%d [%d-%d]: ', ...
%             segment.number, segment.start, segment.end);
        
        if ~boool
            result = 0;
            HR_struct_r = zeros;
            return;
        else
            if all(current_segment_HR)
                HR_struct_r = [0,HR_struct_r];
            else
                HR_struct_r = [1,HR_struct_r];
            end
        end
    end
    
    % 最后一个分段不检查
    if length(all_segments_HR) > 0
        last_segment = all_segments_HR{end}.content;
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



function [dec_out_all] = decoder(llr_in, N, Kr, node_type_structure, idx_fzn,HR_struct,source_len)
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
            case -1 % HR_node
                hr_x = HR_decode(P(p_out_idx,1),HR_struct{i_node},node_type_structure(i_node ,4),source_len);
                for i = 1 : M        
                    C(c_out_idx(i), 2 - c_idx) = hr_x(1,i);
                end
                u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2);
            case 1 % Rate-0 
                for i = 1 : M        
                    C(c_out_idx(i), 2 - c_idx) = 0;
                end
                u(1, dec_idx) = zeros(1, M);
            case 2 % REP
                sum_llr = 0;
                for i = 1 : M                        
                    llrwidth = 8;
                    frac = 1;
%                         P_fix = quantize(P(p_out_idx(i), 1),llrwidth,frac);
                    sum_llr = sum_llr + P(p_out_idx(i),1);
                end
                    if sum_llr >= 0
                        C(c_out_idx, 2 - c_idx) = zeros(M, 1);
                        u(1, dec_idx) = zeros(1, M);
                    else
                        C(c_out_idx, 2 - c_idx) = ones(M, 1);
                        u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)'*G, 2); 
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

function [HR_X] = HR_decode(LLR,HR_struct,type_source,source_len)

    x_source = zeros(1,source_len);
    min_idx = zeros(source_len,1);

    %hard_charge
    HR_X = LLR < 0 ;
    

    % 计算分段数k
    k = length(LLR) / source_len;
    reshaped_LLR = reshape(LLR, source_len, k)';


    % 源节点llr,f
    source_LLR = zeros(1, source_len);
    for i = 1:source_len
        current_column = reshaped_LLR(:, i);
        [min_abs_val, min_idx(i)] = min(abs(current_column));
        min_idx(i) = (min_idx(i)-1)*source_len + i;
        sign_product = (-1)^sum(current_column < 0);
        source_LLR(i) = min_abs_val * sign_product;
    end

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

    %P-PC flip
    for i = 1:source_len
        if (source_LLR(i)<0) ~= x_source(i)
            HR_X(min_idx(i)) = 1 - HR_X(min_idx(i));
        end
    end

    % get section position
    HR_X_xor_res = node_HR_xor_process(HR_X,source_len);
    section_position = section_flip_position(HR_struct,HR_X_xor_res);
    sorted_rows = sort(section_position, 2);  % 每行按升序排序,找到排序后不重复的行索引,提取唯一行
    [~, unique_idx] = unique(sorted_rows, 'rows');
    section_position = section_position(sort(unique_idx), :);

    %S-PC filp
    [~,SPC_indices] = findMinPair(LLR, source_len, section_position);
    if all(HR_struct==0) || all(HR_X_xor_res==0)
%         HR_X = HR_X;
    else
        c = HR_X;                  
        for idx = 1:length(SPC_indices)    
            target_idx = SPC_indices(idx); 
            c(target_idx) = 1-c(target_idx);  
        end
        HR_X = c;
    end
    HR_X = HR_X';
        
end


function out = node_HR_xor_process(a, len)
    % 输入检查：确保a是由0和1组成的向量
    if ~isvector(a) || any(~ismember(a, [0, 1]))
        error('输入a必须是仅包含0和1的向量');
    end
    a = a(:)';  % 转换为行向量便于处理
    n = length(a);
    out = [];
    current_len = len;  % 初始分段长度
    
    while current_len <= n/2  % 分段长度不超过向量长度的一半
        % 计算当前长度下的完整分段数量
        num_segments = floor(n / current_len);
        if num_segments < 1
            break;
        end
        
        % 提取所有完整分段
        segments = cell(1, num_segments);
        for i = 1:num_segments
            start_idx = (i-1)*current_len + 1;
            end_idx = i*current_len;
            segments{i} = a(start_idx:end_idx);
        end
        
        % 提取偶数索引的分段（第2,4,6...段）
        even_indices = 2:2:num_segments;
        if ~isempty(even_indices)
            % 初始化异或结果（与分段长度相同的全0向量）
            xor_result = zeros(1, current_len);
            % 对所有偶数段进行逐比特异或
            for k = 1:length(even_indices)
                xor_result = xor(xor_result, segments{even_indices(k)});
            end
            
            % 对异或后的所有比特再做一次整体异或，得到单个比特
            final_bit = xor_result(1);
            for b = 2:current_len
                final_bit = xor(final_bit, xor_result(b));
            end
            
            out = [out, final_bit];  % 将结果添加到输出向量
        end
        
        current_len = current_len * 2;  % 分段长度翻倍
    end
end

function [min_val, indices] = findMinPair(input, len, matrix)
    % 输入检查
    n = length(input);
    if mod(n, len) ~= 0
        error('输入向量input的长度必须能被len整除');
    end
    m = n / len;  % 段的总数量
    [k, col] = size(matrix);
   
    if any(matrix(:) < 1) || any(matrix(:) > m)
        error('matrix中的段号必须在有效范围内（1到%d）', m);
    end
    
    % 步骤1：将input划分为n/len段（每段长度为len）
    segments = reshape(input, len, m)';  % 转换为m行len列的矩阵，每行代表一个段
    
    % 步骤2：根据matrix计算对位绝对值相加结果及对应索引
    num_values = k*len;  % 总共有km个数值
    values = zeros(num_values, 1);      % 存储相加结果
    indices = ones(num_values, 2);     % 存储每个结果对应的原始索引对
    
    current_idx = 1;  % 用于追踪当前存储位置
    for i = 1:k
        a = matrix(i, 1);  % 第一段号
        b = matrix(i, 2);  % 第二段号
        for j = 1:len
            % 计算对位绝对值之和
            values(current_idx) = abs(segments(a, j)) + abs(segments(b, j));
            % 计算原始索引（MATLAB索引从1开始）
            indices(current_idx, 1) = (a - 1) * len + j;  % 第一段中第j个元素的索引
            indices(current_idx, 2) = (b - 1) * len + j;  % 第二段中第j个元素的索引
            current_idx = current_idx + 1;
        end
    end
    
    % 步骤3：找到最小值
    min_val = min(values);
    
    % 步骤4：找到最小值对应的索引对（若有多个最小值，取第一个）
    min_pos = find(values == min_val, 1);
    indices = indices(min_pos, :);
end

function result = section_flip_position(HR_struct,HR_X_xor_res)
    % 初始化矩阵为[1, 1]
    mat = [1, 1];
    v = zeros(size(HR_X_xor_res));
    
    % 根据a的值生成c
    for i = 1:length(HR_X_xor_res)
        if HR_struct(i) == 0
            v(i) = -1;
        else  % a(i) == 1
            v(i) = HR_X_xor_res(i);
        end
    end
    
    % 遍历输入向量的每个元素
    for i = 1:length(v)
        elem = v(i);
        current_rows = size(mat, 1);
        new_mat = [];  % 存储扩展后的矩阵
        delta = 2^(i-1);  % 增量为2^(i-1)（关键修正）
        
        % 根据当前元素值进行扩展
        for row = 1:current_rows
            a = mat(row, 1);
            b = mat(row, 2);
            
            switch elem
                case -1
                    % 扩展为4行
                    new_rows = [
                        a, b;
                        a + delta, b;
                        a, b + delta;
                        a + delta, b + delta
                    ];
                case 0
                    % 扩展为2行
                    new_rows = [
                        a, b;
                        a + delta, b + delta
                    ];
                case 1
                    % 扩展为2行
                    new_rows = [
                        a + delta, b;
                        a, b + delta
                    ];
                otherwise
                    error('输入向量元素必须为-1、0或1');
            end
            
            new_mat = [new_mat; new_rows];  % 拼接扩展后的行
        end
        
        mat = new_mat;  % 更新矩阵为扩展后的结果
    end
    
    result = mat;
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