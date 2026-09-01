# NavQ95 (MR-NAVQ95B, i.MX95) - Generated Frequencies

Source: live clock tree read from the running board at `user@192.168.2.144`
via `/sys/kernel/debug/clk/clk_summary`. Cross-referenced against the static
`assigned-clock-rates` in `arch/arm64/boot/dts/freescale/imx95-navqb.dts`.

Rates are as reported by the kernel Clock Framework (actual/live rates).

## Root oscillators / reference sources

| Clock            | Rate          |
|------------------|---------------|
| osc24m / osc_24m | 24.000 MHz    |
| cam24m           | 24.000 MHz    |
| osc32k           | 32.768 kHz    |
| ext1 / ext       | 25.000 MHz    |
| clk_ext1         | 133.000 MHz   |
| clk_sys100m      | 100.000 MHz   |
| fro              | 256.000 MHz   |

## PLLs and their outputs

| PLL / output     | Rate          |
|------------------|---------------|
| syspll1_vco      | 4.000 GHz     |
| syspll1_pfd0     | 1.000 GHz     |
| syspll1_pfd0_di  | 500.000 MHz   |
| syspll1_pfd1     | 800.000 MHz   |
| syspll1_pfd1_di  | 400.000 MHz   |
| syspll1_pfd2     | 666.667 MHz   |
| syspll1_pfd2_di  | 333.333 MHz   |
| armpll_vco       | 3.600 GHz     |
| armpll_pfd0      | 1.800 GHz     |
| armpll_pfd1      | 1.800 GHz     |
| armpll_pfd2      | 1.800 GHz     |
| armpll_pfd3      | 1.500 GHz     |
| drampll_vco      | 4.800 GHz     |
| drampll          | 800.000 MHz   |
| hsiopll_vco      | 3.600 GHz     |
| hsiopll          | 100.000 MHz   |
| videopll1_vco    | 3.000 GHz     |
| videopll1        | 333.333 MHz   |
| audiopll1_vco    | 3.932160 GHz  |
| audiopll1        | 393.216 MHz   |
| audiopll2_vco    | 3.612672 GHz  |
| audiopll2        | 361.267 MHz   |
| ldbpll_vco       | 4.800 GHz     |
| ldbpll           | 2.400 GHz     |
| ldb_phy_div      | 2.400 GHz     |
| ldb_pll_div7     | 342.857 MHz   |

## Core / SoC domain clocks

| Clock            | Rate          |
|------------------|---------------|
| a55 (cores)      | 500.000 MHz   |
| a55c0..c5 sel    | 1.800 GHz     |
| a55p sel         | 1.500 GHz     |
| a55periph        | 333.333 MHz   |
| m7               | 800.000 MHz   |
| m33              | 333.333 MHz   |
| gpu / gpu_cgc    | 1.000 GHz     |
| npu              | 1.000 GHz     |
| vpu              | 666.667 MHz   |
| vpujpeg          | 500.000 MHz   |
| noc              | 800.000 MHz   |
| dram_gpr_sel     | 800.000 MHz   |
| dramapb          | 266.667 MHz   |

## Peripheral clocks

| Clock            | Rate          | Consumer                    |
|------------------|---------------|-----------------------------|
| sai2 (mclk1)     | 12.288 MHz    | 4c880000.sai                |
| disp1pix (pix)   | 333.333 MHz   | display-controller          |
| dispaxi          | 800.000 MHz   | display-controller axi      |
| dispocram        | 400.000 MHz   | display-controller ocram    |
| dispapb          | 133.333 MHz   | display-controller apb      |
| flexspi1         | 200.000 MHz   |                             |
| usdhc1/2/3       | 400.000 MHz   | mmc controllers             |
| wakeupaxi        | 400.000 MHz   | mmc ahb                     |
| enet             | 666.667 MHz   | system-controller ipg       |
| enetref          | 250.000 MHz   | ENETC ref                   |
| can1 (per)       | 40.000 MHz    | 443a0000.can                |
| can2 / can3      | 80.000 MHz    |                             |
| lpspi1 / lpspi2  | 50.000 MHz    |                             |
| lpspi4 (per)     | 24.000 MHz    | 42560000.spi                |
| adc              | 80.000 MHz    |                             |
| hsio             | 500.000 MHz   | pcie / usb                  |
| hsiopcieaux      | 10.000 MHz    | pcie                        |
| camaxi           | 800.000 MHz   |                             |
| camisi           | 666.667 MHz   | isi                         |
| camcm0           | 400.000 MHz   |                             |
| camapb           | 133.333 MHz   | csi / syscon                |
| ele              | 250.000 MHz   |                             |
| v2xpk            | 800.000 MHz   |                             |
| swotrace         | 133.333 MHz   |                             |
| various *apb/bus | 133.333 MHz   | buswakeup, busaon, etc.     |

## Clocks parented to 24 MHz osc (not divided, run at 24 MHz)

Many low-speed peripherals are currently sourced directly from the 24 MHz
oscillator and thus report 24.000 MHz: all lpuartN, lpi2cN, lpspiN (3,5-8),
tpmN, saiN (1,3,4,5), i3c1/i3c2, canN (4,5), spdif, pdm, mqs1/2, tmu, and the
various test/monitor clocks (enetphytest*, hsio*test*, hsioacscan*, etc.).

## Cross-check vs device tree (imx95-navqb.dts)

The board's static `assigned-clock-rates` match the live values exactly:

- SAI2 tree: audiopll1_vco 3.932160 GHz, audiopll2_vco 3.612672 GHz,
  audiopll1 393.216 MHz, audiopll2 361.267 MHz, sai2 12.288 MHz.
- DPU tree: videopll1_vco 3.000 GHz, videopll1 333.333 MHz.
- Fixed 24 MHz oscillator (cam24m).
