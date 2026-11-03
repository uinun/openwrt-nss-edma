#!/bin/bash
# 自动查找 sax1v1k 的 DTS 文件（兼容不同的命名和路径层级）
DTS_FILE=$(find target/linux/qualcommax/ -type f -name "*sax1v1k*.dts" | head -n 1)

if [ -z "$DTS_FILE" ] || [ ! -f "$DTS_FILE" ]; then
    echo "::warning:: 未找到 sax1v1k DTS 文件，跳过风扇配置注入！"
    exit 0
fi

# 检查是否已经注入过，防止重复构建时多次追加
if grep -q "fan_pwm: pwm" "$DTS_FILE"; then
    echo "::notice:: $DTS_FILE 中已存在风扇控制代码，无需重复追加。"
    exit 0
fi

echo "正在向 $DTS_FILE 追加风扇控制代码..."

cat << 'EOF' >> "$DTS_FILE"

/ {
	fan_pwm: pwm {
		compatible = "pwm-gpio";
		#pwm-cells = <3>;
		pinctrl-0 = <&fan_pwm_pins>;
		pinctrl-names = "default";
		gpios = <&tlmm 27 0>;
	};

	fan: pwm-fan {
		compatible = "pwm-fan";
		pwms = <&fan_pwm 0 1000000 0>;
		/* 0: 停转, 1: 30%, 2: 50%, 3: 75% */
		cooling-levels = <0 80 128 191>;
		#cooling-cells = <2>;
		interrupt-parent = <&tlmm>;
		interrupts = <29 2>;
		pulses-per-revolution = <2>;
		pinctrl-0 = <&fan_tach_pins>;
		pinctrl-names = "default";
	};
};

&tlmm {
	fan_pwm_pins: fan-pwm-state {
		pins = "gpio27";
		function = "gpio";
		drive-strength = <8>;
		bias-disable;
		output-high;
	};

	fan_tach_pins: fan-tach-state {
		pins = "gpio29";
		function = "gpio";
		drive-strength = <2>;
		bias-pull-up;
	};
};

/* 1. CPU 监测点：CPU 核心 3 */
&cpu3_thermal {
	trips {
		cpu3_fan_low: fan-low { temperature = <73000>; hysteresis = <6000>; type = "active"; };
		cpu3_fan_high: fan-high { temperature = <80000>; hysteresis = <3000>; type = "active"; };
		cpu3_fan_max: fan-max { temperature = <90000>; hysteresis = <3000>; type = "active"; };
	};
	cooling-maps {
		fan-active-low { trip = <&cpu3_fan_low>; cooling-device = <&fan 1 1>; };
		fan-active-high { trip = <&cpu3_fan_high>; cooling-device = <&fan 2 2>; };
		fan-active-max { trip = <&cpu3_fan_max>; cooling-device = <&fan 3 3>; };
	};
};

/* 2. NSS 网络加速引擎监测点：NSS Core 0 */
&nss0_thermal {
	trips {
		nss0_fan_low: fan-low { temperature = <73000>; hysteresis = <6000>; type = "active"; };
		nss0_fan_high: fan-high { temperature = <80000>; hysteresis = <3000>; type = "active"; };
		nss0_fan_max: fan-max { temperature = <90000>; hysteresis = <3000>; type = "active"; };
	};
	cooling-maps {
		fan-active-low { trip = <&nss0_fan_low>; cooling-device = <&fan 1 1>; };
		fan-active-high { trip = <&nss0_fan_high>; cooling-device = <&fan 2 2>; };
		fan-active-max { trip = <&nss0_fan_max>; cooling-device = <&fan 3 3>; };
	};
};

/* 3. 无线射频基带监测点：WCSS 5G 物理层 (对应 ath11k 射频高热区域) */
&wcss_phyb0_thermal {
	trips {
		wcss_fan_low: fan-low { temperature = <73000>; hysteresis = <6000>; type = "active"; };
		wcss_fan_high: fan-high { temperature = <80000>; hysteresis = <3000>; type = "active"; };
		wcss_fan_max: fan-max { temperature = <90000>; hysteresis = <3000>; type = "active"; };
	};
	cooling-maps {
		fan-active-low { trip = <&wcss_fan_low>; cooling-device = <&fan 1 1>; };
		fan-active-high { trip = <&wcss_fan_high>; cooling-device = <&fan 2 2>; };
		fan-active-max { trip = <&wcss_fan_max>; cooling-device = <&fan 3 3>; };
	};
};

/* 4. 无线射频基带监测点：WCSS 2.4G 物理层 */
&wcss_phya0_thermal {
	trips {
		wcss_fan_low: fan-low { temperature = <73000>; hysteresis = <6000>; type = "active"; };
		wcss_fan_high: fan-high { temperature = <80000>; hysteresis = <3000>; type = "active"; };
		wcss_fan_max: fan-max { temperature = <90000>; hysteresis = <3000>; type = "active"; };
	};
	cooling-maps {
		fan-active-low { trip = <&wcss_fan_low>; cooling-device = <&fan 1 1>; };
		fan-active-high { trip = <&wcss_fan_high>; cooling-device = <&fan 2 2>; };
		fan-active-max { trip = <&wcss_fan_max>; cooling-device = <&fan 3 3>; };
	};
};
EOF

echo "::notice:: 风扇控制代码成功注入到 $DTS_FILE！"