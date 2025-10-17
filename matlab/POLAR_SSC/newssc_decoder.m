function [dec_out_all, cb_dec, cb_err] = newSSC_decoder(llr_in, N, Kr, node_type_structure, frozen_ind, CRC_type, Maskbits)
%--------------------------------------------------------------------------
% 函数功能：v1.0 对simplified SC译码算法进行优化，节点长度范围在4-128，新增节点类型Type-I~Type-V
%           v2.0 对不同类型的节点分别限制长度
% 输入参数：
%         llr_in：               信道llr
%         node_type_structure：  节点类型矩阵
%         frozen_ind：           冻结比特索引
%         CRC_type：             CRC类型
%         Maskbits：             校验掩码序列
% 输出参数：
%         dec_out_all：          译码输出比特
%         cb_dec：               码块译码输出
%         cb_err：               误块数

% %---------------------------- 识别节点类型----------------------------% %

% node_type_structure = get_node_structure(frozen_ind);  
T = size(node_type_structure, 1);                            % T代表总的节点个数
% T2 = size(node_type_structure2, 1);
P = zeros(N - 1, 1);                % LLR internal buffer, exclude input LLR, each column for 1 list
C = zeros(N - 1, 2);                % judgment of each stage, 2 columns for left & right node of 1 list, exclude root node
u = zeros(1, N);                    % infomation bits buffer, each row for 1 list
dec_out_all = zeros(1, Kr);         % output all decoded bits, for debug
n = log2(N);

% % ----------------------------节点类型参数----------------------------% %
% for start_bit_idx = 1 : N
for i_node = 1 : T                                     
    start_bit_idx = node_type_structure(i_node, 1);          % 矩阵第一列代表起始比特的位置 
    M = node_type_structure(i_node, 2);                      % 矩阵第二列代表子节点长度
    type = node_type_structure(i_node, 3);                   % 矩阵第三列代表节点类型
%     reduced_layer = log2(M);                                

    % % ------------------------------参数设置------------------------------% %

    m = log2(M);                          
%     c_out_idx = 2^m : 2^(m + 1) - 1;    % output bits index of stage m, index is constant when m is fixed
    c_out_idx = M : 2 * M - 1;
    
    % % -----------------------------生成矩阵G------------------------------% %
    
    F = [1 0;1 1];
    G = F;
    j = 1;
    
    while j < m
        G = kron(F, G);
        j = j + 1;
    end
        
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
% % ---------------------------输出时钟周期数---------------------------% %
%         T_total = 0;        
%         T_fg = start_stage - stage;
%         clk_fg = 2^start_stage / 128;
%         disp(['clk_fg' num2str(clk_fg)])
%         disp(['T_fg' num2str(start_stage - stage)])
%         disp(['start_stage' num2str(start_stage)])
%         disp(['stage' num2str(stage)])
%         disp(['时钟周期 ' num2str(T_total)])
%         node_type_structure(i_node, 4) = T_fg;

    % % --------------------------按节点类型分别译码------------------------% %
 
        switch node_type_structure(i_node, 3)         
                case -1 % Rate-0
                        for i = 1 : M        
                            C(c_out_idx(i), 2 - c_idx) = 0;
                        end
                        u(1, dec_idx) = zeros(1, M);
                     %         T_rep = T_fg;
                    
                case 1 % Rate-1 
                        for i = 1 : M
                            if P(p_out_idx(i), 1) >= 0
                                C(c_out_idx(i), 2 - c_idx) = 0;
                            else
                                C(c_out_idx(i), 2 - c_idx) = 1;
                            end
                        end
                        u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)' * G, 2);
                     %         T_rep = T_hard + T_fg;

                 case 2 % Rep
                    sum_llr = 0;
                        for i = 1 : M                        
%                             sum_llr = sum_llr + P(p_out_idx(i), 1);            %对所有llr求和，和大于等于0，输出判为全0；否则判为全1
                            llrwidth = 8;
                            frac = 1;
                            isSign = 1;
                            P_fix = flt2fix(P(p_out_idx(i), 1),llrwidth,frac,isSign);
                            sum_llr = sum_llr + P_fix;
                        end
                            if sum_llr >= 0
    %                             C(c_out_idx(i), 2 - c_idx) = 0;
                                C(c_out_idx, 2 - c_idx) = zeros(M, 1);
                                u(1, dec_idx) = zeros(1, M);
                            else
    %                             C(c_out_idx(i), 2 - c_idx) = 1;
                                C(c_out_idx, 2 - c_idx) = ones(M, 1);
                                u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)' * G, 2); 
                            end
    %                         C(c_out_idx(i), 2 - c_idx) = rep_bit;
                        %         T_rep = T_sum + T_hard + T_fg;
  
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
                        u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)' * G, 2);
                    else                        
                         if mod(sum_x, 2) ~= 0                                 % 如果和不为0
                            alpha_abs = abs(llr_code);
                            [~, min_index] = min(alpha_abs);                  % 找到llr绝对值最小的比特位置
                            x(min_index) = mod(x(min_index) + 1, 2);          % 对该比特进行翻转                     
                            C(c_out_idx, 2 - c_idx) = x;
                            u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)' * G, 2);
                         end
                    end
                    %         T_spc = T_hard + T_parity + T_fg;

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
                    u(1, dec_idx) = mod(C(c_out_idx, 2 - c_idx)' * G, 2); 
        end
            
%             otherwise % 采用传统SC译码 如何确定比特位置？

%                     if node_type_structure1(i_node, 1) + node_type_structure1(i_node, 2) ~= node_type_structure1(i_node + 1, 1)
%                         bit_idx = find(i_node); % 非特殊节点比特的的起始位置
%                         bit_num = node_type_structure1(i_node + 1) - node_type_structure1(i_node, 1) + node_type_structure1(i_node, 2);
%                         M = 1;
%                         m = log2(M); 
%                         c_out_idx = 2^m : 2^(m + 1) - 1;    % output bits index of stage m, index is constant when m is fixed
%                     %     c_out_idx = M : 2 * M - 1;
%                         for start_bit_index = node_type_structure1(i_node, 1) + node_type_structure1(i_node, 2) : node_type_structure1(i_node + 1) - 1  
           
                
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
        if(frozen_ind(i) == 0)
            dec_out_all(1, cnt) = u(1, i); 
            cnt = cnt + 1;
        end
    end

% % ------------------------------CRC校验-------------------------------% %
    [cb_dec, cb_err] = CrcDecoder(dec_out_all(1, : ), CRC_type, Maskbits);     % CRC check, input row vector
end

