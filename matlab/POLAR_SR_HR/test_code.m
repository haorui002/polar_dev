% 
% % 示例输入向量（仅包含0和1）
% LLR = randi([-5,5],1,32);
% v = [1, 0,1];  % 可替换为任意0-1向量
% 
% % 找出值为1的位置
% ones_pos = find(v == 1);
% k = length(ones_pos);  % 1的个数
% 
% % 生成所有可能的0-1组合（共2^k种）
% combinations = dec2bin(0:2^k-1, k) - '0';  % 转换为数值矩阵
% 
% % 生成所有可能的序列
% num_sequences = size(combinations, 1);
% sequences = repmat(v, num_sequences, 1);  % 初始化序列矩阵
% SR_path = [];
% source_LLR = [];
% % 填充所有组合
% for i = 1:num_sequences
%     sequences(i, ones_pos) = combinations(i, :);
%     SR_path(i,:) = kroneckerSumSequence(sequences(i,:));
%     source_LLR(i,:) = generateC(LLR,SR_path(i,:));
% end
% 
% result = findMaxAbsRow(source_LLR);
% 
% 
% 
% % 显示结果
% disp('所有可能的序列：');
% disp(sequences);
% disp('所有path：');
% disp(SR_path);
% disp('LLR:');
% disp(LLR);
% disp('源节点LLR：');
% disp(source_LLR);
% disp('绝对值之和最大的行是：');
% disp(result);
% 
% function C = kroneckerSumSequence(A)
%     % 输入：0/1序列A
%     % 输出：所有二元组依次做克罗内克和的结果C
%     
%     % 步骤1：生成二元组序列B
%     B = cell(size(A));
%     for i = 1:length(A)
%         if A(i) == 1
%             B{i} = [1, 0];  % 1对应(1,0)
%         else
%             B{i} = [0, 0];  % 0对应(0,0)
%         end
%     end
%     
%     % 步骤2：依次计算克罗内克和（#操作）
%     % 初始值为第一个二元组
%     C = B{1};
%     % 从第二个元素开始迭代计算
%     for i = 2:length(B)
%         % 取出当前两个待运算的向量
%         X = C;
%         Y = B{i};
%         % 克罗内克和：X中每个元素分别与Y中每个元素相加，生成新向量
%         % 例如(1,0)#(1,0) = [1+1, 1+0, 0+1, 0+0] = [2,1,1,0]
%         C = arrayfun(@(x) mod((x + Y),2), X, 'UniformOutput', false);
%         C = cell2mat(C');  % 转换为行向量
%         C = reshape(C.',[],1)
%     end
% end
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

% 示例测试
A = [1,0,1,0];
B = [0,1,1,0];
output = combineVectors(A, B);
disp(output);  % 一行输出：1  2  3  4  -1  -2  -3  -4  -1  -2  -3  -4  1  2  3  4
function result = combineVectors(A, B)
    % 检查输入合法性
    if length(A) ~= length(B) || ~all(B == 0 | B == 1)
        error('A与B长度必须相同，且B元素只能为0或1');
    end
    % 生成系数（0→1，1→-1），通过广播生成矩阵后按列拼接为行向量
    result=[];
    % 按B的每个元素生成对应A或-A，再按列拼接为行向量
    for i = 1:length(B)
        % 根据B(i)选择A或-A，转换为字符串后拼接
        if B(i) == 0
            vec = xor(A,zeros(1,length(B)));
        else
            vec = xor(A,ones(1,length(B)));
        end
        % 将当前向量的元素转换为字符串并拼接（无分隔符）
        result = [result, vec];
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

