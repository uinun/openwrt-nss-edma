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

# 2. 注入内核底层 PWM 及 Fan 支持，并显式关闭因开启 PWM 而暴露出的 7.3 内核新驱动提示
if [ -f "$TARGET_CONF" ]; then
    echo "[INFO] Injecting PWM and Fan configs into $TARGET_CONF"
    sed -i -E '/CONFIG_(PWM|PWM_SYSFS|PWM_GPIO|HWMON|SENSORS_PWM_FAN|THERMAL_HWMON|LTC2378|PWM_CLK|REGULATOR_PWM)/d' "$TARGET_CONF"
    cat << 'EOF' >> "$TARGET_CONF"
CONFIG_PWM=y
CONFIG_PWM_SYSFS=y
CONFIG_PWM_GPIO=y
CONFIG_HWMON=y
CONFIG_SENSORS_PWM_FAN=y
CONFIG_THERMAL_HWMON=y
# CONFIG_LEDS_QCOM_LPG is not set
# CONFIG_PWM_IPQ is not set
# CONFIG_PWM_CLK is not set
# CONFIG_REGULATOR_PWM is not set
# CONFIG_LTC2378 is not set
EOF
    echo "[INFO] Successfully injected configs."
else
    echo "[ERROR] $TARGET_CONF not found!"
    exit 1
fi

# 3. 兜底防护：如果 linux-7.3 还有其他未声明的新符号，允许 syncconfig 自动取默认值而不报错中断
KERNEL_MK="${GITHUB_WORKSPACE}/${OPENWRT_DIR}/include/kernel-defaults.mk"
[ ! -f "$KERNEL_MK" ] && KERNEL_MK="include/kernel-defaults.mk"
if [ -f "$KERNEL_MK" ]; then
    sed -i 's/syncconfig/olddefconfig/g' "$KERNEL_MK" 2>/dev/null || true
fi