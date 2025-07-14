#!/bin/bash

# 检查是否以 root 权限运行
if [[ $EUID -ne 0 ]]; then
   echo "此脚本需要 root 权限，请使用 sudo 运行。"
   exit 1
fi

echo "--------------------------------------------------------"
echo "  Nmap 443 端口网段扫描器 V2"
echo "--------------------------------------------------------"

# 函数：验证 IPv4 CIDR 格式
# 参数: $1 - 要验证的字符串
# 返回: 0 表示有效，1 表示无效
validate_ipv4_cidr() {
    local ip_cidr="$1"
    # 正则表达式解释：
    # ^                 : 字符串开始
    # (25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9]) : 匹配 0-255 的数字 (IPv4 段)
    # (\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3} : 重复3次，形成完整IP
    # \/                : 匹配斜杠 '/'
    # ([1-2][0-9]|3[0-2]|[0-9]) : 匹配 0-32 的数字 (CIDR 位数)
    # $                 : 字符串结束
    if [[ "$ip_cidr" =~ ^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}/([1-2][0-9]|3[0-2]|[0-9])$ ]]; then
        return 0 # 有效
    else
        return 1 # 无效
    fi
}


# 循环提示用户输入网段，直到输入有效
while true; do
    read -p "请输入要扫描的网段 (示例: 43.159.64.0/18): " TARGET_NETWORK

    # 检查输入是否为空
    if [ -z "$TARGET_NETWORK" ]; then
        echo "未输入网段，请重新输入。"
        continue # 继续循环
    fi

    # 验证网段格式
    if validate_ipv4_cidr "$TARGET_NETWORK"; then
        echo "网段格式正确。"
        break # 退出循环
    else
        echo "网段格式不正确，请重新输入正确的 IPv4 CIDR 格式。"
    fi
done

# 移除网段中的斜杠和点，用于生成文件名
# sed 's/\//_/g' 将所有 / 替换为 _
# sed 's/\./-/g' 将所有 . 替换为 -
FILENAME_SUFFIX=$(echo "$TARGET_NETWORK" | sed 's/\//_/g' | sed 's/\./-/g')
OUTPUT_FILE="sc_${FILENAME_SUFFIX}.txt"
GNMAP_FILE="temp_scan_results.gnmap" # 临时文件，用于grep处理

echo "--------------------------------------------------------"
echo "正在为网段 '$TARGET_NETWORK' 扫描 443 端口..."
echo "扫描结果将保存到: '$OUTPUT_FILE' (如果存在开放端口)"
echo "--------------------------------------------------------"

# 执行 Nmap 扫描
sudo nmap -p 443 -sS -T4 --open -oG "$GNMAP_FILE" "$TARGET_NETWORK"

# 检查 Nmap 是否成功执行
if [ $? -ne 0 ]; then
    echo "Nmap 扫描过程中可能发生错误。请检查您的网络连接或 Nmap 安装。"
    rm -f "$GNMAP_FILE" # 删除临时文件
    exit 1
fi

echo "--------------------------------------------------------"
echo "Nmap 扫描完成。正在提取开放 443 端口的 IP 地址..."
echo "--------------------------------------------------------"

# 从 Grepable 文件中提取开放 443 端口的 IP 地址到临时结果文件
TEMP_RESULTS="temp_open_ips.txt"
cat "$GNMAP_FILE" | grep "Host:" | grep "Ports: 443/open/tcp" | awk '{print $2}' > "$TEMP_RESULTS"

# 检查 TEMP_RESULTS 文件是否为空
if [ -s "$TEMP_RESULTS" ]; then
    # 如果不为空，则将内容移动到最终的 OUTPUT_FILE
    mv "$TEMP_RESULTS" "$OUTPUT_FILE"
    echo "--------------------------------------------------------"
    echo "已找到以下 IP 地址开放 443 端口，并已保存到 '$OUTPUT_FILE'："
    cat "$OUTPUT_FILE"
    echo "--------------------------------------------------------"
else
    # 如果为空，则不生成 OUTPUT_FILE
    echo "--------------------------------------------------------"
    echo "在 '$TARGET_NETWORK' 网段中未找到开放 443 端口的 IP 地址。"
    echo "因此，未生成结果文件 '$OUTPUT_FILE'。"
    echo "--------------------------------------------------------"
fi

# 清理临时文件
rm -f "$GNMAP_FILE"
rm -f "$TEMP_RESULTS" # 确保临时结果文件也被删除

echo "--------------------------------------------------------"
echo "脚本执行完毕。"
echo "--------------------------------------------------------"
