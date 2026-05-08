![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg)

#  Sky130 Self-Biased Miller OTA Unity-Gain Buffer

- [Read the documentation for project](docs/info.md)

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.

## Analog projects

For specifications and instructions, see the [analog specs page](https://tinytapeout.com/specs/analog/).

---

## Project Overview

This project features a **Unity-Gain Buffer** based on a **Two-Stage Miller OTA**, integrated with a **Beta-Multiplier Reference (BMR)** and a **Startup Circuit**, all implemented in the **Skywater 130nm (sky130)** PDK. 

### Performance Metrics (Simulated)
*   **Open-Loop Gain:** > 60 dB
*   **Phase Margin:** > 65 degrees
*   **Power Consumption:**
*       P_DiffPair:[7.72 µW]
*       P_BMR:[28 µW]
*       P_SecondStage:[127 µW]
*       P_Total:[162.72 µW]
*   **Slew Rate:** [18.65 V/µs]
*   **Target Load:** 3 pF
## Specifications

| Parameter          | Value             |
|--------------------|-------------------|
| Topology           | Miller OTA        |
| External Network   | Unity-gain Buffer |
| Input Resistance   | 25 KΩ             |
| Output Capacitance | 3 pF              |
| Input Range        | 0.4 V – 1 V       |
| Output Range       | 0.4 V – 1 V       |
| Settling Time      | 100 ns            |
| Settling Error     | 0.03 %            |

## Simulation Results

| Corner | Temp (°C) | Unity-Gain Frequency (Hz) | Phase Margin (°) |
|--------|:---------:|:-------------------------:|:----------------:|
| TT     | -27       | 13,098,400                | 67.11            |
| TT     | 25        | 11,107,500                | 67.36            |
| TT     | 125       | 8,208,920                 | 70.01            |
| SS     | -27       | 20,187,100                | 47.72            |
| SS     | 25        | 15,799,900                | 64.71            |
| SS     | 125       | 10,663,500                | 69.97            |
| FF     | -27       | 11,260,300                | 64.01            |
| FF     | 25        | 9,714,410                 | 65.09            |
| FF     | 125       | 6,840,200                 | 70.12            |

### Pinout Configuration
Please refer to the following analog pin assignments for testing:
*   **Analog Input ($V_{in1}$):** `[ua[0]]`
*   **Analog Output ($V_{out1}$):** `[ua[1]]`
*   **Analog Input ($V_{in2}$):** `[ua[2]]`
*   **Analog Output ($V_{out2}$):** `[ua[3]]`
---
## How it works
### 1. System Level: Gm-C Filter Architecture
Ultimately, the circuits implemented in this document serve as the foundational building blocks for a complete, continuous-time **Gm-C (Transconductor-Capacitor) Filter**. 

The Unity-Gain Miller OTA detailed below represents the first fully completed OTA block of this overarching system. A second OTA, which is required to finalize the filter topology, is currently in the active building stage. 

A central design strategy of this project is **shared biasing**. Once the second OTA is integrated, it will be driven by the exact same **Beta-Multiplier Reference (BMR)** developed here. Sharing a single, autonomous biasing network across multiple OTAs ensures matched transconductance ($g_m$) behavior, guarantees consistent performance across the chip, and drastically minimizes both total power consumption and silicon footprint on the TinyTapeout frame.

### 2. Unity-Gain Configuration & Core Performance
At its core, the Two-Stage Miller OTA provides a  **open-loop gain of over 60 dB**. To create the buffer configuration, the inverting input is directly hardwired to the output ($V_{out}$) in a strict negative feedback loop. This transforms the internal differential amplifier into a **single-input, single-output** voltage follower, carefully optimized across multiple performance axes:

*   **Precision Tracking:** The > 60 dB open-loop gain minimizes steady-state error, ensuring the closed-loop voltage gain is extremely close to unity ($A_v \approx 1$). The output accurately tracks the non-inverting input.
*   **Transient & Slew Performance:** The circuit is designed for fast large-signal response, achieving a strong simulated **Slew Rate of 18.65 V/µs**. This ensures rapid and accurate settling during sharp input transitions or pulse signals.
*   **Robust Load Drive & Stability:** The transconductance ($g_m$) of the second stage and the lead-compensation network are meticulously sized to stably drive a **3 pF capacitive load**. Under these load conditions, the buffer maintains a highly stable **Phase Margin of > 65 degrees**, completely preventing unwanted oscillations or ringing.
*   **Strategic Power Distribution:** The total power consumption is tightly controlled at **162.72 µW**. To achieve the high slew rate and drive the capacitive load effectively, the majority of the power is strategically allocated to the second stage (**127 µW**), while the differential pair (**7.72 µW**) and BMR (**28 µW**) operate with strict power efficiency.

### 3. Miller Compensation with Lead Resistor
Driving a 3 pF capacitive load in a unity-gain configuration represents the absolute worst-case scenario for amplifier stability. To achieve robust stability, we rely on a **Miller compensation network**, specifically enhanced with a **lead compensation** technique:

*   **Lead Compensation Strategy:** To neutralize this RHP zero while maintaining the crucial Miller pole-splitting effect, we added a "nulling resistor" in series with the Miller capacitor. This lead compensation breaks the high-frequency feedforward path. By carefully sizing this resistance, we force the RHP zero to infinity or move it into the Left-Half-Plane (LHP). This restores a healthy phase margin, ensuring the buffer remains completely stable without sustained ringing.
*   **Active MOS Resistor for Area & PVT Robustness:** In integrated circuit layout, large passive resistors consume a massive amount of valuable silicon real estate. Given the strict area boundaries of a TinyTapeout tile, using a traditional passive resistor for lead compensation was highly inefficient. Instead, we implemented this series resistance using an **active MOS transistor biased deep in the linear (triode) region**. Beyond drastically reducing the layout footprint, this active approach provides a crucial advantage for **PVT (Process, Voltage, and Temperature)** stability. The resistance of a passive poly-resistor varies completely independently of the amplifier's transconductance ($g_m$). In contrast, an active MOS resistor naturally tracks the $g_m$ shifts of the second-stage transistors across different temperature and process corners. This correlated tracking ensures that the RHP zero cancellation remains perfectly tuned and the phase margin stays stable under all operating conditions.

### 4.Beta-Multiplier Reference & Startup
The system is designed to be completely self-sufficient. It operates entirely without the need for any external current sources or off-chip biasing networks:

*   **Beta-Multiplier Reference (BMR):** The BMR functions as an autonomous, self-biasing current generator. It produces a highly stable internal reference current ($I_{ref}$), which ensures the OTA's transconductance ($g_m$) remains perfectly constant even in the presence of supply voltage ($V_{DD}$) fluctuations. Furthermore, this internal biasing architecture is highly efficient, operating with an ultra-low power consumption of approximately **28 µW**.
*   **Startup Circuit:** Because self-biased networks like the BMR inherently have two stable operating states (the desired active state and a degenerate "zero-current" state), a startup circuit is strictly necessary. This mechanism guarantees that upon power-up, the circuit is immediately forced out of the zero-current state and reliably driven to its target  operating point as the 1.8V power rail stabilizes.

The entire system is optimized for the **TinyTapeout** platform, focusing on stable analog performance and layout efficiency within the 1.8V domain.

## How to test

To verify the buffer's performance and stability:

*   **Load Setup:** Ensure a **3 pF capacitive load** is connected to the output pin (accounting for any parasitic capacitance from probes or traces).
*   **Pulse & Transient Test:** 
    *   Apply a pulse signal at the inpu1 pin (`ua[0]`) with an amplitude ranging from **0.4V to 1.0V**.
    *   Run a **1 µs transient test** to observe the slewing and settling behavior. 
    *   Verify that the output accurately follows the input without sustained ringing, confirming the 60+ dB precision and the stability of the compensation network under load.
*   **Power-Up Test:** Ramp the $V_{DD}$ from 0V to 1.8V to confirm the **Startup Circuit** successfully initializes the BMR.

<img width="1033" height="785" alt="WhatsApp Image 2026-05-01 at 13 29 02" src="https://github.com/user-attachments/assets/e1d0e36f-7625-4d95-aae4-c8f795522d02" />
<img width="1033" height="785" alt="WhatsApp Image 2026-05-01 at 13 29 03 (1)" src="https://github.com/user-attachments/assets/7fe7b2a9-32d3-41a3-b7db-87d4262ca146" />
<img width="1600" height="602" alt="WhatsApp Image 2026-05-01 at 13 29 03" src="https://github.com/user-attachments/assets/7d052c14-b5b4-4f8f-8544-771aeb7f46b6" />

## External hardware

To fully test this project on a physical bench, the following equipment is required:

*   **Signal Generator / Oscillator:** To provide the 0.4V - 1.0V pulse and AC input signals.
*   **DC Power Supply:** Stable 1.8V source for the VDD rail.
*   **Oscilloscope:** To simultaneously monitor the input and output waveforms, confirming tracking accuracy and settling time.
*   **Capacitor:** A discrete **3 pF capacitor** acting as the load.
*   **Multimeter:** For observing DC bias levels and verifying total current consumption.

---

## Enable GitHub actions to build the results page
- [Enabling GitHub Pages](https://tinytapeout.com/faq/#my-github-action-is-failing-on-the-pages-part)

## Acknowledgments

The architectural decisions, transistor sizing strategies, and overall design methodology for this Miller OTA were heavily guided by the principles outlined in **Analog Integrated Circuit Design by Simulation: Techniques, Tools, and Methods** by Prof. Uğur Çilingiroğlu. This book served as the foundational text for understanding the core mechanics of the circuit and is highly recommended to anyone diving into analog IC design.

## Resources

**Project References:**
- [Analog Integrated Circuit Design by Simulation: Techniques, Tools, and Methods](https://www.mheducation.com/highered/mhp/product/analog-integrated-circuit-design-simulation-techniques-tools-methods?pd=search&viewOption=student) - Uğur Çilingiroğlu
- [Design of Analog CMOS Integrated Circuits](https://www.mheducation.com/highered/product/design-analog-cmos-integrated-circuits-razavi/M9780072524932.html) - Behzad Razavi

**Tiny Tapeout Resources:**
- [FAQ](https://tinytapeout.com/faq/)
- [Digital design lessons](https://tinytapeout.com/digital_design/)
- [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
- [Join the community](https://tinytapeout.com/discord)

## What next?

- [Submit your design to the next shuttle](https://app.tinytapeout.com/).
- Share your project on your social network of choice:
  - LinkedIn [#tinytapeout](https://www.linkedin.com/search/results/content/?keywords=%23tinytapeout) [@TinyTapeout](https://www.linkedin.com/company/100708654/)
  - Mastodon [#tinytapeout](https://chaos.social/tags/tinytapeout) [@matthewvenn](https://chaos.social/@matthewvenn)
  - X (formerly Twitter) [#tinytapeout](https://twitter.com/hashtag/tinytapeout) [@tinytapeout](https://twitter.com/tinytapeout)
  - Bluesky [@tinytapeout.com](https://bsky.app/profile/tinytapeout.com)
