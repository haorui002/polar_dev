% 
% 示例输入向量（仅包含0和1）
LLR = randi([0,1],1,16);
v = [1];  % 可替换为任意0-1向量

% % % 找出值为1的位置
% % ones_pos = find(v == 1);
% % k = length(ones_pos);  % 1的个数
% % 
% % % 生成所有可能的0-1组合（共2^k种）
% % combinations = dec2bin(0:2^k-1, k) - '0';  % 转换为数值矩阵
% % 
% % % 生成所有可能的序列
% % num_sequences = size(combinations, 1);
% % sequences = repmat(v, num_sequences, 1);  % 初始化序列矩阵
% % SR_path = [];
% % source_LLR = [];
% % % 填充所有组合
% % for i = 1:num_sequences
% %     sequences(i, ones_pos) = combinations(i, :);
% %     SR_path(i,:) = kroneckerSumSequence(sequences(i,:));
% %     source_LLR(i,:) = generateC(LLR,SR_path(i,:));
% % end
% % 
% % result = findMaxAbsRow(source_LLR);
% % 
% % 
% % 
% source_LLR = get_section_number([4,7],[1,1,0],[0,1,1]);
% % % 显示结果
% % disp('所有可能的序列：');
% % disp(sequences);
% % disp('所有path：');
% % disp(SR_path);
% disp('LLR:');
% disp(LLR);
% disp('源节点LLR：');
% disp(source_LLR);
% 
% function out = get_section_number(source_position, struct, mask)
%     % get_section_number 生成基于位置、结构和掩码的编码矩阵（保留向量反转）
%     %
%     % 输入:
%     %   source_position - 数值向量，原始位置索引
%     %   struct          - 二进制向量，用于异或操作的结构
%     %   mask            - 二进制向量，指示哪些位是固定的(1)或可变的(0)
%     %
%     % 输出:
%     %   out             - 数值矩阵，每行对应source_position一个元素的所有可能编码，
%     %                     空缺位置用NaN填充
% 
%     % 将位置减一
%     pos = source_position - 1;
%     
%     % 保留原有的反转逻辑
%     mask_vec = mask(end:-1:1);
%     struct_vec = struct(end:-1:1);
%     
%     % 确定二进制位宽并校验输入维度
%     n = length(struct_vec);
%     if length(mask_vec) ~= n
%         error('struct 和 mask 必须具有相同的长度。');
%     end
%     
%     % 初始化存储每个位置结果的元胞数组
%     out_cell = cell(length(pos), 1);
%     
%     for i = 1:length(pos)
%         % 将当前位置转换为n位二进制向量（确保高位在前，与dec2bin输出一致）
%         pos_binary_str = dec2bin(pos(i), n);
%         pos_binary = str2double(cellstr(pos_binary_str(:)));  % 转换为n×1向量
%         
%         % 计算固定位的值（mask为1的位强制固定，0的位保留为占位符）
%         fixed_bits = xor(pos_binary', struct_vec) .* mask_vec;
%         
%         % 找到可变位的索引（mask为0的位）
%         variable_indices = find(mask_vec == 0);
%         k = length(variable_indices);  % 可变位数量
%         
%         if k == 0
%             % 无可变位，仅一种组合
%             combined_binary = fixed_bits;  % 转为1×n行向量，便于后续处理
%         else
%             % 生成所有2^k种可变位组合（核心修复：确保维度正确）
%             num_combinations = 2^k;
%             % dec2bin生成num_combinations行×k列的字符矩阵（每行一个组合）
%             variable_combinations_str = dec2bin(0 : num_combinations - 1, k);
%             % 按行转换为数值矩阵（num_combinations行×k列），避免按列展开
%             variable_combinations = cellfun(@(row) str2double(cellstr(row(:))), ...
%                                            mat2cell(variable_combinations_str, ones(num_combinations,1), k), ...
%                                            'UniformOutput', false);
%             variable_combinations = cell2mat(variable_combinations);  % 直接得到num_combinations×k矩阵
%             
%             % 初始化组合矩阵：num_combinations行×n列，填充固定位
%             combined_binary = repmat(fixed_bits, num_combinations, 1);
%             % 赋值可变位（variable_combinations为num_combinations×k，与目标列数匹配）
%             combined_binary(:, variable_indices) = variable_combinations;
%         end
%         
%         % 将二进制向量转换为十进制数（每行一个二进制数）
%         decimal_values = zeros(size(combined_binary, 1), 1);
%         for j = 1:size(combined_binary, 1)
%             % 拼接当前行的二进制位，去除空格
%             binary_str = strrep(num2str(combined_binary(j, :)), ' ', '');
%             decimal_values(j) = bin2dec(binary_str);
%         end
%         
%         % 加1后存入元胞数组（还原为原始位置索引逻辑）
%         out_cell{i} = decimal_values + 1;
%     end
% 
%     % 构建输出矩阵（每行对应一个source_position元素，空缺填NaN）
%     if isempty(out_cell)
%         out = [];
%         return;
%     end
%     
%     num_rows = length(out_cell);
%     max_cols = max(cellfun(@length, out_cell));  % 最大列数（最多组合数）
%     out = NaN(num_rows, max_cols);  % 初始化输出矩阵
%     
%     % 逐行填充结果
%     for i = 1:num_rows
%         out(i, 1:length(out_cell{i})) = out_cell{i};
%     end
%     
%     out = double(out);  % 确保输出为double类型
% end

% function count_ones = xor_count_skip_segments(LLR, seg, len)
%     % 函数功能：
%     %   1. 将输入向量 LLR 按照跳步方式分段：
%     %      - 第 1 段: LLR(1), LLR(1+len), LLR(1+2*len), ...
%     %      - 第 2 段: LLR(2), LLR(2+len), LLR(2+2*len), ...
%     %      - ...
%     %      - 第 len 段: LLR(len), LLR(len+len), LLR(len+2*len), ...
%     %   2. 将每一段与向量 seg 进行按位异或。
%     %   3. 统计每次异或结果中 '1' 的个数。
%     %   4. 返回所有统计结果。
%     %
%     % 输入参数：
%     %   LLR - 输入的二进制向量 (可以是数值向量或逻辑向量)。
%     %   seg - 用于异或操作的二进制向量 (长度必须与每段的长度一致)。
%     %   len - 一个整数，定义了跳步的步长和分段的数量。
%     %
%     % 输出参数：
%     %   count_ones - 一个行向量，其第 i 个元素表示第 i 段与 seg 异或后结果中 '1' 的个数。
% 
%     % 检查输入向量是否为空
%     if isempty(LLR) || isempty(seg)
%         count_ones = 0;
%         warning('输入向量 LLR 或 seg 为空。');
%         return;
%     end
% 
%     % 检查 len 是否为正整数
%     if ~isscalar(len) || len <= 0 || len ~= floor(len)
%         error('输入 len 必须是一个正整数。');
%     end
%     
%     % 获取 LLR 的总长度
%     total_len_LLR = length(LLR);
%     
%     % 初始化用于存储计数结果的向量
%     count_ones = 0;
%     
%     % 循环处理每一段
%     for i = 1:len
%         % 生成当前段的索引：i, i+len, i+2*len, ... 
%         % 直到索引不超过 LLR 的总长度
%         indices = i:len:total_len_LLR;
%         
%         % 如果索引为空，说明没有足够的元素构成这一段，跳过
%         if isempty(indices)
%             warning('LLR 的长度不足以构成第 %d 段。', i);
%             continue;
%         end
%         
%         % 提取当前段
%         current_segment = LLR(indices)
%         
%         % 检查当前段的长度是否与 seg 的长度一致
%         if length(current_segment) ~= length(seg)
%             warning('第 %d 段的长度 (%d) 与 seg 的长度 (%d) 不一致，无法进行异或操作。', ...
%                 i, length(current_segment), length(seg));
%             continue;
%         end
%         
%         % 与 seg 进行按位异或
%         xor_result = xor(current_segment, seg);
%         
%         % 统计异或结果中 '1' 的个数，并存储
%         count_ones = count_ones+ sum(xor_result(:));
%     end
% 
% end
% 
% 
% 
% function result = xor_sum_segments(LLR, sou)
%     % 函数功能：
%     %   1. 将输入向量 LLR 按照 sou 的长度分段。
%     %   2. 将分段结果按奇偶位置分为两组。
%     %   3. 对两组中对应位置的段进行逐元素异或。
%     %   4. 统计所有异或结果中 '1' 的总数并返回。
%     %
%     % 输入参数：
%     %   LLR - 输入的二进制向量 (可以是数值向量或逻辑向量)。
%     %   sou - 一个整数，定义了每段的长度。
%     %
%     % 输出参数：
%     %   result - 一个整数，代表最终所有异或结果中 '1' 的总数。
% 
%     % 检查输入是否为空
%     if isempty(LLR)
%         result = 0;
%         return;
%     end
% 
%     % 检查 sou 是否为正整数
%     if ~isscalar(sou) || sou <= 0 || sou ~= floor(sou)
%         error('输入 sou 必须是一个正整数。');
%     end
% 
%     % 检查 LLR 的长度是否能被 sou 整除
%     len_LLR = length(LLR);
%     if mod(len_LLR, sou) ~= 0
%         error('输入向量 LLR 的长度 (%d) 必须能被 sou (%d) 整除。', len_LLR, sou);
%     end
% 
%     % ------------------- 步骤 1: 分段 -------------------
%     % 使用 reshape 函数将向量按 sou 长度分段。
%     % 每一行代表一个段。
%     num_segments = len_LLR / sou;
%     segments = reshape(LLR, sou, num_segments)'; 
%     % 注意：reshape 是按列优先的，所以转置一下 (') 使其按行排列，更符合直觉。
% 
%     % ------------------- 步骤 2: 分组 -------------------
%     % 提取奇数索引的段 (第1, 3, 5, ... 段)
%     K_odd = segments(1:2:end, :);
%     
%     % 提取偶数索引的段 (第2, 4, 6, ... 段)
%     K_eve = segments(2:2:end, :);
% 
%     % 检查两组数量是否相等，如果 K 是奇数，最后一个奇数段将没有对应的偶数段
%     if size(K_odd, 1) ~= size(K_eve, 1)
%         warning('段的总数 K = %d 是奇数。最后一个奇数段将不会被处理。', num_segments);
%         % 为了使后续计算可行，我们只处理前 N 对，其中 N 是较小的组数
%         min_num = min(size(K_odd, 1), size(K_eve, 1));
%         K_odd = K_odd(1:min_num, :);
%         K_eve = K_eve(1:min_num, :);
%     end
% 
%     % ------------------- 步骤 3: 对位异或 -------------------
%     % 使用逻辑异或运算符 xor 对两个矩阵的对应元素进行异或操作
%     xor_results = xor(K_odd, K_eve);
% 
%     % ------------------- 步骤 4: 求和 -------------------
%     % 计算 xor_results 矩阵中所有 '1' 的个数
%     result = sum(xor_results(:));
% 
% end
% 



% disp('绝对值之和最大的行是：');
% disp(result);
X=kroneckerSumSequence(v)
uu = funcGG([1,2,3,4,5,6,7,8],X)
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
        C = reshape(C.',[],1)
    end
end
% 
% function C = generateC(A, B)
%     % 检查输入有效性
%     M = length(A);
%     N = length(B);
%     if mod(M, N) ~= 0
%         error('A的长度必须是B长度的正整数倍');
%     end
%     K = M / N;  % C的长度
%     
%     % 将A按列分为N组（每组K个元素）
%     A_matrix = reshape(A, K, N);  % K行N列矩阵，每列对应一组
%     
%     % 计算C：每组按B的符号运算（B=0为加，B=1为减）
%     C = zeros(1, K);
%     for k = 1:K  % 遍历C的每个位置
%         sum_val = 0;
%         for n = 1:N  % 遍历每组
%             if B(n) == 0
%                 sum_val = sum_val + A_matrix(k, n);  % 加第n组的第k个元素
%             else
%                 sum_val = sum_val - A_matrix(k, n);  % 减第n组的第k个元素
%             end
%         end
%         C(k) = sum_val;
%     end
% end
% 
% 
% function max_row = findMaxAbsRow(arr)
%     % 确保输入是矩阵（二维数组）
%     if ndims(arr) ~= 2
%         error('请输入二维数组');
%     end
%     
%     % 计算每行元素的绝对值之和
%     row_abs_sum = sum(abs(arr), 2);  % 按行求和（第二个维度）
%     
%     % 找到绝对值和最大的行索引
%     [~, max_idx] = max(row_abs_sum);
%     
%     % 提取对应的行
%     max_row = arr(max_idx, :);
% end
% 
% function result = processVector(v)
%     % 将输入向量按奇偶位置拆分（索引从1开始）
%     % 奇数位置向量（1,3,5...）
%     odd_v = v(1:2:end);
%     % 偶数位置向量（2,4,6...）
%     even_v = v(2:2:end);
%     
%     % 对奇偶向量分别执行原处理操作
%     odd_result = processSubVector(odd_v);
%     even_result = processSubVector(even_v);
%     
%     % 合并处理结果（保持原位置顺序）
%     result = zeros(size(v));
%     result(1:2:end) = odd_result;  % 奇数位置填充奇数向量结果
%     result(2:2:end) = even_result;  % 偶数位置填充偶数向量结果
% end
% 
% % 原处理逻辑封装为子函数
% function sub_result = processSubVector(sub_v)
%     % 第一步：大于等于0判0，小于0判1
%     step1 = (sub_v < 0);  % 逻辑判断转换为0/1
%     
%     % 第二步：判断和的奇偶性，若为奇数则翻转绝对值最小元素对应的值
%     s = sum(step1);
%     if mod(s, 2) ~= 0
%         % 找到绝对值最小的元素索引（若有多个，取第一个）
%         [~, minIdx] = min(abs(sub_v));
%         % 翻转对应的值（0变1，1变0）
%         step1(minIdx) = 1 - step1(minIdx);
%     end
%     
%     sub_result = step1;
% end

% % 示例测试
% A = [1,0,1,0];
% B = [0,1,1,0];
% output = combineVectors(A, B);
% disp(output);  % 一行输出：1  2  3  4  -1  -2  -3  -4  -1  -2  -3  -4  1  2  3  4
% function result = combineVectors(A, B)
%     % 检查输入合法性
%     if length(A) ~= length(B) || ~all(B == 0 | B == 1)
%         error('A与B长度必须相同，且B元素只能为0或1');
%     end
%     % 生成系数（0→1，1→-1），通过广播生成矩阵后按列拼接为行向量
%     result=[];
%     % 按B的每个元素生成对应A或-A，再按列拼接为行向量
%     for i = 1:length(B)
%         % 根据B(i)选择A或-A，转换为字符串后拼接
%         if B(i) == 0
%             vec = xor(A,zeros(1,length(B)));
%         else
%             vec = xor(A,ones(1,length(B)));
%         end
%         % 将当前向量的元素转换为字符串并拼接（无分隔符）
%         result = [result, vec];
%     end
% end


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

% function [SR_X] = SR_decode(LLR,SR_struct,type_source,source_len)
%     % 示例输入向量（仅包含0和1）
%     v = SR_struct;  % 可替换为任意0-1向量
%     
%     % 找出值为1的位置
%     ones_pos = find(v == 1);
%     k = length(ones_pos);  % 1的个数
% 
%     % 生成所有可能的0-1组合（共2^k种）
%     combinations = dec2bin(0:2^k-1, k) - '0';  % 转换为数值矩阵
%     
%     % 生成所有可能的序列
%     num_sequences = size(combinations, 1);
%     sequences = repmat(v, num_sequences, 1);  % 初始化序列矩阵
%     SR_path = [];
%     SR_path_max = [];
%     source_LLR_allpath = [];
%     source_LLR = [];
% 
%     % 填充所有组合
%     for i = 1:num_sequences
%         sequences(i, ones_pos) = combinations(i, :);
%         SR_path(i,:) = kroneckerSumSequence(sequences(i,:));
%         source_LLR_allpath(i,:) = funcGG(LLR,SR_path(i,:));
%     end
%     
%     row_abs_sum = sum(abs(source_LLR_allpath), 2);
%     % 找到绝对值和最大的行索引
%     [~, max_idx] = max(row_abs_sum);
%     
%     % 提取对应的行
%     SR_path_max = SR_path(max_idx);
%     source_LLR = source_LLR_allpath(max_idx, :);
%     x_source = zeros(source_len);
%     
%     % decode source
%     switch type_source
%         case -1
%             x_source = zeros(source_len);
%         case 1
%             x_source(source_LLR(1,:) < 0) = 1;
%         case 2
%             sum_llr = sum(source_LLR);
%             if sum_llr >= 0
%                 x_source = zeros(source_len);
%             else
%                 x_source = ones(source_len);
%             end
%         case 3
%             x_source = spc_decode(source_LLR);
%         case 4
%             odd_LLR = source_LLR(1:2:end);
%             % 偶数位置向量（2,4,6...）
%             even_LLR = source_LLR(2:2:end);
%             % 对奇偶向量分别执行原处理操作
%             odd_result = spc_decode(odd_LLR);
%             even_result = spc_decode(even_LLR);
%             % 合并处理结果（保持原位置顺序）
%             x_source(1:2:end) = odd_result;  % 奇数位置填充奇数向量结果
%             x_source(2:2:end) = even_result;  % 偶数位置填充偶数向量结果
%     end
%    
%     % 按B的每个元素生成对应A或-A，再按列拼接为行向量
%     SR_X = reshape( x_source.' .* (1-2*SR_path_max), 1, [] );
% end
% 

