import scipy.io
import numpy as np

# 读取 .mat 文件中的向量 b
mat = scipy.io.loadmat('data.mat')
b = mat['b'].flatten()  # 保证是一维数组

assert len(b) == 1024, "数据长度应为1024"

# 检查是否为整数类型，不是则先取整并转为uint16
if not np.issubdtype(b.dtype, np.integer):
    b = np.round(b).astype(np.uint16)
else:
    b = b.astype(np.uint16)

# 创建并写入 8 个 txt 文件
for i in range(1, 9):  # i from 1 to 8
    with open(f'Weight_1024_{i}.txt', 'w') as f:
        for j in range(1, 9):  # j from 1 to 8
            start = 1 + 16 * (i - 1) + 128 * (j - 1) - 1  # Python索引从0开始
            end = start + 16
            segment = b[start:end]
            # 逆序
            segment = segment[::-1]
            hex_line = ''.join([f'{val:03X}' for val in segment])  # 3位十六进制，大写，无间隔
            f.write(hex_line + '\n')
            

    print(f'Weight_1024_{i}.txt has been written successfully.')
