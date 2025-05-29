# 5G
https://www.mathworks.com/help/5g/ug/nr-prs-positioning.html



5G PRS + GNS3 定位系統

專案目標：把 MATLAB 的 5G PRS 定位演算法，透過位置引擎 REST 服務，整合進 GNS3 所建的 5G 網路拓樸，展示「近真實」的 TOA/TDOA 定位流程。
在 GNS3 搭建的小型 5G 網路（3 gNB + Open5GS Core）上，
透過 MATLAB 產生並分析 PRS 量測，將 TDOA 量測資料送至「位置引擎伺服器」(Flask)，
回傳 UE 座標並在 MATLAB GUI 即時顯示——打造「近真實」的 5G 定位全流程示範。


┌─────────┐  UDP/TCP   ┌──────────────────┐
│ MATLAB  │──────────▶│  位置引擎容器      │
│ PRS 模擬│            │  (Python/Node)    │
└─────────┘            └────────┬─────────┘
                               │REST / gRPC
                               ▼
          ┌──────────────────────────────┐
          │ GNS3 拓撲 (Docker/VM/IOU)    │
          │ ┌─────┐  ┌─────┐  ┌───────┐ │
          │ │gNB0 │..│gNB1 │..│gNB2   │ │
          │ └─────┘  └─────┘  └───────┘ │
          │     │        │        │      │
          │    N2/N3   N2/N3   N2/N3    │
          │          (Open5GS CN)       │
          └──────────────────────────────┘

MATLAB UE 模擬器 ue_control_ui.m





  TOA → TDOA 模式已可隨 UE 位置即時定位。

  支援 15/30/60 kHz 三頻段、SNR/MIMO 調整。

TDOA 解算器 locateByTDOA.m

待完成
MATLAB refresh_rx → Flask POST  :Cindy
Flask /solve → 回傳 pos

補上 locateByTDOA Numpy 版 + Error handling Paul

誤差統計報告 SNR Sweep、多徑模型 (TDL‑C) Kevin




Matlab part result

![image](https://github.com/user-attachments/assets/4a51caf2-86cb-47e7-b9e8-84fb02650065)


![image](https://github.com/user-attachments/assets/c7594034-ca04-452b-9d60-a10222b3172d)


![image](https://github.com/user-attachments/assets/ecd39edb-7c1b-47e1-8722-085ac739865e)

Version 2
## estimatePosition.m

Purpose:
This function estimates the 2D position [x, y] of a User Equipment (UE) based on Time of Arrival (TOA)-derived distances to multiple gNodeBs (gNBs). 
The goal is to minimize the total error between the measured distances and the calculated Euclidean distances from the UE to each gNB.

Function Workflow：

Step 1：Initial Guess
x0 = mean(cell2mat(cellfun(@(g) g.Position, gnbList, 'UniformOutput', false)), 1);
→ Uses the average position of all gNBs as the initial guess x0 for the UE position.

Step 2：Cost Function Definition
costFunction = @(x) sum((vecnorm(x - positions, 2, 2) - distances).^2);
→ Defines an objective function that calculates the sum of squared differences between:
Estimated distances from UE to each gNB (using Euclidean norm), and Measured distances (derived from TOA × speed of light)

Step 3：Nonlinear Optimization
estimatedPosition = fminsearch(costFunction, x0);
→  Uses fminsearch to minimize the cost function and return the estimated position that best fits the measured data.


## simulateTDOA.m
This function computes the simulated Time Difference of Arrival (TDOA) between a UE and multiple gNBs. 
It calculates the signal propagation time (TOA) from each gNB to the UE and returns the differences relative to a reference base station. 
These TDOA values are typically used as ground truth for testing positioning algorithms such as locateByTDOA.
 

Workflow：
Step 1：Input Parameters
        - uePos: Actual position of the UE [x, y]
        - gnbList: List of base station objects (gNodeBs)
        - c: Speed of light (used to convert distance to time)

Step 2：Distance Computation



To compute the TDOA values (i.e., time differences between signal arrivals from different gNBs) based on the UE's actual position and known positions of the gNBs. 
These TDOA values are essential inputs for localization algorithms like locateByTDOA.




Version 1
## UE.m — Simulated User Equipment (UE) Signal Reception Module

This module simulates the behavior of a 5G user equipment (UE) receiving signals from multiple gNBs (base stations). 
It models realistic wireless transmission effects, including multipath propagation and additive noise, to emulate a real-world 5G positioning environment.

1. Properties：
   - **ID**：UE device identifier 
   - **Position**：Spatial coordinates of the UE `[x, y]`
   - **NumRx**：Number of receiving antennas (default: 1)  


2. Methods：
   - UE(id, pos, numRx)：Initializes a UE object with a given ID, position, and number of antennas.
   - receive(gnbList, fs, snr_dB)：the core function that simulates signal reception from multiple gNBs.

Signal Reception Flow：

Step 1. Distance and Delay Calculation
For each gNB, the UE calculates the distance, estimates signal attenuation using the Friis transmission model, and applies a time delay to simulate real-world signal propagation.

Step 2. Realistic Channel Modeling (TDL‑C)
Applies the 3GPP TDL‑C model to simulate multipath fading caused by reflections and obstructions, creating a realistic wireless environment.
   
Step 3. Signal Aggregation (Combine the waveforms from all the base stations)
Stores each gNB’s received waveform in a 3D matrix rxMat, and sums them into rxSum for positioning or further analysis.

Step 4. Additive Noise
Gaussian noise is added based on the specified SNR (signal-to-noise ratio) to simulate interference.


## detectTOA.m
This module estimates the **Time of Arrival (TOA)** of signals received from multiple gNBs (base stations). 
It uses **cross-correlation** combined with **parabolic interpolation** to accurately determine when each signal reaches the UE (User Equipment), even in the presence of noise and multipath effects.

Core Concept:
The UE compares the received waveform (`rx`) with each gNB's known transmitted waveform. 
The point of **maximum similarity** (highest cross-correlation) indicates when the signal most likely arrived.  

However, since sampling occurs in discrete time steps, the true arrival time may lie **between samples**. 
Therefore, a **parabolic interpolation** is applied around the correlation peak to refine the TOA estimate with sub-sample precision, significantly improving overall positioning accuracy.


Processing Flow：

1.**Input**
   - `rx`: Received waveform at the UE (may contain signals from multiple gNBs plus noise)
   - `gnbList`: Array of gNB objects with known transmitted signals
   - `fs`: Sampling frequency (Hz), used to convert samples into seconds

2.**Per gNB Processing**
   - Extract reference waveform from each gNB
   - Perform **cross-correlation** between `rx` and the reference waveform
   - Locate the **index of the correlation peak**, indicating the best time match
  
3. **Parabolic Interpolation**
Apply parabolic interpolation around the peak using three points to estimate a more precise offset delta, refining TOA to sub-sample accuracy.


4. **TOA Calculation**
Compute TOA by subtracting the reference waveform length from the peak index pk, adding the interpolation offset delta, and dividing by the sampling rate fs to convert to seconds.


## gNodeB.m
This module defines a gNodeB class that simulates a 5G base station (gNB) transmitting Positioning Reference Signals (PRS) for UE localization.


## locateByTDOA.m
This function performs **2D localization** of a User Equipment (UE) using the **Time Difference of Arrival (TDOA)** technique. 
It requires at least **three gNBs (base stations)** and does **not rely on clock synchronization** between the UE and gNBs.
The function applies **Nonlinear Least Squares (NLS)** optimization with the following objective:![image](https://github.com/user-attachments/assets/caea8881-50e4-4b63-863f-fffa99102cef)



## locateByTOA.m_ TOA-Based UE Position Estimation
This function estimates the UE's position using **Time of Arrival (TOA)** measurements from multiple base stations (gNBs). 
It finds the point in space that minimizes the total error between: the **estimated distances** (from UE to each gNB) and the **measured distances** (derived from TOA × speed of light)


Process Overview:

1. **Initial Guess**  
   The algorithm starts by using the **average of all gNB positions** as the initial location estimate for the UE.
   
2. **Cost Function Construction** _ Builds a **sum of squared residuals** function that compares:
   - Estimated distance from UE to each gNB  
   - Measured distance from TOA × speed of light

3. **Optimization**  
   Uses `fminsearch` to minimize the residual function and find the best-fitting position.

4.**Return Estimated Position**  
   Outputs the estimated 2D coordinate `[x, y]` of the UE.
   

## receiver_tools.m
Defines the `detectTOA` function, which estimates the **Time of Arrival (TOA)** from each base station (`gNodeB`) to the User Equipment (UE) using the received signal. 
This function simulates how a real receiver would detect signal arrival times under noise and multipath conditions.

Processing Steps:
1. **Inputs**
   - `rx`: The complex received signal at the UE.
   - `gnbList`: A list of `gNodeB` objects (each with known transmitted PRS).
   - `fs`: Sampling frequency (Hz), used to convert sample indices to time.

2.**Per gNodeB Estimation**
   - For each gNB, call the `transmit()` method to obtain the reference PRS waveform.
   - Perform **cross-correlation** (`xcorr`) between the received signal and the reference waveform.
   - Locate the index of the **maximum correlation peak**, representing the most likely TOA point.
   - Adjust the peak index by subtracting the waveform length, then convert the result to seconds using the sampling frequency.
  
3.**Output**
Returns a `toa_list`, which contains the estimated TOA (in seconds) for each base station.



## scs_to_fs.m
In 5G NR systems, the **Subcarrier Spacing (SCS)** is configurable depending on application needs — commonly set to **15 kHz**, **30 kHz**, or **60 kHz**. 

Input
scs_kHz: Subcarrier spacing in kHz (typical values include 15, 30, 60)

Output
fs: Corresponding sampling frequency in Hz, assuming 4096 FFT size by default

Formula
![image](https://github.com/user-attachments/assets/4cab5013-ad98-43e9-9218-219b64030fd3)

 **Conversion Principle**
In 5G NR (New Radio), the FFT base is typically defined using **15 kHz** as the reference subcarrier spacing.  
The **sampling frequency** `fs` is calculated using the following scaling formula:![image](https://github.com/user-attachments/assets/30508762-a008-4f69-b380-2480f9dedb9e)



## ue_control_ui.m
This script builds an interactive **Graphical User Interface (GUI)** for simulating UE (User Equipment) signal reception and positioning behavior in a 5G environment.


Workflow Overview：

1.**Initialization & Main Window Setup**
   - Default UE position is set to `[100, 100]`.
   - Supports three carrier frequencies: **2.5 GHz**, **3.5 GHz**, and **4.0 GHz**.
   - Subcarrier spacing (SCS) options: **15 / 30 / 60 kHz**.
   - Sampling frequency `fs` is computed from SCS (e.g., SCS = 15 → fs = 15.36 MHz).
   - GUI window and map panel are created for interactive UE/gNB control.


2.**Control Panel Features**
   - **SNR (dB):** Adjustable signal-to-noise ratio (range: 0–30 dB).
   - **MIMO:** Select number of receiving antennas (1, 2, or 4).
   - **SCS Selection:** Toggle between subcarrier spacings.
   - **Add/Delete gNB:** Dynamically add or remove gNodeB base stations to change the simulation layout.

  
3.**UE Control & Localization Process**
   - Users can move the UE by clicking on the map or using arrow keys.
   - On every movement, the system:

     Reconstructs the UE object
     Calls `UE.receive()` to simulate reception
     Calls `detectTOA()` to estimate time of arrival (TOA)
     Computes TDOA and calls `locateByTDOA()` for position estimation
     Updates the GUI with `viewer_update()` for visual feedback

4.**Real-Time Visualization**
   - Displays actual vs estimated UE positions
   - Shows all gNB locations and connections
   - Allows multi-band and multi-parameter simulation to observe positioning accuracy under different conditions

## viewer_init.m
Initializes the graphical interface used for visualizing PRS-based signal reception and localization within the 5G UE simulation system.
Provides an interactive and informative visual panel to:
Display received PRS signals at the UE,
Show cross-correlation results from multiple gNBs,
Track UE position estimation in real time


Initialization Workflow：
1. Figure and Subplots
   - Top-left: Received signal (Real part)
   - Top-right: Cross-correlation with gNB 0
   - Bottom-left: Cross-correlation with gNB 1
   - Bottom-right: Cross-correlation with gNB 2

2. Shared Object Storage
Stores plot axes and line handles using setappdata()
Enables real-time updates from other modules (e.g., viewer_update.m)

   
4. Information Panel
   - Shows Time of Arrival (TOA) for each gN
   - Displays estimated UE coordinates from localization algorithms


## viewer_update.m
This function updates the visual interface in real time, displaying the UE’s received waveform and localization results. 
It is the **core update routine** for the GUI visualization system and is triggered whenever the UE receives new signals or changes position.

Update Components：
1. **Retrieve GUI Handles**
   Uses `getappdata()` to access the graphical axes, plot lines, and text labels stored in the global environment during `viewer_init.m`.

2. **Update Received Waveform (rx)**
   - Plots the **real part** of the complex received signal using `plot()`.
   - Refreshes the waveform display in the upper-left subplot.


3.  **Update Cross-Correlation Results (corr)**
   - For each gNB, updates the cross-correlation subplot to show correlation strength and peak timing.
   - Helps visualize signal arrival timing used for TOA/TDOA detection.

4. **Update Text Information**
   - Displays the **TOA values** (in seconds) for each gNB.
   - Displays the **estimated UE position** — either in pixel coordinates or transformed to meters depending on the system setup.



