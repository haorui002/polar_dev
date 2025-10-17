
% 方法1：递归构造
function H = recursive_hadamard(n)
    if n == 1
        H = 1;
    else
        H_prev = recursive_hadamard(n/2);
        H = [H_prev H_prev; H_prev -H_prev];
    end
end
H1 = recursive_hadamard(128);

% 方法2：内置函数
H2 = hadamard(128); 

% 验证正交性
disp(norm(H1*H1' - 128*eye(128)));  % 应接近0
disp(norm(H2*H2' - 128*eye(128)));  % 应接近0
