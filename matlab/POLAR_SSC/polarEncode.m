function [enc_out] = polarEncode(N,K, enc_in, WQ_LIST)
    
%     if R == 0
%         K = 1024;
%         N = 4096;
%     else
%         K = 384;
%     end

    %% 索引计算
    % Generate Generation Matrix
    G = calGMatric(log2(N));

    reliability_seq = WQ_LIST(WQ_LIST(:,2)<N,:);
    info_indices = reliability_seq(end-K+1:end, 2) + 1;

    %% 码字构造
    enc_in_sorted = zeros(1, N);
    enc_in_sorted(1, sort(info_indices,'ascend')) = enc_in(:, 1);

    %% 编码
    enc_out = polar_butterfly_encode(enc_in_sorted);

end

function x = polar_butterfly_encode(u)
    N = length(u);
    n = log2(N);
    x = u(:).';  % 行向量
    for s = 1:n
        step = 2^s;
        for i = 1:step:N
            for j = 0:(step/2-1)
                x(i+j) = mod(x(i+j) + x(i+j+step/2), 2);
            end
        end
    end
end