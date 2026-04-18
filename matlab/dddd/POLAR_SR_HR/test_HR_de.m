% % 示例测试
% a = [1,0,0,1,0,1,0,1];  % 输入向量（对应二进制字符串'00010011'）
% len = 2;
% result = bitwise_xor_process(a, len);
% disp(result);  % 输出：1  0（与示例完全一致）
% 
% function out = bitwise_xor_process(a, len)
%     % 输入检查：确保a是由0和1组成的向量
%     if ~isvector(a) || any(~ismember(a, [0, 1]))
%         error('输入a必须是仅包含0和1的向量');
%     end
%     a = a(:)';  % 转换为行向量便于处理
%     n = length(a);
%     out = [];
%     current_len = len;  % 初始分段长度
%     
%     while current_len <= n/2  % 分段长度不超过向量长度的一半
%         % 计算当前长度下的完整分段数量
%         num_segments = floor(n / current_len);
%         if num_segments < 1
%             break;
%         end
%         
%         % 提取所有完整分段
%         segments = cell(1, num_segments);
%         for i = 1:num_segments
%             start_idx = (i-1)*current_len + 1;
%             end_idx = i*current_len;
%             segments{i} = a(start_idx:end_idx);
%         end
%         
%         % 提取偶数索引的分段（第2,4,6...段）
%         even_indices = 2:2:num_segments;
%         if ~isempty(even_indices)
%             % 初始化异或结果（与分段长度相同的全0向量）
%             xor_result = zeros(1, current_len);
%             % 对所有偶数段进行逐比特异或
%             for k = 1:length(even_indices)
%                 xor_result = xor(xor_result, segments{even_indices(k)});
%             end
%             
%             % 对异或后的所有比特再做一次整体异或，得到单个比特
%             final_bit = xor_result(1);
%             for b = 2:current_len
%                 final_bit = xor(final_bit, xor_result(b));
%             end
%             
%             out = [out, final_bit];  % 将结果添加到输出向量
%         end
%         
%         current_len = current_len * 2;  % 分段长度翻倍
%     end
% end
% 


% % 示例测试（与您的描述完全匹配）
% v = [1,1,0,-1];
% result = expand_matrix(v);
% % 对每行的两个元素排序，确保相同无序对具有相同的排序结果
% sorted_rows = sort(result, 2);  % 每行按升序排序
% 
% % 找到排序后不重复的行索引
% [~, unique_idx] = unique(sorted_rows, 'rows');
% 
% % 按原始顺序提取唯一行（取每组重复行中的第一行）
% result = result(sort(unique_idx), :);
% disp(result);
% 
% 
% function result = expand_matrix(v)
%     % 初始化矩阵为[1, 1]
%     mat = [1, 1];
%     
%     % 遍历输入向量的每个元素
%     for i = 1:length(v)
%         elem = v(i);
%         current_rows = size(mat, 1);
%         new_mat = [];  % 存储扩展后的矩阵
%         delta = 2^(i-1);  
%         
%         % 根据当前元素值进行扩展
%         for row = 1:current_rows
%             a = mat(row, 1);
%             b = mat(row, 2);
%             
%             switch elem
%                 case -1
%                     % 扩展为4行
%                     new_rows = [
%                         a, b;
%                         a + delta, b;
%                         a, b + delta;
%                         a + delta, b + delta
%                     ];
%                 case 0
%                     % 扩展为2行
%                     new_rows = [
%                         a, b;
%                         a + delta, b + delta
%                     ];
%                 case 1
%                     % 扩展为2行
%                     new_rows = [
%                         a + delta, b;
%                         a, b + delta
%                     ];
%                 otherwise
%                     error('输入向量元素必须为-1、0或1');
%             end
%             
%             new_mat = [new_mat; new_rows];  % 拼接扩展后的行
%         end
%         
%         mat = new_mat;  % 更新矩阵为扩展后的结果
%     end
%     
%     result = mat;
% end
% 


% 测试数据

input = [3,1,2,4,6,7,3,5,0, -1, 2, 3, -4, 5, 6, -7];
out = input;
len = 4;
matrix = [ 4, 2, 3,1,3,2,4,1,2,3,4,4];
                   % 复制原始向量，避免修改a
for idx = 1:length(matrix)    % 遍历b的每个元素（循环次数=length(b)）
    target_idx = matrix(idx); % 当前要修改的a的索引
    out(target_idx) = 1-out(target_idx);  % 对应位置取相反数
end


% 输出结果
% disp(['最小值：', num2str(min_val)]);
disp(['对应的索引：', num2str(out)]);
% 
% function [min_val, indices] = findMinPair(input, len, matrix)
%     % 输入检查
%     n = length(input);
%     if mod(n, len) ~= 0
%         error('输入向量input的长度必须能被len整除');
%     end
%     m = n / len;  % 段的总数量
%     [k, col] = size(matrix);
%    
%     if any(matrix(:) < 1) || any(matrix(:) > m)
%         error('matrix中的段号必须在有效范围内（1到%d）', m);
%     end
%     
%     % 步骤1：将input划分为n/len段（每段长度为len）
%     segments = reshape(input, len, m)';  % 转换为m行len列的矩阵，每行代表一个段
%     
%     % 步骤2：根据matrix计算对位绝对值相加结果及对应索引
%     num_values = k*m;  % 总共有km个数值
%     values = zeros(num_values, 1);      % 存储相加结果
%     indices = zeros(num_values, 2);     % 存储每个结果对应的原始索引对
%     
%     current_idx = 1;  % 用于追踪当前存储位置
%     for i = 1:k
%         a = matrix(i, 1);  % 第一段号
%         b = matrix(i, 2);  % 第二段号
%         for j = 1:len
%             % 计算对位绝对值之和
%             values(current_idx) = abs(segments(a, j)) + abs(segments(b, j));
%             % 计算原始索引（MATLAB索引从1开始）
%             indices(current_idx, 1) = (a - 1) * len + j;  % 第一段中第j个元素的索引
%             indices(current_idx, 2) = (b - 1) * len + j;  % 第二段中第j个元素的索引
%             current_idx = current_idx + 1;
%         end
%     end
%     
%     % 步骤3：找到最小值
%     min_val = min(values);
%     
%     % 步骤4：找到最小值对应的索引对（若有多个最小值，取第一个）
%     min_pos = find(values == min_val, 1);
%     indices = indices(min_pos, :);
% end
