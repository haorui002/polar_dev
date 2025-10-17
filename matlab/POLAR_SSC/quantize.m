function dout = quantize(din, width, frac)
    if width == 0
        % 不量化，原样输出
        dout = din;
    else
        % 量化边界
        dMax = 2^(width - 1) - 1;
        dMin = -2^(width - 1);

        % 定义统一的量化与裁剪函数
        quant_clip = @(x) min(max(floor(x * 2^frac), dMin), dMax);
    
        dout = quant_clip(din);
    end
end
