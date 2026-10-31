#!/bin/bash
set -e

TARGET_CONF="${GITHUB_WORKSPACE}/${OPENWRT_DIR}/target/linux/qualcommax/ipq807x/config-default"
TARGET_MAKEFILE="${GITHUB_WORKSPACE}/${OPENWRT_DIR}/target/linux/qualcommax/Makefile"

# 兼容当前相对路径与绝对路径
if [ ! -f "$TARGET_CONF" ]; then
    TARGET_CONF="target/linux/qualcommax/ipq807x/config-default"
fi
if [ ! -f "$TARGET_MAKEFILE" ]; then
    TARGET_MAKEFILE="target/linux/qualcommax/Makefile"
fi

# 1. 确保 target 平台特性声明具备 pwm
if [ -f "$TARGET_MAKEFILE" ]; then
    if ! grep -q "FEATURES.*pwm" "$TARGET_MAKEFILE"; then
        echo "[INFO] Appending pwm to FEATURES in $TARGET_MAKEFILE"
        sed -i '/FEATURES+=/ s/$/ pwm/' "$TARGET_MAKEFILE" 2>/dev/null || true
    fi
fi

# 2. 注入内核底层 PWM 及 Fan 支持
if [ -f "$TARGET_CONF" ]; then
    echo "[INFO] Injecting PWM and Fan configs into $TARGET_CONF"
    sed -i -E '/CONFIG_(PWM|PWM_SYSFS|PWM_GPIO|HWMON|SENSORS_PWM_FAN|THERMAL_HWMON)/d' "$TARGET_CONF"
    cat << 'EOF' >> "$TARGET_CONF"
CONFIG_PWM=y
CONFIG_PWM_SYSFS=y
CONFIG_PWM_GPIO=y
CONFIG_HWMON=y
CONFIG_SENSORS_PWM_FAN=y
CONFIG_THERMAL_HWMON=y
# CONFIG_LEDS_QCOM_LPG is not set
# CONFIG_PWM_IPQ is not set
EOF
    echo "[INFO] Successfully injected configs."
else
    echo "[ERROR] $TARGET_CONF not found!"
    exit 1
fi