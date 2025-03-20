#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/t3rn-bot.sh"

# 定义仓库地址和目录名称
REPO_URL="https://github.com/0xqianyi30/t3rn-bot.git"
DIR_NAME="t3rn-bot"
PYTHON_FILE="keys_and_addresses.py"
DATA_BRIDGE_FILE="data_bridge.py"
BOT_FILE="bot.py"
VENV_DIR="t3rn-env"  # 虚拟环境目录

# 日志文件
LOG_FILE="$HOME/t3rn-bot-install.log"

# 记录日志的函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查命令是否成功的函数
check_error() {
    if [ $? -ne 0 ]; then
        log "错误: $1"
        echo "错误: $1"
        exit 1
    fi
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 执行t3rn跨链脚本"
        echo "2. 退出"
        
        read -p "请输入选项 (1/2): " option
        case $option in
            1)
                execute_cross_chain_script
                ;;
            2)
                log "用户选择退出脚本。"
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效选项，请重新选择。"
                sleep 2
                ;;
        esac
    done
}

# 验证 Input Data 格式的函数
validate_input_data() {
    local input_data=$1
    # Input Data 应以 0x 开头，后面跟十六进制字符（长度不固定）
    if [[ ! "$input_data" =~ ^0x[0-9a-fA-F]+$ ]]; then
        log "错误: Input Data 格式不正确，应为 0x 开头的十六进制字符串。"
        echo "错误: Input Data 格式不正确，应为 0x 开头的十六进制字符串。"
        return 1
    fi
    return 0
}

# 执行跨链脚本
function execute_cross_chain_script() {
    # 不强制要求 root 用户运行，但需要确保有权限
    log "当前用户: $(whoami)"

    # 检查是否安装了 git
    if ! command -v git &> /dev/null; then
        log "Git 未安装，正在安装 Git..."
        echo "Git 未安装，正在安装 Git..."
        sudo apt update
        sudo apt install -y git
        check_error "安装 Git 失败"
    fi

    # 检查是否安装了 python3 和 python3-pip
    if ! command -v python3 &> /dev/null; then
        log "Python3 未安装，正在安装 python3..."
        echo "Python3 未安装，正在安装 python3..."
        sudo apt update
        sudo apt install -y python3
        check_error "安装 Python3 失败"
    fi

    if ! command -v pip3 &> /dev/null; then
        log "pip3 未安装，正在安装 python3-pip..."
        echo "pip3 未安装，正在安装 python3-pip..."
        sudo apt update
        sudo apt install -y python3-pip
        check_error "安装 python3-pip 失败"
    fi

    # 检查 Python 版本（需要 3.6+）
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
    PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
    if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 6 ]; }; then
        log "错误: Python 版本过低（$PYTHON_VERSION），需要 3.6 或以上版本。"
        echo "错误: Python 版本过低（$PYTHON_VERSION），需要 3.6 或以上版本。"
        exit 1
    fi
    log "Python 版本: $PYTHON_VERSION"

    # 提取 Python 次版本（例如 3.8）
    PYTHON_SUBVERSION="$PYTHON_MAJOR.$PYTHON_MINOR"

    # 检查是否安装了 python3.x-venv（例如 python3.8-venv）
    VENV_PACKAGE="python$PYTHON_SUBVERSION-venv"
    if ! dpkg -l | grep -q "$VENV_PACKAGE"; then
        log "$VENV_PACKAGE 未安装，正在安装 $VENV_PACKAGE..."
        echo "$VENV_PACKAGE 未安装，正在安装 $VENV_PACKAGE..."
        sudo apt update
        sudo apt install -y "$VENV_PACKAGE"
        check_error "安装 $VENV_PACKAGE 失败"
    fi

    # 检查 ensurepip 是否可用
    if ! python3 -m ensurepip --version &> /dev/null; then
        log "错误: ensurepip 不可用，请确保 $VENV_PACKAGE 已正确安装。"
        echo "错误: ensurepip 不可用，请确保 $VENV_PACKAGE 已正确安装。"
        echo "尝试手动安装 $VENV_PACKAGE："
        echo "  sudo apt update"
        echo "  sudo apt install -y $VENV_PACKAGE"
        echo "如果问题仍未解决，请尝试重新安装 Python："
        echo "  sudo apt install -y python$PYTHON_SUBVERSION python$PYTHON_SUBVERSION-venv python$PYTHON_SUBVERSION-dev"
        exit 1
    fi
    log "ensurepip 已正确安装"

    # 拉取仓库
    if [ -d "$DIR_NAME" ]; then
        log "目录 $DIR_NAME 已存在，拉取最新更新..."
        echo "目录 $DIR_NAME 已存在，拉取最新更新..."
        cd "$DIR_NAME" || exit
        git pull origin main
        check_error "拉取仓库更新失败"
    else
        log "正在克隆仓库 $REPO_URL..."
        echo "正在克隆仓库 $REPO_URL..."
        git clone "$REPO_URL"
        check_error "克隆仓库失败"
        cd "$DIR_NAME" || exit
    fi

    log "已进入目录 $DIR_NAME"
    echo "已进入目录 $DIR_NAME"

    # 删除旧的虚拟环境（如果存在）
    if [ -d "$VENV_DIR" ]; then
        log "删除旧的虚拟环境 $VENV_DIR..."
        echo "删除旧的虚拟环境 $VENV_DIR..."
        rm -rf "$VENV_DIR"
        check_error "删除旧虚拟环境失败"
    fi

    # 创建虚拟环境
    log "正在创建虚拟环境 $VENV_DIR..."
    echo "正在创建虚拟环境 $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    check_error "创建虚拟环境失败"

    # 检查 activate 文件是否存在
    if [ ! -f "$VENV_DIR/bin/activate" ]; then
        log "错误: 虚拟环境创建失败，$VENV_DIR/bin/activate 文件不存在。"
        echo "错误: 虚拟环境创建失败，$VENV_DIR/bin/activate 文件不存在。"
        exit 1
    fi

    # 激活虚拟环境
    log "激活虚拟环境 $VENV_DIR..."
    echo "激活虚拟环境 $VENV_DIR..."
    source "$VENV_DIR/bin/activate"
    check_error "激活虚拟环境失败"

    # 确认虚拟环境中的 pip 路径
    PIP_PATH=$(which pip)
    log "当前 pip 路径: $PIP_PATH"
    echo "当前 pip 路径: $PIP_PATH"
    if [[ "$PIP_PATH" != *"$VENV_DIR"* ]]; then
        log "错误: 虚拟环境未正确激活，pip 路径不正确。"
        echo "错误: 虚拟环境未正确激活，pip 路径不正确。"
        exit 1
    fi

    # 升级 pip
    log "正在升级 pip..."
    echo "正在升级 pip..."
    pip install --upgrade pip
    check_error "升级 pip 失败"

    # 安装依赖
    log "正在安装依赖 web3 和 colorama..."
    echo "正在安装依赖 web3 和 colorama..."
    pip install web3 colorama
    check_error "安装依赖失败"

    # 确认依赖已安装
    if ! pip show web3 &> /dev/null || ! pip show colorama &> /dev/null; then
        log "错误: 依赖安装失败，请检查日志。"
        echo "错误: 依赖安装失败，请检查日志。"
        exit 1
    fi
    log "依赖安装成功: web3, colorama"

    # 提醒用户私钥安全
    echo "警告：请务必确保您的私钥安全！"
    echo "私钥应当保存在安全的位置，切勿公开分享或泄漏给他人。"
    echo "如果您的私钥被泄漏，可能导致您的资产丧失！"
    echo "请输入您的私钥，确保安全操作。"

    # 让用户输入私钥和标签
    echo "请输入您的私钥（多个私钥以空格分隔）："
    read -r private_keys_input

    echo "请输入您的标签（多个标签以空格分隔，与私钥顺序一致）："
    read -r labels_input

    # 检查输入是否一致
    IFS=' ' read -r -a private_keys <<< "$private_keys_input"
    IFS=' ' read -r -a labels <<< "$labels_input"

    if [ "${#private_keys[@]}" -ne "${#labels[@]}" ]; then
        log "错误: 私钥和标签数量不一致。"
        echo "私钥和标签数量不一致，请重新运行脚本并确保它们匹配！"
        exit 1
    fi

    # 验证私钥格式（简单检查，私钥应为 0x 开头的 64 位十六进制）
    for key in "${private_keys[@]}"; do
        if [[ ! "$key" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            log "错误: 私钥格式不正确: $key"
            echo "错误: 私钥格式不正确，应为 0x 开头的 64 位十六进制字符串。"
            exit 1
        fi
    done

    # 写入 keys_and_addresses.py 文件
    log "正在写入 $PYTHON_FILE 文件..."
    echo "正在写入 $PYTHON_FILE 文件..."
    cat > "$PYTHON_FILE" <<EOL
# 此文件由脚本生成

private_keys = [
$(printf "    '%s',\n" "${private_keys[@]}")
]

labels = [
$(printf "    '%s',\n" "${labels[@]}")
]
EOL
    check_error "写入 $PYTHON_FILE 文件失败"

    log "$PYTHON_FILE 文件已生成。"
    echo "$PYTHON_FILE 文件已生成。"

    # 提醒用户私钥安全
    echo "脚本执行完成！所有依赖已安装，私钥和标签已保存到 $PYTHON_FILE 中。"
    echo "请务必妥善保管此文件，避免泄露您的私钥和标签信息！"

    # 获取额外的用户输入："Arbitrum - OP Sepolia" 和 "OP - Arbitrum"
    while true; do
        echo "请输入 'Arbitrum - OP Sepolia' 的 Input Data（以 0x 开头的十六进制字符串，例如 0x2dc4edfc...）："
        echo "提示：您可以从 t3rn 文档、Etherscan 或其他工具中获取正确的 Input Data。"
        read -r arb_op_sepolia_value
        if validate_input_data "$arb_op_sepolia_value"; then
            break
        fi
        echo "请重新输入正确的 Input Data。"
    done

    while true; do
        echo "请输入 'OP - Arbitrum' 的 Input Data（以 0x 开头的十六进制字符串，例如 0x2dc4edfc...）："
        echo "提示：您可以从 t3rn 文档、Etherscan 或其他工具中获取正确的 Input Data。"
        read -r op_arb_value
        if validate_input_data "$op_arb_value"; then
            break
        fi
        echo "请重新输入正确的 Input Data。"
    done

    # 写入 data_bridge.py 文件
    log "正在写入 $DATA_BRIDGE_FILE 文件..."
    echo "正在写入 $DATA_BRIDGE_FILE 文件..."
    cat > "$DATA_BRIDGE_FILE" <<EOL
# 此文件由脚本生成

data_bridge = {
    # Data bridge Arbitrum
    "Arbitrum - OP Sepolia": "$arb_op_sepolia_value",

    # Data bridge OP Sepolia
    "OP - Arbitrum": "$op_arb_value",
}

# 提供 get 方法以兼容 bot.py 中的 data_bridge.get() 调用
def get(bridge):
    return data_bridge.get(bridge)
EOL
    check_error "写入 $DATA_BRIDGE_FILE 文件失败"

    log "$DATA_BRIDGE_FILE 文件已生成。"
    echo "$DATA_BRIDGE_FILE 文件已生成。"

    # 检查 screen 是否安装
    if ! command -v screen &> /dev/null; then
        log "screen 未安装，正在安装 screen..."
        echo "screen 未安装，正在安装 screen..."
        sudo apt update
        sudo apt install -y screen
        check_error "安装 screen 失败"
    fi

    # 提醒用户运行 bot.py
    log "配置完成，正在通过 screen 运行 bot.py..."
    echo "配置完成，正在通过 screen 运行 bot.py..."

    # 使用 screen 后台运行 bot.py
    screen -dmS t3rn python3 "$BOT_FILE"
    check_error "启动 bot.py 失败"

    # 输出信息
    log "bot.py 已在后台运行。"
    echo "bot.py 已在后台运行，您可以通过 'screen -r t3rn' 查看运行日志。"

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
