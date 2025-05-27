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
The function applies **Nonlinear Least Squares (NLS)** optimization with the following objective: <div align="center">
  <img src="docs/img/tdoa_cost_function.png" alt="TDOA Cost Function" width="300"/>
</div>
![image](https://github.com/user-attachments/assets/caea8881-50e4-4b63-863f-fffa99102cef)



## locateByTOA.m
用於 根據接收時間估算 UE 位置。試著找到一個位置，讓「從該點到各 gNB 的距離」與「實際量測到的距離」誤差總和最小
1. 以所有基站的「平均位置」作為初始估測值
   
2. 建立殘差平方和函數
   將 UE 與每個 gNB 的估計距離與實際量測距離之間的差值平方總和最小化

3. 執行最小化

4. 回傳估計位置

## receiver_tools.m
定義函數「detectTOA」，根據接收到的訊號，估算使用者設備（UE）與每個 gNodeB（基站）之間的到達時間（Time of Arrival, TOA）。
模擬真實接收器在雜訊與多路徑干擾中，如何判斷訊號從每個基站到達的時間點。

流程：
1. 輸入參數
   - rx：UE 接收到的複數訊號。
   - gnbList：所有 gNodeB 物件的列表。
   - fs：採樣頻率（Hz）。

2. 對每個基站執行：
   - 呼叫 gNodeB 的 transmit() 方法取得其發送的參考波形。
   - 使用 xcorr() 進行「互相關分析」，比對接收到的訊號與每個基站的發送波形之間的對應程度。
   - 找出最大相關值的位置，即代表最可能的到達時間點。
   - 根據該位置，扣除波形長度後換算成時間（以秒為單位）作為 TOA 值。
  
3. 輸出結果
   回傳一個 TOA 時間清單 toa_list，對應每一個基站的到達時間估計值。


## scs_to_fs.m
子載波間距轉換成取樣頻率，系統會根據應用需求設定不同的 子載波間距（SubCarrier Spacing, SCS），例如 15 kHz、30 kHz、60 kHz 等。這些設定會影響訊號的頻寬與採樣率，因此需要透過轉換公式計算對應的取樣頻率（Sampling Frequency, fs）。

轉換原理：
5G NR（New Radio）中，FFT 的基準點通常以 15 kHz 為一個單位，採樣頻率依據以下公式計算： ![image](https://github.com/user-attachments/assets/30508762-a008-4f69-b380-2480f9dedb9e)


## ue_control_ui.m
負責建立一個互動式圖形使用者介面（GUI），用於模擬使用者設備（UE, User Equipment）在 5G 環境下的接收與定位行為。

流程：
1.  初始化設定與主視窗建立
   - 預設 UE 起始位置為 [100, 100]。
   - 頻率選項為 2.5 GHz, 3.5 GHz, 4.0 GHz，子載波間距（SCS）支援 15/30/60 kHz。
   - 根據 SCS 計算取樣頻率 fs（例如 SCS=15 → fs=15.36 MHz）。
   - 建立主視窗與地圖區域，供使用者觀察並操作 UE 與 gNB（基站）位置。

2. 控制面板功能
   - SNR (dB)：模擬訊雜比，範圍 0~30。
   - MIMO 數量：接收天線數量，可選擇 1、2 或 4。
   - SCS 選擇：用戶可切換不同的子載波間距。
   - 新增 / 刪除 gNB：即時添加或移除基站節點，動態改變通訊場域佈局。
  
3. UE操控與定位流程
   - 使用者可透過滑鼠點擊地圖或鍵盤（上下左右）移動 UE。
   - 每次 UE 位置變更後，系統會：
     重建 UE 物件。
     呼叫 UE.receive() 進行訊號接收模擬。
     使用 detectTOA() 偵測接收時間（TOA）。
     計算 TDOA（到達時間差），並傳入 locateByTDOA() 進行定位估算。
     最後透過 viewer_update() 更新圖形顯示與預測結果。

4. 實時視覺化更新
即時顯示
- UE 實際位置與預測位置。
- 所有基站位置與其通訊連線。
- 可透過不同頻段與參數模擬真實場景，觀察定位結果變化。


## viewer_init.m
Viewer 初始化，負責建立模擬系統中用戶設備（UE）所接收訊號的圖形化視覺介面，用於觀察與分析定位過程中的波形與交叉相關（xcorr）結果。
提供即時的波形與定位資訊，幫助使用者理解定位系統中多基地台訊號的傳播與時間差異對位置估測的影響。

初始化：
1. 建立視窗與子圖
   - 左上：接收波形（Real）
   - 右上：gNB0 的交叉相關圖
   - 左下：gNB1 的交叉相關圖
   - 右下：gNB2 的交叉相關圖

2. 儲存圖像物件供後續更新使用
   透過 setappdata 指令，將圖像物件與視窗物件儲存在全域環境中，使其他模組能夠即時更新圖表。
   
3. 資訊面板顯示
   - TOA（Time of Arrival）時間：各基地台訊號抵達 UE 的時間。
   - 定位估計座標：模擬系統根據演算法計算出的 UE 預測位置。


## viewer_update.m
波形與定位結果即時更新模組，負責將使用者設備（UE）所接收的波形與定位分析結果「即時呈現在圖形介面」上，是視覺化介面（GUI）運作的核心更新模組。

更新內容：
1. 取得 GUI 控制物件
   使用 getappdata() 從全域環境中取出圖表與標籤物件的控制權。

2. 更新接收波形圖（rx）
   - 顯示實際接收到的複數波形訊號的實部（real part）。
   - 用 plot() 將其即時繪製在圖形視窗中。

3. 更新交叉相關圖（corr）
   - 對每個基站的訊號互相關結果進行更新，顯示其強度與形狀，觀察峰值位置。
   - 用於辨識訊號到達時間。

4. 更新右側文字資訊
   - 顯示每個基站的 TOA 數值（以秒為單位）。
   - 顯示估算後的 UE 位置座標（通常為像素座標，或經轉換為公尺）。


