function [info_esti, denoised_llr, error, iter_this_time] = SR_HR_Decoder_LLR(N,K, dec_in, WQ_LIST)


 counter=0;
    reliability_seq = WQ_LIST(WQ_LIST(:,2)<N,:);
    fzn_indices = reliability_seq(1:end-K, 2) + 1;

    idx_fzn = zeros(1, N);
    idx_fzn(fzn_indices) = 1;
    idx = 1 : length(idx_fzn);
    code_struct = zeros(length(idx_fzn), 3); % start, end, type
    cnt_struct = 1;
    [code_struct, ~] = identify_node(~idx_fzn, idx, code_struct, cnt_struct);
    code_struct = code_struct(code_struct ~= 0);
    code_struct = reshape(code_struct', length(code_struct)/3, 3);
    dec_out = decoder(dec_in, N, K, code_struct, idx_fzn);
end

function [code_struct, cnt_struct] = identify_node(idx_fzn, idx, code_struct, cnt_struct)
    N = length(idx_fzn);
    source_len = 16;
        if is_segment_SR(idx_fzn,source_len)
            code_struct(cnt_struct, :) = [idx(1), N, 1];
            cnt_struct = cnt_struct + 1;
        elseif is_segment_HR(idx_fzn,source_len)
            code_struct(cnt_struct, :) = [idx(1), N, 2];
            cnt_struct = cnt_struct + 1;
        elseif N > source_len
            [code_struct, cnt_struct] = identify_node(idx_fzn(1 : N/2), idx(1 : N/2) ,code_struct, cnt_struct);
            [code_struct, cnt_struct] = identify_node(idx_fzn(N/2 + 1 : end), idx(N/2 + 1 : end),code_struct, cnt_struct);
        else                                                           
            code_struct(cnt_struct, :) = [idx(1), N, 5];
            cnt_struct = cnt_struct + 1;
        end
end
    

function result = is_segment_SR(sequence,source_len)

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
        fprintf('分段%d (%d-%d) 长度小于4，停止遍历\n', ...
        segment_number_SR, segment_start_SR, segment_end_SR);
        all_segments_SR{end+1} = struct('number',segment_number_SR,'start',segment_start_SR,'end',segment_end_SR,'content',sequence(segment_start_SR:segment_end_SR));
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
    
    % 显示分段信息
    fprintf('分段%d: 位置[%d-%d], 长度=%d\n', ...
        segment_number_SR, segment_start_SR, segment_end_SR, length(current_segment_SR));
    fprintf('  内容: %s\n', mat2str(current_segment_SR));
    fprintf('  范围: 前%.3f到前%.3f\n\n', ...
        1 - (segment_start_SR-1)/n, 1 - segment_end_SR/n);
    
    % 更新下一个分段的起始位置
    segment_start_SR = segment_end_SR + 1;
    segment_number_SR = segment_number_SR + 1;
    denominator = denominator * 2;
    
    % 检查是否到达序列末尾
    if segment_start_SR > n
        break;
    end
end

% 执行分段检查（除最后一个分段外）
result = check_all_segments_SR(all_segments_SR);
end

function result = check_all_segments_SR(all_segments_SR)
    % 检查除最后一个分段外的所有分段是否全为0或全为1
    
    if isempty(all_segments_SR)
        fprintf('没有可检查的分段\n');
        result = 0;
        return;
    end
    
    fprintf('\n=== 开始分段检查 ===\n');
    
    % 检查除最后一个分段外的所有分段
    for i = 1:length(all_segments_SR)-1
        segment = all_segments_SR{i};
        current_segment_SR = segment.content;
        
        % 检查是否全为0或全为1
        boool = all(~current_segment_SR) || ((current_segment_SR(end) == 1) && all(current_segment_SR(1:end-1) == 0));
        fprintf('检查分段%d [%d-%d]: ', ...
            segment.number, segment.start, segment.end);
        
        if boool
            fprintf('✓ 满足条件 ');
        else
            fprintf('✗ 不满足条件\n');
            result = 0;
            return;
        end
    end
    
    % 最后一个分段不检查
    if length(all_segments_SR) > 0
        last_segment = all_segments_SR{end};
        fprintf('最后一个分段%d [%d-%d] 跳过检查\n', ...
            last_segment.number, last_segment.start, last_segment.end);
    end
    fprintf('=== 所有分段检查通过 ===\n');
    result = 1;
end

function result = is_segment_HR(sequence,source_len)

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
        fprintf('分段%d (%d-%d) 长度小于4，停止遍历\n', ...
        segment_number_HR, segment_start_HR, segment_end_HR);
        all_segments_HR{end+1} = struct('number',segment_number_HR,'start',segment_start_HR,'end',segment_end_HR,'content',sequence(segment_start_HR:segment_end_HR));
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
    
    % 显示分段信息
    fprintf('分段%d: 位置[%d-%d], 长度=%d\n', ...
        segment_number_HR, segment_start_HR, segment_end_HR, length(current_segment_HR));
    fprintf('  内容: %s\n', mat2str(current_segment_HR));
    fprintf('  范围: 前%.3f到前%.3f\n\n', ...
        1 - (segment_start_HR-1)/n, 1 - segment_end_HR/n);
    
    % 更新下一个分段的起始位置
    segment_end_HR = segment_start_HR - 1;
    segment_number_HR = segment_number_HR + 1;
    denominator = denominator * 2;
    
    % 检查是否到达序列末尾
    if segment_end_HR < 1
        break;
    end
end

% 执行分段检查（除最后一个分段外）
result = check_all_segments_HR(all_segments_HR);
end

function result = check_all_segments_HR(all_segments_HR)
    % 检查除最后一个分段外的所有分段是否全为0或全为1
    
    if isempty(all_segments_HR)
        fprintf('没有可检查的分段\n');
        result = 0;
        return;
    end
    
    fprintf('\n=== 开始分段检查 ===\n');
    
    % 检查除最后一个分段外的所有分段
    for i = 1:length(all_segments_HR)-1
        segment = all_segments_HR{i};
        current_segment_HR = segment.content;
        
        % 检查是否全为0或全为1
        boool = all(current_segment_HR) || ((current_segment_HR(1) == 0) && all(current_segment_HR(2:end) == 1));
        fprintf('检查分段%d [%d-%d]: ', ...
            segment.number, segment.start, segment.end);
        
        if boool
            fprintf('✓ 满足条件 ');
        else
            fprintf('✗ 不满足条件\n');
            result = 0;
            return;
        end
    end
    
    % 最后一个分段不检查
    if length(all_segments_HR) > 0
        last_segment = all_segments_HR{end};
        fprintf('最后一个分段%d [%d-%d] 跳过检查\n', ...
            last_segment.number, last_segment.start, last_segment.end);
    end
    fprintf('=== 所有分段检查通过 ===\n');
    result = 1;
end







