function node_type_structure = SSC_get_node_structure(frozen_ind)
% % -----------------------------------------------------------------------
% 该函数功能是得到节点类型矩阵
% frozen_ind：冻结比特索引
% node_type_structure：节点类型矩阵

% % -----------------------------------------------------------------------
global code_structure cnt_structure
code_structure = zeros(length(frozen_ind), 3);
cnt_structure = 1;
SSC_identify_node(frozen_ind, 1 : length(frozen_ind));
code_structure = code_structure(code_structure ~= 0);
code_structure = reshape(code_structure', length(code_structure)/3, 3);
% code_structure = code_structure(1 : cnt_structure, :);
node_type_structure = code_structure;
clear global;
end