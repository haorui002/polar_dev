
def process_bit_file(input_file, output_file):
    """
    处理比特文件，将每8行从下到上转换为16进制字节
    :param input_file: 输入比特文件路径
    :param output_file: 输出16进制文件路径
    """
    try:
        with open(input_file, 'r') as f:
            bits = [line.strip() for line in f if line.strip()]
        
        hex_bytes = []
        # 从最后一行开始处理，每8行一组
        for i in range(len(bits), 0, -8):
            start = max(0, i-8)
            byte_bits = bits[start:i]
            # 不足8位补0
            while len(byte_bits) < 8:
                byte_bits.insert(0, '0')
            # 从下到上组合并转换为16进制
            byte_str = ''.join(reversed(byte_bits))
            hex_byte = f"{int(byte_str, 2):02x}"
            hex_bytes.append(hex_byte)
        
        # 反转结果使顺序正确
        hex_bytes.reverse()
        
        with open(output_file, 'w') as f:
            f.write(' '.join(hex_bytes))
        
        print(f"转换完成，结果保存在 {output_file}")
    
    except Exception as e:
        print(f"处理文件时出错: {e}")

if __name__ == "__main__":
    input_path = input("请输入输入文件路径: ")
    output_path = input("请输入输出文件路径: ")
    process_bit_file(input_path, output_path)
