function [cb_dec, cb_err] = PolarDecode_New_SSC(llrMat, info, polarIdx, Maskbits, encPara)
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
global file_out1
global file_out2


N = encPara(2);
Kr = encPara(1);
K = encPara(1)-info.crcLen;
% CRC_len = info.crcLen;
numCB = size(llrMat, 1);
if numCB==1 && sum(info.CBG)==1
    % 只解码1个CB的时候(numCB=1)，若sum(info.CBG)~=1，即该CB用24B解校验，若sum(info.CBG)=1，用crcType解校验
    CRC_type = info.crcType;
else
    CRC_type = '24B';
end

frozen_ind = zeros(1, N);
frozen_ind(polarIdx.frozen_bits) = 1;

dec_out_all = zeros(1, Kr, numCB);
%PM_sort = zeros(numCB, 1);
cb_dec = zeros(numCB, K);
cb_err = zeros(numCB, 1);
%list_ind = zeros(numCB, 1);
% PM_esti = zeros(numCB, 1);
node_type_structure = SSC_get_node_structure(frozen_ind);   
% node_type_structure1 = get_node_structure(frozen_ind);
% node_type_structure2 = New_SSC_get_node_structure(frozen_ind); % 两种不同的分类方式
for iCB = 1 : numCB
    [dec_out_all(:, :, iCB), cb_dec(iCB, :), cb_err(iCB)] = ...
        newSSC_decoder(llrMat(iCB, :), N, Kr, node_type_structure, frozen_ind, CRC_type, Maskbits);
end

end