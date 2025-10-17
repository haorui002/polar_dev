function  SSC_identify_node(frozen_ind, z)
% 
% 函数功能:
%          识别节点类型：R0、R1、Rep、SPC、type-III，并且把节点长度限制在[4,128]
N = length(frozen_ind);
% while (4 <= N) && (N <= 128)
global code_structure cnt_structure
if N > 128
    SSC_identify_node(frozen_ind(1 : N/2), z(1 : N/2));
    SSC_identify_node(frozen_ind(N/2 + 1 : end), z(N/2 + 1 : end));

    else
        if all(frozen_ind(1 : end - 1) == 1) && (frozen_ind(end) == 0)      % Rep节点
            code_structure(cnt_structure, 1) = z(1);
            code_structure(cnt_structure, 2) = N;
            code_structure(cnt_structure, 3) = 2;
            cnt_structure = cnt_structure + 1;   
        else
            if all(frozen_ind(1 : 2) == 1) && all(frozen_ind(3 : end) == 0)  % type-III节点      
                code_structure(cnt_structure, 1) = z(1);
                code_structure(cnt_structure, 2) = N;
                code_structure(cnt_structure, 3) = 4;
                cnt_structure = cnt_structure + 1;
        else
            if (frozen_ind(1) == 1) && all(frozen_ind(2 : end) == 0)        % SPC节点
                code_structure(cnt_structure, 1) = z(1);
                code_structure(cnt_structure, 2) = N;
                code_structure(cnt_structure, 3) = 3;
                cnt_structure = cnt_structure + 1;                
            else
                if all(frozen_ind == 0)                                                 % Rate-1节点
                   code_structure(cnt_structure, 1) = z(1);
                   code_structure(cnt_structure, 2) = N;
                   code_structure(cnt_structure, 3) = 1;
                   cnt_structure = cnt_structure + 1;
                else
                    if all(frozen_ind == 1)
                    code_structure(cnt_structure, 1) = z(1);                                % Rate-0节点
                    code_structure(cnt_structure, 2) = N;       
                    code_structure(cnt_structure, 3) = -1;
                    cnt_structure = cnt_structure + 1;
                    else
                         
                                if N > 4
                                    SSC_identify_node(frozen_ind(1 : N/2), z(1 : N/2));
                                    SSC_identify_node(frozen_ind(N/2 + 1 : end), z(N/2 + 1 : end));
                                else
                                    % need to change
                                    % SSC_identify_node(frozen_ind(1 : N/2), z(1 : N/2));
                                    % SSC_identify_node(frozen_ind(N/2 + 1 : end), z(N/2 + 1 : end));

                                end
                    end
                end

            end
            end
        end
end
end



     
    

