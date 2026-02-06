# iOS App Store 上架準備

## 程式配置狀態

| 項目 | 狀態 | 備註 |
|------|------|------|
| Bundle Identifier | ✅ | `com.qrscanner.qrScanner` |
| 版本號 | ✅ | 1.0.0 (Build 1) |
| App Icons | ✅ | Assets.xcassets |
| 權限描述 | ✅ | 相機/位置/相簿（Info.plist） |
| Display Name | ✅ | QR Scanner |
| 支援方向 | ✅ | iPhone: 直向 / iPad: 全方向 |

---

## 建置步驟

### 1. 開啟 Xcode

```bash
cd ios
open Runner.xcworkspace
```

### 2. 設定簽署

1. 選擇 **Runner** target
2. 在 **Signing & Capabilities** 中選擇你的 Apple Developer Team
3. 確認 Bundle Identifier: `com.qrscanner.qrScanner`

### 3. 建置 Archive

```bash
flutter build ios --release
```

然後在 Xcode 中：
1. **Product → Archive**
2. Archive 完成後，點擊 **Distribute App**
3. 選擇 **App Store Connect** → **Upload**

---

## App Store Connect 資料

### 基本資訊

| 項目 | 值 |
|------|-----|
| 主要類別 | 工具程式 (Utilities) |
| 次要類別 | 效率 (Productivity) |
| 內容分級 | 4+ |
| 授權類型 | 免費（含廣告） |
| 隱私政策 URL | ⬜ 需提供（託管 PRIVACY_POLICY.md） |
| 支援 URL | ⬜ 需提供 |

### 版本資訊

| 項目 | 狀態 |
|------|------|
| 版本號 | 1.0.0 |
| 版權 | © 2025 QR Scanner |
| App 預覽 | ⬜ 可選（15-30 秒影片） |
| 螢幕截圖 | ⬜ 必填（見下方規格） |

---

## App Store 螢幕截圖規格

### 必須提供的尺寸

| 裝置 | 尺寸 (px) | 必填 |
|------|----------|------|
| iPhone 6.9" (16 Pro Max) | 1320 x 2868 | ✅ |
| iPhone 6.7" (15 Pro Max) | 1290 x 2796 | ✅ |
| iPhone 6.5" (11 Pro Max) | 1242 x 2688 | 可用 6.7" 替代 |
| iPhone 5.5" (8 Plus) | 1242 x 2208 | ✅ |
| iPad Pro 12.9" (6th) | 2048 x 2732 | ✅ (如支援 iPad) |

### 截圖數量
- 最少：2 張
- 最多：10 張
- 建議：5-8 張

---

## 應用程式商店說明（7 語言版本）

### 繁體中文 (zh-Hant) - 預設語言

**應用程式名稱** (30 字內)
```
QR 掃描器
```

**副標題** (30 字內)
```
離線掃描、AR 多碼偵測、隱私優先
```

**關鍵字** (100 字內，逗號分隔)
```
QR,條碼,掃描器,二維碼,barcode,scanner,WiFi,ISBN,vCard,AR,離線,產生器,QR Code,掃碼,相機
```

**宣傳文字** (170 字內，可隨時更新)
```
全新 AR 模式！同時偵測畫面中的多個 QR Code，掃描效率加倍。完全離線運作，保護你的隱私。
```

**描述** (4000 字內)
```
QR 掃描器是一款注重隱私的離線掃描應用程式，讓您輕鬆掃描與產生 QR Code。

掃描功能
• 支援 QR Code、Data Matrix、EAN-13、Code 128 等多種條碼格式
• 智慧語意辨識：自動識別 URL、Email、電話、WiFi、ISBN、vCard、SMS
• AR 模式：同時偵測並顯示畫面中的多個條碼
• 連續掃描模式：快速批量掃描
• 相簿掃描：從照片中讀取條碼

產生功能
• 社群媒體 QR Code：LINE、Facebook、Instagram、YouTube、TikTok 等
• 資訊類型 QR Code：文字、網址、Email、電話、WiFi
• 品牌 Logo 自動嵌入 QR Code 中心
• 可添加備註文字

歷史記錄
• 完整掃描歷史，支援搜尋與篩選
• 日曆檢視模式，回顧每日掃描
• 收藏功能，快速存取重要條碼
• 掃描地點記錄（僅儲存城市/區域）

隱私優先
• 完全離線運作，無需網路連線即可掃描
• 所有資料存放於本機，不上傳雲端
• 位置資訊僅儲存城市/區域，不記錄精確座標

支援語言
繁體中文、English、日本語、Español、Português、한국어、Tiếng Việt

免費使用，包含廣告。
```

**新功能** (4000 字內)
```
1.0.0 版本發布！

• AR 模式：同時偵測多個條碼
• 智慧語意辨識：自動識別 URL、WiFi、ISBN 等類型
• 社群媒體 QR 產生器：快速建立個人社群連結
• 日曆檢視：回顧掃描歷史
• 7 種語言支援
```

---

### English (en-US)

**App Name**
```
QR Scanner
```

**Subtitle**
```
Offline Scan, AR Multi-Code, Privacy First
```

**Keywords**
```
QR,barcode,scanner,code,WiFi,ISBN,vCard,AR,offline,generator,reader,camera,scan,create
```

**Promotional Text**
```
New AR Mode! Detect multiple QR codes on screen simultaneously. Fully offline operation protects your privacy.
```

**Description**
```
QR Scanner is a privacy-focused offline scanning app for effortless QR code scanning and creation.

Scanning Features
• Supports QR Code, Data Matrix, EAN-13, Code 128 and more
• Smart semantic detection: auto-recognize URL, Email, Phone, WiFi, ISBN, vCard, SMS
• AR Mode: detect and display multiple codes simultaneously
• Continuous scan mode for batch scanning
• Gallery scanning: read codes from photos

Generator Features
• Social media QR codes: YouTube, Facebook, Instagram, TikTok, Snapchat, WhatsApp & more
• Info type QR codes: Text, URL, Email, Phone, WiFi
• Brand logo auto-embedded in QR center
• Add custom notes to QR codes

History
• Complete scan history with search and filter
• Calendar view to review daily scans
• Favorites for quick access to important codes
• Location tagging (city/district only)

Privacy First
• Fully offline operation - no internet required to scan
• All data stored locally, never uploaded
• Location info stores city/district only, no precise coordinates

Supported Languages
繁體中文, English, 日本語, Español, Português, 한국어, Tiếng Việt

Free to use with ads.
```

**What's New**
```
Version 1.0.0 released!

• AR Mode: Detect multiple barcodes simultaneously
• Smart semantic detection: Auto-recognize URL, WiFi, ISBN and more
• Social media QR generator: Quickly create personal social links
• Calendar view: Review scan history by date
• 7 language support
```

---

### 日本語 (ja)

**アプリ名**
```
QRスキャナー
```

**サブタイトル**
```
オフラインスキャン・AR複数コード・プライバシー重視
```

**キーワード**
```
QR,バーコード,スキャナー,二次元コード,WiFi,ISBN,vCard,AR,オフライン,生成,読み取り,カメラ
```

**プロモーションテキスト**
```
新ARモード！画面内の複数QRコードを同時検出。完全オフライン動作でプライバシーを保護します。
```

**説明**
```
QRスキャナーは、プライバシーを重視したオフラインスキャンアプリです。

スキャン機能
• QRコード、Data Matrix、EAN-13、Code 128など多数のバーコード形式に対応
• スマート認識：URL、メール、電話、WiFi、ISBN、vCard、SMSを自動検出
• ARモード：画面内の複数コードを同時検出・表示
• 連続スキャンモード：高速バッチスキャン
• ギャラリースキャン：写真からコードを読み取り

生成機能
• SNS用QRコード：LINE、X(Twitter)、Instagram、YouTube、TikTokなど
• 情報タイプQRコード：テキスト、URL、メール、電話、WiFi
• ブランドロゴをQR中央に自動埋め込み
• メモを追加可能

履歴
• 完全なスキャン履歴、検索・フィルター対応
• カレンダービューで日別のスキャンを確認
• お気に入り機能で重要なコードに素早くアクセス
• 位置情報記録（市区町村のみ）

プライバシー優先
• 完全オフライン動作 - スキャンにネット接続不要
• 全データはローカル保存、クラウドにアップロードしません
• 位置情報は市区町村のみ、精密な座標は記録しません

対応言語
繁體中文、English、日本語、Español、Português、한국어、Tiếng Việt

広告付きで無料でご利用いただけます。
```

**新機能**
```
バージョン1.0.0リリース！

• ARモード：複数バーコードを同時検出
• スマート認識：URL、WiFi、ISBNなどを自動認識
• SNS用QR生成：個人のソーシャルリンクを素早く作成
• カレンダービュー：日付別にスキャン履歴を確認
• 7言語対応
```

---

### Español (es-ES)

**Nombre de la App**
```
Escáner QR
```

**Subtítulo**
```
Escaneo Offline, AR Multicódigo, Privacidad
```

**Palabras Clave**
```
QR,código,barras,escáner,WiFi,ISBN,vCard,AR,offline,generador,lector,cámara,crear
```

**Texto Promocional**
```
¡Nuevo modo AR! Detecta múltiples códigos QR en pantalla simultáneamente. Funciona offline para proteger tu privacidad.
```

**Descripción**
```
Escáner QR es una aplicación de escaneo offline centrada en la privacidad.

Funciones de Escaneo
• Compatible con QR Code, Data Matrix, EAN-13, Code 128 y más
• Detección inteligente: reconoce URL, Email, Teléfono, WiFi, ISBN, vCard, SMS
• Modo AR: detecta y muestra múltiples códigos simultáneamente
• Modo de escaneo continuo para escaneo por lotes
• Escaneo de galería: lee códigos desde fotos

Funciones de Generador
• QR de redes sociales: WhatsApp, Instagram, Facebook, TikTok, YouTube, Twitch y más
• QR de información: Texto, URL, Email, Teléfono, WiFi
• Logo de marca integrado automáticamente en el centro del QR
• Añade notas personalizadas

Historial
• Historial completo con búsqueda y filtros
• Vista de calendario para revisar escaneos diarios
• Favoritos para acceso rápido a códigos importantes
• Registro de ubicación (solo ciudad/distrito)

Privacidad Primero
• Funciona completamente offline - no requiere internet
• Todos los datos se almacenan localmente
• La ubicación solo guarda ciudad/distrito, sin coordenadas precisas

Idiomas Soportados
繁體中文, English, 日本語, Español, Português, 한국어, Tiếng Việt

Gratis con anuncios.
```

**Novedades**
```
¡Versión 1.0.0 lanzada!

• Modo AR: Detecta múltiples códigos simultáneamente
• Detección semántica: Reconoce automáticamente URL, WiFi, ISBN y más
• Generador QR social: Crea rápidamente enlaces de tus redes
• Vista de calendario: Revisa el historial por fecha
• Soporte para 7 idiomas
```

---

### Português (pt-BR)

**Nome do App**
```
Leitor QR
```

**Subtítulo**
```
Leitura Offline, AR Multicódigo, Privacidade
```

**Palavras-chave**
```
QR,código,barras,leitor,scanner,WiFi,ISBN,vCard,AR,offline,gerador,câmera,criar
```

**Texto Promocional**
```
Novo modo AR! Detecte múltiplos códigos QR na tela simultaneamente. Funciona offline para proteger sua privacidade.
```

**Descrição**
```
Leitor QR é um aplicativo de digitalização offline focado em privacidade.

Funções de Digitalização
• Suporta QR Code, Data Matrix, EAN-13, Code 128 e mais
• Detecção inteligente: reconhece URL, Email, Telefone, WiFi, ISBN, vCard, SMS
• Modo AR: detecta e exibe múltiplos códigos simultaneamente
• Modo de digitalização contínua para lotes
• Digitalização de galeria: lê códigos de fotos

Funções do Gerador
• QR de redes sociais: WhatsApp, Instagram, Facebook, TikTok, YouTube, Kwai e mais
• QR de informação: Texto, URL, Email, Telefone, WiFi
• Logo da marca incorporado automaticamente no centro do QR
• Adicione notas personalizadas

Histórico
• Histórico completo com busca e filtros
• Visualização de calendário para revisar digitalizações diárias
• Favoritos para acesso rápido a códigos importantes
• Registro de localização (apenas cidade/distrito)

Privacidade em Primeiro
• Funciona completamente offline - não requer internet
• Todos os dados são armazenados localmente
• A localização salva apenas cidade/distrito, sem coordenadas precisas

Idiomas Suportados
繁體中文, English, 日本語, Español, Português, 한국어, Tiếng Việt

Gratuito com anúncios.
```

**Novidades**
```
Versão 1.0.0 lançada!

• Modo AR: Detecta múltiplos códigos simultaneamente
• Detecção semântica: Reconhece automaticamente URL, WiFi, ISBN e mais
• Gerador QR social: Crie rapidamente links das suas redes
• Visualização de calendário: Revise o histórico por data
• Suporte a 7 idiomas
```

---

### 한국어 (ko)

**앱 이름**
```
QR 스캐너
```

**부제**
```
오프라인 스캔, AR 멀티코드, 개인정보 보호
```

**키워드**
```
QR,바코드,스캐너,코드,WiFi,ISBN,vCard,AR,오프라인,생성기,리더,카메라,스캔
```

**프로모션 텍스트**
```
새로운 AR 모드! 화면의 여러 QR 코드를 동시에 감지합니다. 완전한 오프라인 작동으로 개인정보를 보호합니다.
```

**설명**
```
QR 스캐너는 개인정보 보호에 중점을 둔 오프라인 스캔 앱입니다.

스캔 기능
• QR 코드, Data Matrix, EAN-13, Code 128 등 다양한 바코드 형식 지원
• 스마트 인식: URL, 이메일, 전화, WiFi, ISBN, vCard, SMS 자동 감지
• AR 모드: 화면의 여러 코드를 동시에 감지 및 표시
• 연속 스캔 모드: 빠른 일괄 스캔
• 갤러리 스캔: 사진에서 코드 읽기

생성 기능
• 소셜 미디어 QR 코드: 카카오, YouTube, Instagram, 네이버 블로그, Band, TikTok 등
• 정보 유형 QR 코드: 텍스트, URL, 이메일, 전화, WiFi
• 브랜드 로고 QR 중앙에 자동 삽입
• 메모 추가 가능

기록
• 완전한 스캔 기록, 검색 및 필터 지원
• 캘린더 보기로 일별 스캔 확인
• 즐겨찾기로 중요한 코드에 빠르게 접근
• 위치 기록 (시/구 단위만)

개인정보 우선
• 완전한 오프라인 작동 - 스캔에 인터넷 불필요
• 모든 데이터는 로컬에 저장, 클라우드 업로드 없음
• 위치 정보는 시/구만 저장, 정확한 좌표 기록 안 함

지원 언어
繁體中文, English, 日本語, Español, Português, 한국어, Tiếng Việt

광고 포함 무료.
```

**새로운 기능**
```
버전 1.0.0 출시!

• AR 모드: 여러 바코드 동시 감지
• 스마트 인식: URL, WiFi, ISBN 등 자동 인식
• 소셜 QR 생성기: 개인 소셜 링크 빠르게 생성
• 캘린더 보기: 날짜별 스캔 기록 확인
• 7개 언어 지원
```

---

### Tiếng Việt (vi)

**Tên Ứng Dụng**
```
Quét QR
```

**Phụ đề**
```
Quét Offline, AR Đa Mã, Bảo Mật Riêng Tư
```

**Từ khóa**
```
QR,mã vạch,quét,máy quét,WiFi,ISBN,vCard,AR,offline,tạo mã,đọc,camera,tạo
```

**Văn bản quảng cáo**
```
Chế độ AR mới! Phát hiện nhiều mã QR trên màn hình cùng lúc. Hoạt động offline để bảo vệ quyền riêng tư.
```

**Mô tả**
```
Quét QR là ứng dụng quét mã offline chú trọng quyền riêng tư.

Tính Năng Quét
• Hỗ trợ QR Code, Data Matrix, EAN-13, Code 128 và nhiều định dạng khác
• Nhận diện thông minh: tự động nhận URL, Email, Điện thoại, WiFi, ISBN, vCard, SMS
• Chế độ AR: phát hiện và hiển thị nhiều mã cùng lúc
• Chế độ quét liên tục để quét hàng loạt
• Quét thư viện: đọc mã từ ảnh

Tính Năng Tạo Mã
• QR mạng xã hội: Zalo, Facebook, Messenger, YouTube, TikTok, Instagram và nhiều hơn
• QR thông tin: Văn bản, URL, Email, Điện thoại, WiFi
• Logo thương hiệu tự động nhúng vào giữa QR
• Thêm ghi chú tùy chỉnh

Lịch Sử
• Lịch sử quét đầy đủ với tìm kiếm và bộ lọc
• Xem lịch để xem lại các lần quét theo ngày
• Yêu thích để truy cập nhanh các mã quan trọng
• Ghi nhận vị trí (chỉ thành phố/quận)

Quyền Riêng Tư Trước Hết
• Hoạt động hoàn toàn offline - không cần internet để quét
• Tất cả dữ liệu lưu trữ cục bộ, không tải lên đám mây
• Thông tin vị trí chỉ lưu thành phố/quận, không ghi tọa độ chính xác

Ngôn Ngữ Hỗ Trợ
繁體中文, English, 日本語, Español, Português, 한국어, Tiếng Việt

Miễn phí có quảng cáo.
```

**Tính năng mới**
```
Phiên bản 1.0.0 phát hành!

• Chế độ AR: Phát hiện nhiều mã cùng lúc
• Nhận diện thông minh: Tự động nhận URL, WiFi, ISBN và nhiều hơn
• Tạo QR mạng xã hội: Nhanh chóng tạo liên kết mạng xã hội cá nhân
• Xem lịch: Xem lại lịch sử quét theo ngày
• Hỗ trợ 7 ngôn ngữ
```

---

## App 預覽影片（可選）

| 規格 | 要求 |
|------|------|
| 長度 | 15-30 秒 |
| 格式 | MP4, MOV |
| 解析度 | 與截圖相同 |
| 建議內容 | 展示掃描流程、AR 模式、QR 產生 |

---

## App Store 審核注意事項

### 常見拒絕原因

1. **隱私政策缺失** - 必須提供可公開存取的隱私政策 URL
2. **權限說明不足** - Info.plist 中的權限描述必須清楚說明用途
3. **廣告合規** - 確保 AdMob 符合 Apple 廣告政策
4. **崩潰問題** - 提交前徹底測試所有功能
5. **中繼資料不一致** - 截圖必須反映實際 App 功能

### 建議準備

- [ ] 提供有效的隱私政策 URL
- [ ] 提供有效的支援 URL
- [ ] 準備 Apple 帳號（需加入 Apple Developer Program）
- [ ] 在實機上測試所有功能
- [ ] 準備各尺寸截圖

---

## 檔案清單

```
ios/
├── Runner/
│   ├── Info.plist              ✅ 權限描述已配置
│   ├── Assets.xcassets/        ✅ App Icons
│   └── ...
├── Runner.xcodeproj/           ✅ 專案配置
└── Runner.xcworkspace          ✅ 工作區（用此開啟）

PRIVACY_POLICY.md               ✅ 七語言隱私政策
```

---

## 提交流程

1. **登入 App Store Connect**
   - https://appstoreconnect.apple.com

2. **建立 App 記錄**
   - 「我的 App」→「+」→「新增 App」
   - 填寫基本資訊

3. **上傳組建版本**
   - 使用 Xcode 的 Organizer 或 Transporter

4. **填寫 App 資訊**
   - 輸入各語言的商店說明
   - 上傳截圖
   - 設定價格與供應狀況

5. **提交審核**
   - 填寫 App 審核資訊
   - 提交等待審核（通常 24-48 小時）

---

## 注意事項

1. **Apple Developer Program**：需要年費 $99 USD

2. **測試版本**：建議先使用 TestFlight 進行測試

3. **審核時間**：首次審核通常 24-48 小時，後續更新可能更快

4. **拒絕處理**：若被拒絕，仔細閱讀原因並修正後重新提交

5. **版本號遞增**：每次提交新版本必須遞增版本號
