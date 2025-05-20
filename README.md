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



## UE.m
用來模擬使用者裝置（User Equipment, UE）接收訊號的模組。主要功能是模擬 UE 接收多個基站（gNB）訊號並加入雜訊，以真實反映 5G 無線傳輸環境。
1. 屬性（Properties）：
   - ID：裝置編號
   - Position：UE 所在的空間座標（x, y）
   - NumRx：接收天線數量（預設為 1 根）

2. 方法（Methods）：
   - UE(id, pos, numRx)：建構子，用來初始化 UE 的位置與天線數量。
   - receive(gnbList, fs, snr_dB)：主功能函數，模擬 UE 接收來自多個 gNB 的訊號。


接收模擬流程：
1. 屬性（Properties）：
   算出每個基地台到 UE 的距離，根據距離和頻率，利用 Friis 模型估計訊號會被削弱多少（路徑損耗）。同時也會算出訊號傳過來會延遲多久，這些延遲會反映在波形中。

2. 模擬真實通訊環境（使用 TDL-C 通道模型）
   用 3GPP 推出的 TDL-C 模型，模擬真實世界傳輸環境下訊號會被建築物、牆壁等物體反射或擋住，形成多條路徑（多徑效應）
   
3. 把所有基地台的波形組合起來
   UE 把每個基地台傳來的波形記錄下來，根據天線數量儲存在一個三維矩陣 rxMat 裡。把所有訊號加總起來，形成一個總接收訊號 rxSum，可以拿來做定位或分析

4. 加入雜訊模擬干擾
   根據 SNR 設定來加入對應強度的高斯雜訊。


## detectTOA.m
負責估算訊號「到達時間（Time of Arrival, TOA）」的模組。本方法使用 互相關（cross-correlation）搭配拋物線插值，能有效精準判斷每一個 gNB 傳來的信號何時抵達 UE 接收端。
把 UE 收到的訊號，和每個基地台（gNB）原本發送的訊號做比對。當兩者最相似時，就能推估這個訊號大約是幾秒前傳過來的。
但因為資料是用一格一格的樣本收進來，沒辦法非常準確地知道訊號在哪一格進來的，再使用「數學補償」——拋物線插值——讓時間的估算更精準，從而提升整個系統定位效果。

流程：
1. 輸入接收波形與 gNB 清單
   - rx：由 UE 收到的總波形（包含多個 gNB 干擾與雜訊）
   - gnbList：gNB 發射源的物件清單
   - fs：取樣頻率，用來將樣本點轉為秒

2. 依序比對每顆 gNB 的發射波形
   對每顆 gNB 執行以下步驟：
   - 取得該 gNB 的「參考波形」（理論發射波形）
   - 將接收到的總波形與參考波形進行 互相關運算，計算在不同延遲情況下的相似程度
   - 找出 互相關最大值的位置，代表最有可能的到達點
  
3. 拋物線插值（Parabolic Interpolation）
   由於互相關的最大值可能落在兩個取樣點之間，因此使用三點拋物線對最大值進行插值微調，提升估算精度。

4. 計算實際到達時間
   將最大點的位置 pk 減去參考波形長度，加入插值偏移 delta，再除以 fs，得到秒數為單位的 TOA。



## gNodeB.m
基地台（gNB），其主要功能為建立並傳送定位參考訊號（PRS）。


## locateByTDOA.m
透過「到達時間差（TDOA, Time Difference of Arrival）」技術，使用至少三個基站（gNB）對 UE（使用者設備）進行平面（2D）定位，無需 UE 與基站間的時鐘同步。
採用非線性最小平方（NLS, Nonlinear Least Squares）優化，定義目標函數 ![image](https://github.com/user-attachments/assets/caea8881-50e4-4b63-863f-fffa99102cef)



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


## viewer_init.m
Viewer 初始化，負責建立模擬系統中用戶設備（UE）所接收訊號的圖形化視覺介面，用於觀察與分析定位過程中的波形與交叉相關（xcorr）結果。
提供即時的波形與定位資訊，幫助使用者理解定位系統中多基地台訊號的傳播與時間差異對位置估測的影響。

初始化：


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


