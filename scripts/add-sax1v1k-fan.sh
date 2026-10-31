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
		gpios = <&tlmm 27 GPIO_ACTIVE_HIGH>;
	};

	fan: pwm-fan {
		compatible = "pwm-fan";
		pwms = <&fan_pwm 0 1000000 0>;
		/* 0: 停转, 1: 25%, 2: 50%, 3: 75% */
		cooling-levels = <0 64 128 191>;
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

&cpu0_thermal {
	trips {
		cpu0_fan_low: fan-low { temperature = <73000>; hysteresis = <6000>; type = "active"; };
		cpu0_fan_high: fan-high { temperature = <80000>; hysteresis = <3000>; type = "active"; };
		cpu0_fan_max: fan-max { temperature = <90000>; hysteresis = <3000>; type = "active"; };
	};
	cooling-maps {
		fan-active-low { trip = <&cpu0_fan_low>; cooling-device = <&fan 1 1>; };
		fan-active-high { trip = <&cpu0_fan_high>; cooling-device = <&fan 2 2>; };
		fan-active-max { trip = <&cpu0_fan_max>; cooling-device = <&fan 3 3>; };
	};
};

&cpu1_thermal {
	trips {
		cpu1_fan_low: fan-low { temperature = <73000>; hysteresis = <6000>; type = "active"; };
		cpu1_fan_high: fan-high { temperature = <80000>; hysteresis = <3000>; type = "active"; };
		cpu1_fan_max: fan-max { temperature = <90000>; hysteresis = <3000>; type = "active"; };
	};
	cooling-maps {
		fan-active-low { trip = <&cpu1_fan_low>; cooling-device = <&fan 1 1>; };
		fan-active-high { trip = <&cpu1_fan_high>; cooling-device = <&fan 2 2>; };
		fan-active-max { trip = <&cpu1_fan_max>; cooling-device = <&fan 3 3>; };
	};
};

&cpu2_thermal {
	trips {
		cpu2_fan_low: fan-low { temperature = <73000>; hysteresis = <6000>; type = "active"; };
		cpu2_fan_high: fan-high { temperature = <80000>; hysteresis = <3000>; type = "active"; };
		cpu2_fan_max: fan-max { temperature = <90000>; hysteresis = <3000>; type = "active"; };
	};
	cooling-maps {
		fan-active-low { trip = <&cpu2_fan_low>; cooling-device = <&fan 1 1>; };
		fan-active-high { trip = <&cpu2_fan_high>; cooling-device = <&fan 2 2>; };
		fan-active-max { trip = <&cpu2_fan_max>; cooling-device = <&fan 3 3>; };
	};
};

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

&cluster_thermal {
	trips {
		cluster_fan_low: fan-low { temperature = <73000>; hysteresis = <6000>; type = "active"; };
		cluster_fan_high: fan-high { temperature = <80000>; hysteresis = <3000>; type = "active"; };
		cluster_fan_max: fan-max { temperature = <90000>; hysteresis = <3000>; type = "active"; };
	};
	cooling-maps {
		fan-active-low { trip = <&cluster_fan_low>; cooling-device = <&fan 1 1>; };
		fan-active-high { trip = <&cluster_fan_high>; cooling-device = <&fan 2 2>; };
		fan-active-max { trip = <&cluster_fan_max>; cooling-device = <&fan 3 3>; };
	};
};
EOF

echo "::notice:: 风扇控制代码成功注入到 $DTS_FILE！"