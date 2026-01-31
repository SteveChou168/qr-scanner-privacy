// lib/app_text.dart
// Multi-language dictionary - Supports: zh, en, ja, es, pt, ko, vi

class AppText {
  // ============ Language State ============
  static String _language = 'zh';

  static String get language => _language;

  static set language(String lang) {
    if (['zh', 'en', 'ja', 'es', 'pt', 'ko', 'vi'].contains(lang)) {
      _language = lang;
    }
  }

  static bool get isZh => _language == 'zh';
  static bool get isEn => _language == 'en';
  static bool get isJa => _language == 'ja';
  static bool get isEs => _language == 'es';
  static bool get isPt => _language == 'pt';
  static bool get isKo => _language == 'ko';
  static bool get isVi => _language == 'vi';

  // ============ Internal Helper ============
  static String _v(String zh, String en, String ja, String es, String pt, String ko, String vi) {
    return switch (_language) {
      'zh' => zh,
      'en' => en,
      'ja' => ja,
      'es' => es,
      'pt' => pt,
      'ko' => ko,
      'vi' => vi,
      _ => en, // Global fallback
    };
  }

  // ============ App Title ============
  static String get appTitle => _v('QR 掃描器', 'QR Scanner', 'QRスキャナー', 'Escáner QR', 'Leitor QR', 'QR 스캐너', 'Quét QR');

  // ============ Bottom Toolbar ============
  static String get toolFlash => _v('手電筒', 'Flash', 'ライト', 'Linterna', 'Lanterna', '플래시', 'Đèn pin');
  static String get toolGallery => _v('相簿', 'Gallery', 'ギャラリー', 'Galería', 'Galeria', '갤러리', 'Thư viện');
  static String get toolHistory => _v('歷史', 'History', '履歴', 'Historial', 'Histórico', '기록', 'Lịch sử');
  static String get toolSettings => _v('設置', 'Settings', '設定', 'Ajustes', 'Ajustes', '설정', 'Cài đặt');

  // ============ Scan Screen ============
  static String get scanTitle => _v('掃描', 'Scan', 'スキャン', 'Escanear', 'Escanear', '스캔', 'Quét');
  static String get scanHint => _v('將條碼對準畫面', 'Align barcode in frame', 'バーコードを枠内に合わせてください', 'Alinee el código', 'Alinhe o código', '바코드를 맞추세요', 'Căn mã vào khung');
  static String foundCodes(int n) => _v('發現 $n 個條碼', 'Found $n codes', '$n個のコードを検出', '$n códigos', '$n códigos', '$n개 발견', 'Tìm thấy $n mã');
  static String get scanSaveAll => _v('全部保存', 'Save All', 'すべて保存', 'Guardar todo', 'Salvar tudo', '모두 저장', 'Lưu tất cả');
  static String get scanCopy => _v('複製', 'Copy', 'コピー', 'Copiar', 'Copiar', '복사', 'Sao chép');
  static String get scanOpen => _v('開啟', 'Open', '開く', 'Abrir', 'Abrir', '열기', 'Mở');
  static String get scanSave => _v('保存', 'Save', '保存', 'Guardar', 'Salvar', '저장', 'Lưu');
  static String get scanShare => _v('分享', 'Share', '共有', 'Compartir', 'Partilhar', '공유', 'Chia sẻ');
  static String get scanSearch => _v('搜尋', 'Search', '検索', 'Buscar', 'Buscar', '검색', 'Tìm kiếm');
  static String get scanConnect => _v('連線', 'Connect', '接続', 'Conectar', 'Conectar', '연결', 'Kết nối');
  static String get scanSaved => _v('已保存', 'Saved', '保存しました', 'Guardado', 'Salvo', '저장됨', 'Đã lưu');
  static String get scanAllSaved => _v('已保存所有項目', 'All items saved', 'すべて保存しました', 'Todo guardado', 'Tudo salvo', '모두 저장됨', 'Đã lưu tất cả');
  static String get cameraPermissionRequired => _v('需要相機權限', 'Camera permission required', 'カメラの許可が必要です', 'Permiso de cámara', 'Permissão de câmera', '카메라 권한 필요', 'Cần quyền camera');
  static String get cameraError => _v('相機錯誤', 'Camera error', 'カメラエラー', 'Error de cámara', 'Erro de câmera', '카메라 오류', 'Lỗi camera');

  // ============ Semantic Type Labels ============
  static String get typeUrl => _v('網址', 'URL', 'URL', 'URL', 'URL', 'URL', 'URL');
  static String get typeEmail => _v('電郵', 'Email', 'メール', 'Email', 'Email', '이메일', 'Email');
  static String get typeWifi => _v('Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi');
  static String get typeIsbn => _v('ISBN', 'ISBN', 'ISBN', 'ISBN', 'ISBN', 'ISBN', 'ISBN');
  static String get typeVcard => _v('聯絡人', 'Contact', '連絡先', 'Contacto', 'Contacto', '연락처', 'Liên hệ');
  static String get typeGeo => _v('位置', 'Location', '位置', 'Ubicación', 'Localização', '위치', 'Vị trí');
  static String get typeSms => _v('簡訊', 'SMS', 'SMS', 'SMS', 'SMS', 'SMS', 'SMS');
  static String get typeText => _v('文字', 'Text', 'テキスト', 'Texto', 'Texto', '텍스트', 'Văn bản');

  // ============ Action Buttons ============
  static String get actionOpen => _v('開啟', 'Open', '開く', 'Abrir', 'Abrir', '열기', 'Mở');
  static String get actionEmail => _v('寄信', 'Email', 'メール', 'Enviar', 'Enviar', '이메일', 'Gửi mail');
  static String get actionConnect => _v('連線', 'Connect', '接続', 'Conectar', 'Conectar', '연결', 'Kết nối');
  static String get actionSearch => _v('搜尋', 'Search', '検索', 'Buscar', 'Buscar', '검색', 'Tìm kiếm');
  static String get actionSave => _v('保存', 'Save', '保存', 'Guardar', 'Salvar', '저장', 'Lưu');
  static String get actionSms => _v('簡訊', 'SMS', 'SMS', 'SMS', 'SMS', 'SMS', 'SMS');
  static String get actionCopy => _v('複製', 'Copy', 'コピー', 'Copiar', 'Copiar', '복사', 'Sao chép');
  static String get actionFavorite => _v('加入收藏', 'Add to Favorites', 'お気に入りに追加', 'Añadir favorito', 'Adicionar favorito', '즐겨찾기 추가', 'Thêm yêu thích');
  static String get actionUnfavorite => _v('取消收藏', 'Remove from Favorites', 'お気に入りから削除', 'Quitar favorito', 'Remover favorito', '즐겨찾기 삭제', 'Bỏ yêu thích');
  static String get actionDelete => _v('刪除', 'Delete', '削除', 'Eliminar', 'Eliminar', '삭제', 'Xóa');
  static String get actionShare => _v('分享', 'Share', '共有', 'Compartir', 'Partilhar', '공유', 'Chia sẻ');

  // ============ Error Messages ============
  static String get shareFailed => _v('分享失敗', 'Share failed', '共有に失敗', 'Error al compartir', 'Falha ao partilhar', '공유 실패', 'Chia sẻ thất bại');
  static String get urlOpenFailed => _v('無法開啟連結', 'Failed to open link', 'リンクを開けません', 'No se pudo abrir', 'Falha ao abrir', '링크 열기 실패', 'Không thể mở liên kết');
  static String get emailOpenFailed => _v('無法開啟郵件', 'Failed to open email', 'メールを開けません', 'No se pudo abrir', 'Falha ao abrir', '이메일 열기 실패', 'Không thể mở email');
  static String get smsOpenFailed => _v('無法開啟簡訊', 'Failed to open SMS', 'SMSを開けません', 'No se pudo abrir', 'Falha ao abrir', 'SMS 열기 실패', 'Không thể mở SMS');
  static String get mapOpenFailed => _v('無法開啟地圖', 'Failed to open map', '地図を開けません', 'No se pudo abrir', 'Falha ao abrir', '지도 열기 실패', 'Không thể mở bản đồ');
  static String get cameraPermissionDenied => _v('相機權限被拒絕', 'Camera permission denied', 'カメラ権限が拒否されました', 'Permiso de cámara denegado', 'Permissão de câmera negada', '카메라 권한 거부됨', 'Quyền camera bị từ chối');
  static String get cameraPermissionMessage => _v('請在設置中允許相機權限以使用掃描功能', 'Please allow camera permission in settings to use scanner', '設定でカメラ権限を許可してください', 'Por favor permita el acceso a la cámara', 'Por favor permita o acesso à câmera', '설정에서 카메라 권한을 허용해주세요', 'Vui lòng cho phép quyền camera trong cài đặt');
  static String get openSettings => _v('開啟設置', 'Open Settings', '設定を開く', 'Abrir ajustes', 'Abrir ajustes', '설정 열기', 'Mở cài đặt');
  static String get locationTimeout => _v('位置取得逾時', 'Location timeout', '位置情報がタイムアウト', 'Tiempo de ubicación agotado', 'Tempo de localização esgotado', '위치 시간 초과', 'Hết thời gian vị trí');

  static String get cancel => _v('取消', 'Cancel', 'キャンセル', 'Cancelar', 'Cancelar', '취소', 'Hủy');
  static String get confirm => _v('確認', 'Confirm', '確認', 'Confirmar', 'Confirmar', '확인', 'Xác nhận');

  // Photo Viewer
  static String get saveToGallery => _v('儲存至相簿', 'Save to Gallery', 'ギャラリーに保存', 'Guardar en galería', 'Salvar na galeria', '갤러리에 저장', 'Lưu vào thư viện');
  static String get photoSavedToGallery => _v('已儲存至相簿', 'Saved to Gallery', 'ギャラリーに保存しました', 'Guardado en galería', 'Salvo na galeria', '갤러리에 저장됨', 'Đã lưu vào thư viện');
  static String get photoSaveFailed => _v('儲存失敗', 'Save Failed', '保存に失敗しました', 'Error al guardar', 'Falha ao salvar', '저장 실패', 'Lưu thất bại');

  // ============ History Screen ============
  static String get historyTitle => _v('掃描歷史', 'Scan History', 'スキャン履歴', 'Historial', 'Histórico', '스캔 기록', 'Lịch sử quét');
  static String get historyEmpty => _v('沒有掃描記錄', 'No scan history', 'スキャン履歴がありません', 'Sin historial', 'Sem histórico', '기록 없음', 'Không có lịch sử');
  static String get historyEmptyHint => _v('掃描後的記錄會顯示在這裡', 'Scanned items will appear here', 'スキャンした項目がここに表示されます', 'Aparecerán aquí', 'Aparecerão aqui', '스캔 항목이 여기 표시됩니다', 'Mục đã quét sẽ hiện ở đây');
  static String get historySearchHint => _v('搜尋歷史記錄...', 'Search history...', '履歴を検索...', 'Buscar...', 'Buscar...', '기록 검색...', 'Tìm lịch sử...');
  static String get historyNoResults => _v('沒有找到結果', 'No results found', '結果が見つかりません', 'Sin resultados', 'Sem resultados', '결과 없음', 'Không tìm thấy');
  static String get historyClearFilter => _v('清除篩選', 'Clear filter', 'フィルターをクリア', 'Limpiar filtro', 'Limpar filtro', '필터 초기화', 'Xóa bộ lọc');
  static String get historyClearAll => _v('清除全部', 'Clear All', 'すべて削除', 'Borrar todo', 'Limpar tudo', '모두 삭제', 'Xóa tất cả');
  static String get filterAll => _v('全部', 'All', 'すべて', 'Todo', 'Tudo', '전체', 'Tất cả');
  static String get filterFavorites => _v('最愛', 'Favorites', 'お気に入り', 'Favoritos', 'Favoritos', '즐겨찾기', 'Yêu thích');
  static String get filterFavoritesOnly => _v('只顯示最愛', 'Favorites Only', 'お気に入りのみ', 'Solo favoritos', 'Só favoritos', '즐겨찾기만', 'Chỉ yêu thích');

  // ============ Detail Sheet ============
  static String get detailTitle => _v('掃描詳情', 'Scan Details', 'スキャン詳細', 'Detalles', 'Detalhes', '상세 정보', 'Chi tiết');
  static String get detailRawValue => _v('原始內容', 'Raw Value', '元の値', 'Valor original', 'Valor original', '원본 데이터', 'Nội dung gốc');
  static String get detailParsedValue => _v('解析結果', 'Parsed Value', '解析結果', 'Resultado', 'Resultado', '해석 결과', 'Kết quả');
  static String get detailNote => _v('備註', 'Note', 'メモ', 'Nota', 'Nota', '메모', 'Ghi chú');
  static String get detailNoteHint => _v('添加備註...', 'Add a note...', 'メモを追加...', 'Añadir nota...', 'Adicionar nota...', '메모 추가...', 'Thêm ghi chú...');
  static String get detailNoteSaved => _v('備註已儲存', 'Note saved', 'メモを保存しました', 'Nota guardada', 'Nota salva', '메모 저장됨', 'Đã lưu ghi chú');

  // ============ Time Formats ============
  static String get timeJustNow => _v('剛才', 'Just now', 'たった今', 'Ahora', 'Agora', '방금', 'Vừa xong');
  static String timeMinutesAgo(int n) => _v('$n 分鐘前', '$n min ago', '$n分前', 'hace $n min', 'há $n min', '$n분 전', '$n phút trước');
  static String timeHoursAgo(int n) => _v('$n 小時前', '$n hr ago', '$n時間前', 'hace $n h', 'há $n h', '$n시간 전', '$n giờ trước');
  static String timeDaysAgo(int n) => _v('$n 天前', '$n days ago', '$n日前', 'hace $n días', 'há $n dias', '$n일 전', '$n ngày trước');

  // ============ Dialogs ============
  static String get deleteConfirmTitle => _v('刪除記錄', 'Delete Record', '記録を削除', 'Eliminar registro', 'Eliminar registro', '기록 삭제', 'Xóa bản ghi');
  static String get deleteConfirmMessage => _v('確定要刪除這筆記錄？', 'Are you sure you want to delete this record?', 'この記録を削除しますか？', '¿Eliminar este registro?', 'Eliminar este registro?', '이 기록을 삭제할까요?', 'Xóa bản ghi này?');
  static String get clearAllTitle => _v('清除全部', 'Clear All', 'すべて削除', 'Borrar todo', 'Limpar tudo', '전체 삭제', 'Xóa tất cả');
  static String get clearAllMessage => _v('確定要清除所有歷史記錄？此操作無法復原。', 'Are you sure you want to clear all history? This cannot be undone.', 'すべての履歴を削除しますか？この操作は元に戻せません。', '¿Borrar todo el historial? No se puede deshacer.', 'Limpar todo o histórico? Não pode ser desfeito.', '모든 기록을 삭제할까요? 복구 불가능합니다.', 'Xóa toàn bộ lịch sử? Không thể hoàn tác.');
  static String get dialogCancel => _v('取消', 'Cancel', 'キャンセル', 'Cancelar', 'Cancelar', '취소', 'Hủy');
  static String get dialogConfirm => _v('確定', 'Confirm', '確定', 'Confirmar', 'Confirmar', '확인', 'Xác nhận');
  static String get dialogClose => _v('關閉', 'Close', '閉じる', 'Cerrar', 'Fechar', '닫기', 'Đóng');

  // ============ WiFi Details ============
  static String get wifiSecurity => _v('安全性', 'Security', 'セキュリティ', 'Seguridad', 'Segurança', '보안', 'Bảo mật');
  static String get wifiPassword => _v('密碼', 'Password', 'パスワード', 'Contraseña', 'Senha', '비밀번호', 'Mật khẩu');
  static String get wifiCopyPassword => _v('複製密碼', 'Copy Password', 'パスワードをコピー', 'Copiar contraseña', 'Copiar senha', '비밀번호 복사', 'Sao chép mật khẩu');
  static String get wifiTypeWpa => _v('WPA/WPA2', 'WPA/WPA2', 'WPA/WPA2', 'WPA/WPA2', 'WPA/WPA2', 'WPA/WPA2', 'WPA/WPA2');
  static String get wifiTypeWep => _v('WEP', 'WEP', 'WEP', 'WEP', 'WEP', 'WEP', 'WEP');
  static String get wifiTypeOpen => _v('開放網路', 'Open', 'オープン', 'Abierta', 'Aberta', '개방형', 'Mở');

  // ============ Clipboard ============
  static String get copiedToClipboard => _v('已複製到剪貼簿', 'Copied to clipboard', 'クリップボードにコピーしました', 'Copiado', 'Copiado', '복사됨', 'Đã sao chép');

  // ============ Settings Screen ============
  static String get settingsTitle => _v('設置', 'Settings', '設定', 'Ajustes', 'Ajustes', '설정', 'Cài đặt');

  // Section Headers
  static String get settingsScanSection => _v('掃描設置', 'Scan Settings', 'スキャン設定', 'Escaneo', 'Escaneamento', '스캔 설정', 'Cài đặt quét');
  static String get settingsHistorySection => _v('歷史設置', 'History Settings', '履歴設定', 'Historial', 'Histórico', '기록 설정', 'Cài đặt lịch sử');
  static String get settingsAppearanceSection => _v('外觀', 'Appearance', '外観', 'Apariencia', 'Aparência', '테마', 'Giao diện');
  static String get settingsAboutSection => _v('關於', 'About', 'バージョン情報', 'Acerca de', 'Sobre', '정보', 'Thông tin');

  // Scan Settings
  static String get settingsVibration => _v('震動反饋', 'Vibration', '振動', 'Vibración', 'Vibração', '진동', 'Rung');
  static String get settingsVibrationDesc => _v('掃描成功時震動', 'Vibrate on scan', 'スキャン時に振動', 'Vibrar al escanear', 'Vibrar ao escanear', '스캔 시 진동', 'Rung khi quét');
  static String get settingsSound => _v('掃描音效', 'Sound', 'サウンド', 'Sonido', 'Som', '소리', 'Âm thanh');
  static String get settingsSoundDesc => _v('掃描成功時播放音效', 'Play sound on scan', 'スキャン時にサウンドを再生', 'Sonido al escanear', 'Som ao escanear', '스캔 시 소리', 'Âm thanh khi quét');
  static String get settingsAutoOpenUrl => _v('自動開啟 URL', 'Auto-open URL', 'URLを自動で開く', 'Abrir URL auto', 'Abrir URL auto', 'URL 자동 열기', 'Tự động mở URL');
  static String get settingsAutoOpenUrlDesc => _v('掃描到網址時自動開啟', 'Open URLs automatically', 'URLをスキャンしたら自動で開く', 'Abrir URL automáticamente', 'Abrir URL automaticamente', 'URL 스캔 시 자동 열기', 'Tự động mở khi quét URL');
  static String get settingsUseExternalBrowser => _v('使用外部瀏覽器', 'Use External Browser', '外部ブラウザを使用', 'Usar navegador externo', 'Usar navegador externo', '외부 브라우저 사용', 'Dùng trình duyệt ngoài');
  static String get settingsUseExternalBrowserDesc => _v('開啟連結時使用系統預設瀏覽器', 'Open links in system default browser', 'リンクをシステムブラウザで開く', 'Abrir en navegador del sistema', 'Abrir no navegador do sistema', '시스템 브라우저로 열기', 'Mở bằng trình duyệt hệ thống');
  static String get settingsContinuousScan => _v('連續掃描', 'Continuous Scan', '連続スキャン', 'Escaneo continuo', 'Escaneamento contínuo', '연속 스캔', 'Quét liên tục');
  static String get settingsContinuousScanDesc => _v('掃描後自動儲存，不彈出對話框', 'Auto-save after scan without dialog', 'スキャン後に自動保存', 'Guardar sin diálogo', 'Salvar sem diálogo', '대화상자 없이 자동 저장', 'Tự động lưu, không hiện hộp thoại');

  // History Settings
  static String get settingsSaveImage => _v('保存截圖', 'Save Screenshot', 'スクリーンショットを保存', 'Guardar captura', 'Salvar captura', '스크린샷 저장', 'Lưu ảnh chụp');
  static String get settingsSaveImageDesc => _v('保存掃描時的畫面截圖', 'Save scan screenshot', 'スキャン画面を保存', 'Guardar imagen de escaneo', 'Salvar imagem de escaneamento', '스캔 화면 캡처 저장', 'Lưu ảnh màn hình khi quét');
  static String get settingsSaveLocation => _v('保存地點', 'Save Location', '位置情報を保存', 'Guardar ubicación', 'Salvar localização', '위치 저장', 'Lưu vị trí');
  static String get settingsSaveLocationDesc => _v('記錄掃描時的城市/區域', 'Record city/area', '都市/地域を記録', 'Guardar ciudad/área', 'Salvar cidade/área', '도시/지역 기록', 'Ghi lại thành phố/khu vực');
  static String get settingsHistoryLimit => _v('歷史記錄上限', 'History Limit', '履歴の上限', 'Límite historial', 'Limite histórico', '기록 제한', 'Giới hạn lịch sử');
  static String get settingsHistoryLimitDesc => _v('最多保存的歷史記錄數量', 'Maximum history records', '保存する履歴の最大数', 'Máximo de registros', 'Máximo de registros', '최대 기록 수', 'Số bản ghi tối đa');

  // Appearance
  static String get settingsTheme => _v('主題模式', 'Theme', 'テーマ', 'Tema', 'Tema', '테마', 'Chủ đề');
  static String get settingsThemeSystem => _v('跟隨系統', 'System', 'システム', 'Sistema', 'Sistema', '시스템', 'Hệ thống');
  static String get settingsThemeLight => _v('淺色', 'Light', 'ライト', 'Claro', 'Claro', '라이트', 'Sáng');
  static String get settingsThemeDark => _v('深色', 'Dark', 'ダーク', 'Oscuro', 'Escuro', '다크', 'Tối');
  static String get settingsThemeColor => _v('主題色', 'Theme Color', 'テーマカラー', 'Color tema', 'Cor do tema', '테마 색상', 'Màu chủ đề');
  static String get settingsThemeColorDesc => _v('選擇應用程式主題顏色', 'Choose app theme color', 'アプリのテーマカラーを選択', 'Elegir color del tema', 'Escolher cor do tema', '앱 테마 색상 선택', 'Chọn màu chủ đề');
  static String get colorBlue => _v('藍色', 'Blue', '青', 'Azul', 'Azul', '파랑', 'Xanh dương');
  static String get colorGreen => _v('綠色', 'Green', '緑', 'Verde', 'Verde', '초록', 'Xanh lá');
  static String get colorPurple => _v('紫色', 'Purple', '紫', 'Morado', 'Roxo', '보라', 'Tím');
  static String get colorOrange => _v('橙色', 'Orange', 'オレンジ', 'Naranja', 'Laranja', '주황', 'Cam');
  static String get colorRed => _v('紅色', 'Red', '赤', 'Rojo', 'Vermelho', '빨강', 'Đỏ');
  static String get colorTeal => _v('青綠色', 'Teal', 'ティール', 'Verde azulado', 'Verde-azulado', '청록', 'Xanh ngọc');
  static String get colorPink => _v('粉紅色', 'Pink', 'ピンク', 'Rosa', 'Rosa', '분홍', 'Hồng');
  static String get colorIndigo => _v('靛藍色', 'Indigo', 'インディゴ', 'Índigo', 'Índigo', '남색', 'Chàm');

  // Language
  static String get settingsLanguage => _v('語言', 'Language', '言語', 'Idioma', 'Idioma', '언어', 'Ngôn ngữ');
  static String get settingsLangSystem => _v('跟隨系統', 'System', 'システム', 'Sistema', 'Sistema', '시스템', 'Hệ thống');
  static String get settingsLangZh => _v('繁體中文', '繁體中文', '繁體中文', '繁體中文', '繁體中文', '繁體中文', '繁體中文');
  static String get settingsLangEn => _v('English', 'English', 'English', 'English', 'English', 'English', 'English');
  static String get settingsLangJa => _v('日本語', '日本語', '日本語', '日本語', '日本語', '日本語', '日本語');
  static String get settingsLangEs => _v('Español', 'Español', 'Español', 'Español', 'Español', 'Español', 'Español');
  static String get settingsLangPt => _v('Português', 'Português', 'Português', 'Português', 'Português', 'Português', 'Português');
  static String get settingsLangKo => _v('한국어', '한국어', '한국어', '한국어', '한국어', '한국어', '한국어');
  static String get settingsLangVi => _v('Tiếng Việt', 'Tiếng Việt', 'Tiếng Việt', 'Tiếng Việt', 'Tiếng Việt', 'Tiếng Việt', 'Tiếng Việt');

  // Growth System
  static String get settingsGrowthSection => _v('機械工坊', 'Mech Workshop', '機械工房', 'Taller mecánico', 'Oficina mecânica', '기계 공방', 'Xưởng cơ khí');
  static String get settingsShowGrowth => _v('顯示工坊卡片', 'Show Workshop Card', '工房カードを表示', 'Mostrar tarjeta', 'Mostrar cartão', '공방 카드 표시', 'Hiển thị thẻ xưởng');
  static String get settingsShowGrowthDesc => _v('在設定頁面顯示賽博零件鑄造進度', 'Show Cyber Parts forging progress in Settings', '設定ページにサイバーパーツの鍛造進捗を表示', 'Mostrar progreso de forja', 'Mostrar progresso de forja', '설정에서 사이버 부품 진행 표시', 'Hiển thị tiến trình rèn linh kiện');
  static String get settingsShowRewardPopups => _v('顯示獎勵通知', 'Show Reward Notifications', '報酬通知を表示', 'Mostrar notificaciones', 'Mostrar notificações', '보상 알림 표시', 'Hiển thị thông báo');
  static String get settingsShowRewardPopupsDesc => _v('完成模組時顯示獎勵解鎖彈窗', 'Show popup when rewards are unlocked', 'モジュール完了時に報酬ポップアップを表示', 'Mostrar popup de recompensas', 'Mostrar popup de recompensas', '보상 해금 시 팝업 표시', 'Hiển thị popup khi mở khóa');

  // About
  static String get settingsVersion => _v('版本', 'Version', 'バージョン', 'Versión', 'Versão', '버전', 'Phiên bản');
  static String get settingsAbout => _v('關於', 'About', 'アプリについて', 'Acerca de', 'Sobre', '정보', 'Giới thiệu');
  static String get settingsPrivacy => _v('隱私政策', 'Privacy Policy', 'プライバシーポリシー', 'Privacidad', 'Privacidade', '개인정보 정책', 'Chính sách bảo mật');
  static String get privacyContent => _v(
    '本應用程式重視您的隱私。\n\n'
        '• 掃描記錄僅存儲於本地設備\n'
        '• 位置資訊僅保存城市/區域（無精確座標）\n'
        '• 不收集任何個人資料\n'
        '• 本應用包含 Google AdMob 廣告服務',
    'This app respects your privacy.\n\n'
        '• Scan history is stored locally on device only\n'
        '• Location info only saves city/area (no precise coordinates)\n'
        '• No personal data is collected\n'
        '• This app contains Google AdMob advertising',
    'このアプリはあなたのプライバシーを尊重します。\n\n'
        '• スキャン履歴はデバイスにのみ保存されます\n'
        '• 位置情報は都市/地域のみ保存（正確な座標なし）\n'
        '• 個人データは収集されません\n'
        '• 本アプリにはGoogle AdMob広告が含まれています',
    'Esta app respeta tu privacidad.\n\n'
        '• El historial se guarda solo en el dispositivo\n'
        '• Solo se guarda ciudad/área (sin coordenadas)\n'
        '• No se recopilan datos personales\n'
        '• Contiene publicidad de Google AdMob',
    'Este app respeita sua privacidade.\n\n'
        '• Histórico armazenado apenas no dispositivo\n'
        '• Só salva cidade/área (sem coordenadas)\n'
        '• Nenhum dado pessoal coletado\n'
        '• Contém publicidade do Google AdMob',
    '이 앱은 개인정보를 보호합니다.\n\n'
        '• 스캔 기록은 기기에만 저장됩니다\n'
        '• 위치 정보는 도시/지역만 저장 (좌표 없음)\n'
        '• 개인 데이터를 수집하지 않습니다\n'
        '• Google AdMob 광고가 포함되어 있습니다',
    'Ứng dụng này tôn trọng quyền riêng tư của bạn.\n\n'
        '• Lịch sử chỉ lưu trên thiết bị\n'
        '• Chỉ lưu thành phố/khu vực (không có tọa độ)\n'
        '• Không thu thập dữ liệu cá nhân\n'
        '• Có chứa quảng cáo Google AdMob',
  );

  // About Dialog
  static String get aboutTitle => _v('關於 QR 掃描器', 'About QR Scanner', 'QRスキャナーについて', 'Acerca de Escáner QR', 'Sobre Leitor QR', 'QR 스캐너 정보', 'Giới thiệu Quét QR');
  static String get aboutFeatures => _v('功能介紹：', 'Features:', '機能紹介：', 'Funciones:', 'Recursos:', '기능:', 'Tính năng:');
  static String get aboutFeatureList => _v(
    '• 支援 QR Code、一維條碼等多種格式\n'
        '• 智慧識別網址、電郵、Wi-Fi、ISBN 等\n'
        '• 多碼同時掃描、AR 模式掃描\n'
        '• 掃描歷史與圖鑑統計\n'
        '• QR 碼生成器\n'
        '• 成長系統（3 年成就解鎖）\n'
        '• 支援 7 種語言\n'
        '• 完全離線運作，保護隱私',
    '• Supports QR Code, barcodes, and more\n'
        '• Smart detection: URL, Email, Wi-Fi, ISBN, etc.\n'
        '• Multi-code scanning, AR mode\n'
        '• Scan history and codex statistics\n'
        '• QR code generator\n'
        '• Growth system (3-year achievements)\n'
        '• Supports 7 languages\n'
        '• Fully offline, privacy-friendly',
    '• QRコード、バーコードなど対応\n'
        '• URL、メール、Wi-Fi、ISBNなどを自動認識\n'
        '• 複数コード同時スキャン、ARモード\n'
        '• スキャン履歴と図鑑統計\n'
        '• QRコード生成機能\n'
        '• 成長システム（3年間の実績解除）\n'
        '• 7言語対応\n'
        '• 完全オフライン、プライバシー保護',
    '• Soporta QR Code, códigos de barras y más\n'
        '• Detección inteligente: URL, Email, Wi-Fi, ISBN\n'
        '• Escaneo múltiple, modo AR\n'
        '• Historial y estadísticas\n'
        '• Generador de códigos QR\n'
        '• Sistema de crecimiento (logros de 3 años)\n'
        '• Soporta 7 idiomas\n'
        '• Totalmente offline, privado',
    '• Suporta QR Code, códigos de barras e mais\n'
        '• Detecção inteligente: URL, Email, Wi-Fi, ISBN\n'
        '• Escaneamento múltiplo, modo AR\n'
        '• Histórico e estatísticas\n'
        '• Gerador de códigos QR\n'
        '• Sistema de crescimento (conquistas de 3 anos)\n'
        '• Suporta 7 idiomas\n'
        '• Totalmente offline, privado',
    '• QR 코드, 바코드 등 지원\n'
        '• URL, 이메일, Wi-Fi, ISBN 자동 인식\n'
        '• 다중 코드 스캔, AR 모드\n'
        '• 스캔 기록 및 통계\n'
        '• QR 코드 생성기\n'
        '• 성장 시스템 (3년 업적 해제)\n'
        '• 7개 언어 지원\n'
        '• 완전 오프라인, 개인정보 보호',
    '• Hỗ trợ QR Code, mã vạch và hơn thế nữa\n'
        '• Nhận diện thông minh: URL, Email, Wi-Fi, ISBN\n'
        '• Quét nhiều mã, chế độ AR\n'
        '• Lịch sử và thống kê\n'
        '• Tạo mã QR\n'
        '• Hệ thống phát triển (thành tựu 3 năm)\n'
        '• Hỗ trợ 7 ngôn ngữ\n'
        '• Hoàn toàn offline, bảo mật',
  );
  static String get aboutDisclaimer => _v(
    '聲明：\n本 App 完全離線運作，不連接任何外部伺服器。',
    'Disclaimer:\nThis app works completely offline without connecting to any external servers.',
    '免責事項：\n本アプリは完全にオフラインで動作し、外部サーバーには接続しません。',
    'Aviso:\nEsta app funciona offline sin conectar a servidores externos.',
    'Aviso:\nEste app funciona offline sem conectar a servidores externos.',
    '고지:\n이 앱은 완전히 오프라인으로 작동하며 외부 서버에 연결하지 않습니다.',
    'Tuyên bố:\nỨng dụng này hoạt động hoàn toàn offline, không kết nối máy chủ bên ngoài.',
  );
  static String get aboutPrivacy => _v(
    '隱私：\n所有資料僅儲存在本機裝置，不會上傳到任何伺服器。',
    'Privacy:\nAll data stored locally on device only.',
    'プライバシー：\n全データは端末内にのみ保存され、サーバーには送信されません。',
    'Privacidad:\nTodos los datos se guardan solo en el dispositivo.',
    'Privacidade:\nTodos os dados são armazenados apenas no dispositivo.',
    '개인정보:\n모든 데이터는 기기에만 저장됩니다.',
    'Quyền riêng tư:\nTất cả dữ liệu chỉ lưu trên thiết bị.',
  );

  // Open Source Licenses
  static String get settingsOpenSource => _v('開源資訊', 'Open Source', 'オープンソース', 'Código abierto', 'Código aberto', '오픈소스', 'Mã nguồn mở');
  static String get settingsLicenses => _v('開源授權', 'Open Source Licenses', 'オープンソースライセンス', 'Licencias', 'Licenças', '오픈소스 라이선스', 'Giấy phép mã nguồn mở');
  static String get settingsLicensesSub => _v('第三方套件授權聲明', 'Third-party package licenses', 'サードパーティパッケージのライセンス', 'Licencias de terceros', 'Licenças de terceiros', '서드파티 패키지 라이선스', 'Giấy phép gói bên thứ ba');
  static String get settingsLicensesNote => _v(
    '本應用使用的所有第三方套件均採用 MIT、BSD 或 Apache 2.0 等商業友好授權。',
    'All third-party packages used in this app are licensed under commercial-friendly licenses such as MIT, BSD, or Apache 2.0.',
    '本アプリで使用しているすべてのサードパーティパッケージは、MIT、BSD、Apache 2.0などの商用利用可能なライセンスを採用しています。',
    'Todos los paquetes de terceros usan licencias como MIT, BSD o Apache 2.0.',
    'Todos os pacotes de terceiros usam licenças como MIT, BSD ou Apache 2.0.',
    '모든 서드파티 패키지는 MIT, BSD, Apache 2.0 등의 상용 라이선스를 사용합니다.',
    'Tất cả gói bên thứ ba đều sử dụng giấy phép như MIT, BSD hoặc Apache 2.0.',
  );
  static String get settingsViewAllLicenses => _v('查看完整授權', 'View All Licenses', 'すべてのライセンスを表示', 'Ver todas las licencias', 'Ver todas as licenças', '모든 라이선스 보기', 'Xem tất cả giấy phép');

  // ============ Common ============
  static String get btnConfirm => _v('確定', 'Confirm', '確定', 'Confirmar', 'Confirmar', '확인', 'Xác nhận');
  static String get btnCancel => _v('取消', 'Cancel', 'キャンセル', 'Cancelar', 'Cancelar', '취소', 'Hủy');
  static String get btnClose => _v('關閉', 'Close', '閉じる', 'Cerrar', 'Fechar', '닫기', 'Đóng');
  static String get btnDone => _v('完成', 'Done', '完了', 'Hecho', 'Concluído', '완료', 'Xong');
  static String get btnRescan => _v('重掃', 'Rescan', '再スキャン', 'Reescanear', 'Reescanear', '재스캔', 'Quét lại');

  // Gallery Mode
  static String get galleryTapToSelect => _v('點擊選擇碼', 'Tap to select', 'タップして選択', 'Toque para seleccionar', 'Toque para selecionar', '탭하여 선택', 'Nhấn để chọn');
  static String get galleryNoCodeFound => _v('未找到條碼或 QR 碼', 'No barcode found', 'バーコードが見つかりません', 'No se encontró código', 'Nenhum código encontrado', '코드를 찾을 수 없음', 'Không tìm thấy mã');
  static String get galleryScanning => _v('正在掃描圖片...', 'Scanning image...', '画像をスキャン中...', 'Escaneando imagen...', 'Digitalizando imagem...', '이미지 스캔 중...', 'Đang quét hình ảnh...');
  static String galleryFoundCodesTapToSelect(int n) => _v('發現 $n 個條碼，點擊選擇', 'Found $n codes, tap to select', '$n個のコードを検出、タップして選択', '$n códigos encontrados, toque para seleccionar', '$n códigos encontrados, toque para selecionar', '$n개 코드 발견, 탭하여 선택', 'Tìm thấy $n mã, nhấn để chọn');

  static String get copied => _v('已複製', 'Copied', 'コピーしました', 'Copiado', 'Copiado', '복사됨', 'Đã sao chép');
  static String get saved => _v('已保存', 'Saved', '保存しました', 'Guardado', 'Salvo', '저장됨', 'Đã lưu');
  static String get deleted => _v('已刪除', 'Deleted', '削除しました', 'Eliminado', 'Eliminado', '삭제됨', 'Đã xóa');
  static String get error => _v('發生錯誤', 'Error occurred', 'エラーが発生しました', 'Error', 'Erro', '오류 발생', 'Đã xảy ra lỗi');

  // ============ Bottom Navigation ============
  static String get navScan => _v('掃描', 'Scan', 'スキャン', 'Escanear', 'Escanear', '스캔', 'Quét');
  static String get navCodex => _v('圖鑑', 'Codex', '図鑑', 'Códex', 'Códex', '도감', 'Sổ tay');
  static String get navHistory => _v('歷史', 'History', '履歴', 'Historial', 'Histórico', '기록', 'Lịch sử');
  static String get navSettings => _v('設置', 'Settings', '設定', 'Ajustes', 'Ajustes', '설정', 'Cài đặt');

  // ============ Codex Screen ============
  static String get codexTitle => _v('圖鑑', 'Codex', '図鑑', 'Códex', 'Códex', '도감', 'Sổ tay');
  static String get codexDaily => _v('日', 'Day', '日', 'Día', 'Dia', '일', 'Ngày');
  static String get codexWeekly => _v('週', 'Week', '週', 'Semana', 'Semana', '주', 'Tuần');
  static String get codexMonthly => _v('月', 'Month', '月', 'Mes', 'Mês', '월', 'Tháng');
  static String get codexYearly => _v('年', 'Year', '年', 'Año', 'Ano', '년', 'Năm');

  // Codex Stats
  static String get codexToday => _v('今日', 'Today', '今日', 'Hoy', 'Hoje', '오늘', 'Hôm nay');
  static String get codexTotal => _v('總共', 'Total', '合計', 'Total', 'Total', '전체', 'Tổng');
  static String get codexTopType => _v('最多', 'Top', '最多', 'Top', 'Top', '최다', 'Nhiều nhất');
  static String get codexTopPlace => _v('常去', 'Frequent', 'よく行く', 'Frecuente', 'Frequente', '자주 가는', 'Thường xuyên');

  // Codex Navigation
  static String get codexGoToToday => _v('返回今天', 'Go to Today', '今日に戻る', 'Ir a hoy', 'Ir para hoje', '오늘로 이동', 'Về hôm nay');
  static String get codexPrevious => _v('上一個', 'Previous', '前へ', 'Anterior', 'Anterior', '이전', 'Trước');
  static String get codexNext => _v('下一個', 'Next', '次へ', 'Siguiente', 'Próximo', '다음', 'Tiếp');
  static String get codexSort => _v('排序', 'Sort', '並べ替え', 'Ordenar', 'Ordenar', '정렬', 'Sắp xếp');

  // Codex Filters
  static String get codexFilterAll => _v('全部', 'All', 'すべて', 'Todo', 'Tudo', '전체', 'Tất cả');
  static String get codexFilterUrl => _v('網址', 'URL', 'URL', 'URL', 'URL', 'URL', 'URL');
  static String get codexFilterIsbn => _v('ISBN', 'ISBN', 'ISBN', 'ISBN', 'ISBN', 'ISBN', 'ISBN');
  static String get codexFilterBarcode => _v('條碼', 'Barcode', 'バーコード', 'Código de barras', 'Código de barras', '바코드', 'Mã vạch');
  static String get codexFilterWifi => _v('Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi');
  static String get codexFilterText => _v('文字', 'Text', 'テキスト', 'Texto', 'Texto', '텍스트', 'Văn bản');

  // Codex Sort
  static String get codexSortNewest => _v('最新優先', 'Newest First', '新しい順', 'Más reciente', 'Mais recente', '최신순', 'Mới nhất');
  static String get codexSortOldest => _v('最舊優先', 'Oldest First', '古い順', 'Más antiguo', 'Mais antigo', '오래된 순', 'Cũ nhất');
  static String get codexSortByType => _v('按類型', 'By Type', '種類別', 'Por tipo', 'Por tipo', '유형별', 'Theo loại');
  static String get codexSortHasImage => _v('有圖片優先', 'Has Image', '画像あり', 'Con imagen', 'Com imagem', '이미지 있음', 'Có ảnh');

  // Codex Search
  static String get codexSearchHint => _v('搜尋內容、城市...', 'Search content, city...', '内容、都市を検索...', 'Buscar contenido, ciudad...', 'Buscar conteúdo, cidade...', '내용, 도시 검색...', 'Tìm nội dung, thành phố...');

  // Codex Heatmap
  static String get codexLess => _v('少', 'Less', '少', 'Menos', 'Menos', '적음', 'Ít');
  static String get codexMore => _v('多', 'More', '多', 'Más', 'Mais', '많음', 'Nhiều');

  // Codex Empty States
  static String get codexEmpty => _v('這段時間沒有掃描記錄', 'No scans in this period', 'この期間にスキャンはありません', 'Sin escaneos en este período', 'Nenhum escaneamento neste período', '이 기간에 스캔 없음', 'Không có quét trong khoảng này');
  static String get codexEmptyToday => _v('今天還沒有掃描', 'No scans today', '今日のスキャンはありません', 'Sin escaneos hoy', 'Nenhum escaneamento hoje', '오늘 스캔 없음', 'Hôm nay chưa quét');

  // Codex Labels
  static String get codexWeekOf => _v('週', 'Week of', '週', 'Semana de', 'Semana de', '주', 'Tuần');
  static String codexScansCount(int n) => _v('$n 筆', '$n scans', '$n件', '$n escaneos', '$n escaneamentos', '$n개', '$n lượt quét');
  static String get codexYearSummary => _v('年度摘要', 'Annual Summary', '年間サマリー', 'Resumen anual', 'Resumo anual', '연간 요약', 'Tổng kết năm');
  static String codexMonthLabel(int m) => _v('$m月', _monthName(m), '$m月', _monthNameEs(m), _monthNamePt(m), '$m월', 'Tháng $m');

  static String _monthName(int m) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m];
  }

  static String _monthNameEs(int m) {
    const names = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return names[m];
  }

  static String _monthNamePt(int m) {
    const names = ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return names[m];
  }

  // ============ Export ============
  static String get exportTitle => _v('匯出', 'Export', 'エクスポート', 'Exportar', 'Exportar', '내보내기', 'Xuất');
  static String get exportCsv => _v('匯出 CSV', 'Export CSV', 'CSVエクスポート', 'Exportar CSV', 'Exportar CSV', 'CSV 내보내기', 'Xuất CSV');
  static String get exportJson => _v('匯出 JSON', 'Export JSON', 'JSONエクスポート', 'Exportar JSON', 'Exportar JSON', 'JSON 내보내기', 'Xuất JSON');
  static String get exportSuccess => _v('匯出成功', 'Export successful', 'エクスポート成功', 'Exportación exitosa', 'Exportação bem-sucedida', '내보내기 성공', 'Xuất thành công');
  static String get exportFailed => _v('匯出失敗', 'Export failed', 'エクスポート失敗', 'Error al exportar', 'Falha na exportação', '내보내기 실패', 'Xuất thất bại');
  static String get exportAll => _v('匯出全部', 'Export All', 'すべてエクスポート', 'Exportar todo', 'Exportar tudo', '전체 내보내기', 'Xuất tất cả');
  static String get exportFiltered => _v('匯出篩選結果', 'Export Filtered', 'フィルター結果をエクスポート', 'Exportar filtrado', 'Exportar filtrado', '필터 결과 내보내기', 'Xuất đã lọc');
  static String get exportSelected => _v('匯出選取', 'Export Selected', '選択をエクスポート', 'Exportar selección', 'Exportar seleção', '선택 내보내기', 'Xuất đã chọn');
  static String get exportChooseAction => _v('選擇匯出方式', 'Choose Export Method', 'エクスポート方法を選択', 'Elegir método', 'Escolher método', '내보내기 방법 선택', 'Chọn phương thức');
  static String get exportSaveToDevice => _v('儲存到本機', 'Save to Device', 'デバイスに保存', 'Guardar en dispositivo', 'Salvar no dispositivo', '기기에 저장', 'Lưu vào thiết bị');
  static String get exportShare => _v('分享', 'Share', '共有', 'Compartir', 'Partilhar', '공유', 'Chia sẻ');
  static String get exportSavedTo => _v('已儲存至', 'Saved to', '保存先:', 'Guardado en', 'Salvo em', '저장됨:', 'Đã lưu tại');

  // ============ Batch Operations ============
  static String get selectMode => _v('選擇模式', 'Selection Mode', '選択モード', 'Modo selección', 'Modo seleção', '선택 모드', 'Chế độ chọn');
  static String get selectAll => _v('全選', 'Select All', 'すべて選択', 'Seleccionar todo', 'Selecionar tudo', '전체 선택', 'Chọn tất cả');
  static String get deselectAll => _v('取消全選', 'Deselect All', '選択解除', 'Deseleccionar', 'Desmarcar tudo', '선택 해제', 'Bỏ chọn tất cả');
  static String get deleteSelected => _v('刪除選取', 'Delete Selected', '選択を削除', 'Eliminar selección', 'Eliminar seleção', '선택 삭제', 'Xóa đã chọn');
  static String deleteSelectedMessage(int n) => _v('確定要刪除這 $n 筆記錄嗎？', 'Delete $n selected records?', '$n件の記録を削除しますか？', '¿Eliminar $n registros?', 'Eliminar $n registros?', '$n개 기록을 삭제할까요?', 'Xóa $n bản ghi đã chọn?');
  static String selectedCount(int n) => _v('已選 $n 項', '$n selected', '$n件選択', '$n seleccionados', '$n selecionados', '$n개 선택됨', 'Đã chọn $n');
  static String get favoriteSelected => _v('收藏選取', 'Favorite Selected', '選択をお気に入り', 'Favoritos selección', 'Favoritar seleção', '선택 즐겨찾기', 'Yêu thích đã chọn');
  static String get exitSelectMode => _v('退出選擇', 'Exit Selection', '選択を終了', 'Salir selección', 'Sair seleção', '선택 종료', 'Thoát chế độ chọn');

  // ============ Continuous Scan ============
  static String get scannedCount => _v('已掃描', 'Scanned', 'スキャン済み', 'Escaneados', 'Escaneados', '스캔됨', 'Đã quét');
  static String scannedItems(int n) => _v('已掃描 $n 個', '$n items scanned', '$n件スキャン済み', '$n escaneados', '$n escaneados', '$n개 스캔됨', 'Đã quét $n mục');

  // ============ AR Mode ============
  static String get arMode => _v('AR', 'AR', 'AR', 'AR', 'AR', 'AR', 'AR');
  static String get arModeHint => _v('對準多個條碼，按確認處理', 'Aim at multiple codes, tap confirm', '複数のコードを読み取り、確認を押す', 'Apunte a varios códigos', 'Aponte para vários códigos', '여러 코드를 스캔하고 확인', 'Quét nhiều mã, nhấn xác nhận');
  static String get detecting => _v('偵測中...', 'Detecting...', '検出中...', 'Detectando...', 'Detectando...', '감지 중...', 'Đang phát hiện...');
  static String arModeCollected(int n) => _v('已收集 $n 個條碼', '$n codes collected', '$n個のコードを収集', '$n códigos recopilados', '$n códigos coletados', '$n개 코드 수집', 'Đã thu thập $n mã');

  // ============ Charts ============
  static String get chartsTitle => _v('統計圖表', 'Statistics', '統計チャート', 'Estadísticas', 'Estatísticas', '통계', 'Thống kê');
  static String get typeDistribution => _v('類型分佈', 'Type Distribution', 'タイプ分布', 'Distribución de tipos', 'Distribuição de tipos', '유형 분포', 'Phân bố loại');
  static String get scanTrend => _v('掃描趨勢', 'Scan Trend', 'スキャン傾向', 'Tendencia de escaneo', 'Tendência de escaneamento', '스캔 추세', 'Xu hướng quét');
  static String get thisWeek => _v('本週', 'This Week', '今週', 'Esta semana', 'Esta semana', '이번 주', 'Tuần này');
  static String get thisMonth => _v('本月', 'This Month', '今月', 'Este mes', 'Este mês', '이번 달', 'Tháng này');
  static String get last7Days => _v('最近 7 天', 'Last 7 Days', '過去7日間', 'Últimos 7 días', 'Últimos 7 dias', '최근 7일', '7 ngày qua');
  static String get last30Days => _v('最近 30 天', 'Last 30 Days', '過去30日間', 'Últimos 30 días', 'Últimos 30 dias', '최근 30일', '30 ngày qua');

  // ============ QR Generator ============
  static String get navGenerator => _v('生成', 'Generate', '生成', 'Generar', 'Gerar', '생성', 'Tạo');
  static String get generatorTitle => _v('QR 碼生成器', 'QR Generator', 'QRコード生成', 'Generador QR', 'Gerador QR', 'QR 생성기', 'Tạo mã QR');
  static String get inputText => _v('輸入文字', 'Enter text', 'テキストを入力', 'Ingrese texto', 'Digite texto', '텍스트 입력', 'Nhập văn bản');
  static String get inputHint => _v('輸入要生成的內容...', 'Enter content to generate...', '生成する内容を入力...', 'Ingrese contenido...', 'Digite conteúdo...', '생성할 내용 입력...', 'Nhập nội dung để tạo...');
  static String get generateQR => _v('生成 QR 碼', 'Generate QR', 'QRコード生成', 'Generar QR', 'Gerar QR', 'QR 생성', 'Tạo QR');
  static String get saveImage => _v('儲存圖片', 'Save Image', '画像を保存', 'Guardar imagen', 'Salvar imagem', '이미지 저장', 'Lưu ảnh');
  static String get shareQR => _v('分享 QR 碼', 'Share QR', 'QRコードを共有', 'Compartir QR', 'Partilhar QR', 'QR 공유', 'Chia sẻ QR');
  static String get shareNoteHint => _v('加入備註（選填）', 'Add a note (optional)', 'メモを追加（任意）', 'Agregar nota (opcional)', 'Adicionar nota (opcional)', '메모 추가 (선택)', 'Thêm ghi chú (tùy chọn)');
  static String get templateUrl => _v('網址', 'URL', 'URL', 'URL', 'URL', 'URL', 'URL');
  static String get templateWifi => _v('Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi', 'Wi-Fi');
  static String get templateEmail => _v('電郵', 'Email', 'メール', 'Email', 'Email', '이메일', 'Email');
  static String get templateText => _v('純文字', 'Plain Text', 'テキスト', 'Texto plano', 'Texto simples', '일반 텍스트', 'Văn bản thuần');
  static String get templatePhone => _v('電話', 'Phone', '電話', 'Teléfono', 'Telefone', '전화', 'Điện thoại');

  // Generator Tab Labels
  static String get tabSocial => _v('社群', 'Social', 'SNS', 'Social', 'Social', '소셜', 'Mạng xã hội');
  static String get tabInfo => _v('資訊', 'Info', '情報', 'Info', 'Info', '정보', 'Thông tin');

  static String get wifiSsid => _v('網路名稱', 'Network Name', 'ネットワーク名', 'Nombre de red', 'Nome da rede', '네트워크 이름', 'Tên mạng');
  static String get wifiType => _v('加密類型', 'Security Type', 'セキュリティタイプ', 'Tipo de seguridad', 'Tipo de segurança', '보안 유형', 'Loại bảo mật');
  static String get generatorEmpty => _v('請輸入內容以生成 QR 碼', 'Enter content to generate QR code', 'QRコードを生成するには内容を入力してください', 'Ingrese contenido para generar QR', 'Digite conteúdo para gerar QR', 'QR 코드를 생성하려면 내용을 입력하세요', 'Nhập nội dung để tạo mã QR');
  static String get imageSaved => _v('圖片已儲存', 'Image saved', '画像を保存しました', 'Imagen guardada', 'Imagem salva', '이미지 저장됨', 'Đã lưu ảnh');
  static String get imageSaveFailed => _v('儲存失敗', 'Save failed', '保存に失敗しました', 'Error al guardar', 'Falha ao salvar', '저장 실패', 'Lưu thất bại');
  static String get socialMediaBrand => _v('品牌標誌', 'Brand Logo', 'ブランドロゴ', 'Logo de marca', 'Logo da marca', '브랜드 로고', 'Logo thương hiệu');

  // ============ Validation Messages ============
  static String get invalidEmail => _v('無效的電子郵件格式', 'Invalid email format', '無効なメール形式', 'Formato de email inválido', 'Formato de email inválido', '잘못된 이메일 형식', 'Định dạng email không hợp lệ');
  static String get invalidUrl => _v('無效的網址格式', 'Invalid URL format', '無効なURL形式', 'Formato de URL inválido', 'Formato de URL inválido', '잘못된 URL 형식', 'Định dạng URL không hợp lệ');
  static String get wifiPasswordTooLong => _v('密碼過長（最多 63 字元）', 'Password too long (max 63 chars)', 'パスワードが長すぎます（最大63文字）', 'Contraseña muy larga (máx 63)', 'Senha muito longa (máx 63)', '비밀번호가 너무 깁니다 (최대 63자)', 'Mật khẩu quá dài (tối đa 63 ký tự)');
  static String get contentTooLong => _v('內容過長', 'Content too long', '内容が長すぎます', 'Contenido muy largo', 'Conteúdo muito longo', '내용이 너무 깁니다', 'Nội dung quá dài');

  static String get noteLabel => _v('備註', 'Note', 'メモ', 'Nota', 'Nota', '메모', 'Ghi chú');
  static String get noteHint => _v('輸入備註（會顯示在 QR 碼下方）', 'Add note (shown below QR code)', 'メモを入力（QRコードの下に表示）', 'Añadir nota (se muestra debajo)', 'Adicionar nota (mostrada abaixo)', '메모 입력 (QR 코드 아래 표시)', 'Thêm ghi chú (hiện bên dưới mã QR)');

  // ============ Ads ============
  static String adRemainingQuota(int n) => _v('今日剩餘 $n 次', '$n left today', '本日残り $n 回', '$n restantes hoy', '$n restantes hoje', '오늘 $n회 남음', 'Còn $n lần hôm nay');
  static String get adQuotaExhaustedTitle => _v('今日免費次數已用完', 'Free quota exhausted', '本日の無料回数を使い切りました', 'Cuota gratuita agotada', 'Cota gratuita esgotada', '오늘 무료 횟수 소진', 'Đã hết lượt miễn phí hôm nay');
  static String get adQuotaExhaustedMessage => _v(
    '觀看廣告可獲得額外使用次數\n\n⚠️ 廣告開始後須看完才能關閉',
    'Watch an ad to get extra uses\n\n⚠️ Once started, ad must be watched to completion',
    '広告を視聴すると追加利用ができます\n\n⚠️ 広告開始後は最後まで視聴が必要です',
    'Ver un anuncio para obtener más usos\n\n⚠️ Una vez iniciado, debe verse completo',
    'Assista um anúncio para mais usos\n\n⚠️ Após iniciar, deve assistir até o fim',
    '광고를 보고 추가 사용 횟수를 받으세요\n\n⚠️ 시작 후 끝까지 시청해야 합니다',
    'Xem quảng cáo để có thêm lượt dùng\n\n⚠️ Sau khi bắt đầu phải xem hết',
  );
  static String get adWatchAd => _v('觀看廣告', 'Watch Ad', '広告を見る', 'Ver anuncio', 'Ver anúncio', '광고 보기', 'Xem quảng cáo');
  static String adRewardReceived(int n) => _v('已獲得 $n 次額外使用次數！', 'Got $n extra uses!', '$n回分の追加利用を獲得しました！', '¡$n usos extra obtenidos!', '$n usos extras obtidos!', '$n회 추가 사용 획득!', 'Đã nhận $n lượt dùng thêm!');
  static String get adBonusRewardTitle => _v('幸運加倍！', 'Lucky Bonus!', 'ラッキーボーナス！', '¡Bonus de suerte!', 'Bônus de sorte!', '행운 보너스!', 'Thưởng may mắn!');
  static String adBonusRewardMessage(int n) => _v('恭喜獲得 $n 次額外使用次數！', 'Congratulations! You got $n extra uses!', 'おめでとう！$n回分の追加利用を獲得！', '¡Felicidades! ¡$n usos extra!', 'Parabéns! $n usos extras!', '축하합니다! $n회 추가 사용!', 'Chúc mừng! Nhận $n lượt dùng thêm!');
  static String get adNoThanks => _v('不用了', 'No thanks', '結構です', 'No, gracias', 'Não, obrigado', '괜찮습니다', 'Không, cảm ơn');
  static String get adGetExtraQuotaTitle => _v('獲取額外次數', 'Get Extra Uses', '追加利用を獲得', 'Obtener más usos', 'Obter mais usos', '추가 사용 횟수 받기', 'Nhận thêm lượt dùng');
  static String get adGetExtraQuotaMessage => _v(
    '觀看廣告可隨機獲得 1~3 次額外使用次數。\n每日使用次數將於隔日重置為 3 次。\n\n⚠️ 廣告開始後須看完才能關閉',
    'Watch an ad to get 1-3 extra uses randomly.\nDaily uses reset to 3 each day.\n\n⚠️ Once started, ad must be watched to completion',
    '広告を視聴すると1〜3回の追加利用をランダムで獲得できます。\n毎日の利用回数は翌日3回にリセットされます。\n\n⚠️ 広告開始後は最後まで視聴が必要です',
    'Ver un anuncio para obtener 1-3 usos extra.\nLos usos se reinician a 3 cada día.\n\n⚠️ Una vez iniciado, debe verse completo',
    'Assista um anúncio para obter 1-3 usos extras.\nOs usos reiniciam para 3 a cada dia.\n\n⚠️ Após iniciar, deve assistir até o fim',
    '광고를 보면 1~3회 추가 사용이 랜덤으로 주어집니다.\n매일 사용 횟수는 3회로 초기화됩니다.\n\n⚠️ 시작 후 끝까지 시청해야 합니다',
    'Xem quảng cáo để nhận 1-3 lượt dùng thêm.\nLượt dùng mỗi ngày được đặt lại về 3.\n\n⚠️ Sau khi bắt đầu phải xem hết',
  );
  static String get adDailyLimitReachedTitle => _v('感謝你的熱心支持', 'Thanks for your support', 'ご支援ありがとうございます', 'Gracias por tu apoyo', 'Obrigado pelo apoio', '응원 감사합니다', 'Cảm ơn sự ủng hộ');
  static String get adDailyLimitReachedMessage => _v(
    '今日額外次數已達上限，明天再繼續吧！',
    'You\'ve reached today\'s limit. Come back tomorrow!',
    '本日の追加利用は上限に達しました。また明日！',
    '¡Has alcanzado el límite de hoy. Vuelve mañana!',
    'Você atingiu o limite de hoje. Volte amanhã!',
    '오늘 한도에 도달했습니다. 내일 다시 오세요!',
    'Bạn đã đạt giới hạn hôm nay. Hãy quay lại ngày mai!',
  );

  // ============ Growth System (Cyber Parts) ============
  static String get growthYear1Title => _v('賽博零件', 'Cyber Parts', 'サイバーパーツ', 'Piezas Cyber', 'Peças Cyber', '사이버 부품', 'Linh kiện Cyber');
  static String get growthYear2Title => _v('智核機甲', 'Mecha Warrior', 'メカウォリアー', 'Mecha Guerrero', 'Mecha Guerreiro', '메카 워리어', 'Mecha Chiến binh');
  static String get growthYear3Title => _v('星際尖塔', 'Data Spire', 'データスパイア', 'Espira de Datos', 'Espira de Dados', '데이터 스파이어', 'Tháp Dữ liệu');
  static String get growthDetailSubtitle => _v('建造紀錄', 'Build Log', '建造ログ', 'Registro de construcción', 'Registro de construção', '건조 기록', 'Nhật ký xây dựng');
  static String get growthCurrentPart => _v('當前零件', 'Current Part', '現在のパーツ', 'Pieza actual', 'Peça atual', '현재 부품', 'Linh kiện hiện tại');
  static String get growthModuleCollection => _v('本模組收集', 'Module Collection', 'モジュールコレクション', 'Colección del módulo', 'Coleção do módulo', '모듈 컬렉션', 'Bộ sưu tập mô-đun');
  static String get growthYearAwards => _v('年度成就', 'Year Awards', '年間アワード', 'Premios anuales', 'Prêmios anuais', '연간 업적', 'Thành tựu năm');
  static String get growthReusePart => _v('復用零件', 'Reused Part', '再利用パーツ', 'Pieza reutilizada', 'Peça reutilizada', '재사용 부품', 'Linh kiện tái sử dụng');
  static String growthPartProgress(int current, int total) => _v('零件 $current / $total', 'Part $current / $total', 'パーツ $current / $total', 'Pieza $current / $total', 'Peça $current / $total', '부품 $current / $total', 'Linh kiện $current / $total');
  static String growthYearLabel(int year) => _v('第 $year 年', 'Year $year', '$year年目', 'Año $year', 'Ano $year', '$year년차', 'Năm $year');
  static String growthRoundDay(int day) => _v('第 $day 天', 'Day $day', '$day日目', 'Día $day', 'Dia $day', '$day일차', 'Ngày $day');
  static String get growthDaysUnit => _v('天', 'days', '日', 'días', 'dias', '일', 'ngày');

  // Year-specific progress display
  static String growthYear1Progress(int days) => _v('第 $days 天', 'Day $days', '$days日目', 'Día $days', 'Dia $days', '$days일째', 'Ngày $days');
  static String growthYear2Progress(int percent) => _v('機體同步率：$percent%', 'Sync Rate: $percent%', '同期率：$percent%', 'Sincronización: $percent%', 'Sincronização: $percent%', '동기화율: $percent%', 'Đồng bộ: $percent%');
  static String growthYear3Progress(int floor) => _v('建設層數：${floor}F', 'Floor: ${floor}F', '建設階：${floor}F', 'Piso: ${floor}F', 'Andar: ${floor}F', '층수: ${floor}F', 'Tầng: ${floor}F');
  static String growthYearNumber(int year) => _v('第 $year 年', 'Year $year', '$year年目', 'Año $year', 'Ano $year', '$year년차', 'Năm $year');
  static String growthRoundNumber(int round) => _v('第 $round 輪', 'Round $round', 'ラウンド $round', 'Ronda $round', 'Rodada $round', '$round라운드', 'Vòng $round');

  // ============ CP (Computing Power) System ============
  static String get cpScanCount => _v('解析', 'Parse', '解析', 'Análisis', 'Análise', '분석', 'Phân tích');
  static String get cpEnergyCount => _v('能源', 'Energy', 'エネルギー', 'Energía', 'Energia', '에너지', 'Năng lượng');
  static String get cpEnergyBoostTitle => _v('能量補給', 'Energy Supply', 'エネルギー補給', 'Suministro energía', 'Suprimento energia', '에너지 보급', 'Nạp năng lượng');
  static String cpEnergyBoostMessage(int remaining, int max) => _v(
    '是否觀看廣告以獲取 +0.5 CP 的算力加速？\n(今日剩餘：$remaining/$max)',
    'Watch ad for +0.5 CP boost?\n(Today: $remaining/$max remaining)',
    '広告視聴で+0.5 CPの加速を取得しますか？\n(本日残り：$remaining/$max)',
    '¿Ver anuncio para +0.5 CP?\n(Hoy: $remaining/$max)',
    'Assistir anúncio para +0.5 CP?\n(Hoje: $remaining/$max)',
    '광고 시청으로 +0.5 CP 획득?\n(오늘 남음: $remaining/$max)',
    'Xem quảng cáo để nhận +0.5 CP?\n(Hôm nay: $remaining/$max)',
  );
  static String get cpEnergyBoostConfirm => _v('立即加速', 'Boost Now', '今すぐ加速', 'Acelerar', 'Acelerar', '지금 가속', 'Tăng tốc ngay');
  static String get cpEnergyBoostCancel => _v('稍後再說', 'Maybe Later', 'あとで', 'Más tarde', 'Mais tarde', '나중에', 'Để sau');
  static String cpEnergyBoostSuccess(double cp) => _v(
    '⚡ 成功注入 +$cp CP！當前進度已同步更新。',
    '⚡ +$cp CP injected! Progress synced.',
    '⚡ +$cp CP注入成功！進捗が同期されました。',
    '⚡ +$cp CP inyectado! Progreso sincronizado.',
    '⚡ +$cp CP injetado! Progresso sincronizado.',
    '⚡ +$cp CP 주입 성공! 진행 상황 동기화됨.',
    '⚡ Đã tiêm +$cp CP! Tiến độ đã đồng bộ.',
  );
  static String get cpLimitReached => _v('今日已達上限', 'Daily limit reached', '本日の上限に達しました', 'Límite diario alcanzado', 'Limite diário atingido', '일일 한도 도달', 'Đã đạt giới hạn hôm nay');

  // ============ Forge System (Hidden Easter Egg) ============
  static String get forgeStatus => _v('鍛造中', 'FORGING', '鍛造中', 'FORJANDO', 'FORJANDO', '단조 중', 'ĐANG RÈN');
  static String get forgeReady => _v('待機中', 'READY', '待機中', 'LISTO', 'PRONTO', '대기 중', 'SẴN SÀNG');
  static String get forgeTapToStart => _v('點擊中央開始鍛造', 'Tap center to start forging', '中央をタップして鍛造開始', 'Toca el centro para forjar', 'Toque no centro para forjar', '중앙을 탭하여 단조 시작', 'Chạm vào giữa để bắt đầu rèn');
  static String get forgeInProgress => _v('鍛造進行中...', 'Forging in progress...', '鍛造進行中...', 'Forjando...', 'Forjando...', '단조 진행 중...', 'Đang rèn...');
  static String get forgePaused => _v('已暫停', 'PAUSED', '一時停止', 'PAUSADO', 'PAUSADO', '일시 정지', 'TẠM DỪNG');
  static String get forgeDoubleTapResume => _v('雙擊繼續', 'Double tap to resume', 'ダブルタップで再開', 'Doble toque para continuar', 'Toque duplo para continuar', '더블탭으로 재개', 'Nhấp đúp để tiếp tục');
  static String get forgeLongPressCancel => _v('長按取消', 'Long press to cancel', '長押しでキャンセル', 'Mantén para cancelar', 'Segure para cancelar', '길게 눌러 취소', 'Nhấn giữ để hủy');
  static String forgeComplete(double cp) => _v(
    '⚙️ 鍛造完畢！+$cp CP',
    '⚙️ Forge complete! +$cp CP',
    '⚙️ 鍛造完了！+$cp CP',
    '⚙️ ¡Forja completa! +$cp CP',
    '⚙️ Forja completa! +$cp CP',
    '⚙️ 단조 완료! +$cp CP',
    '⚙️ Hoàn thành rèn! +$cp CP',
  );
  static String get forgeLimitReached => _v('今日鍛造已達上限', 'Daily forge limit reached', '本日の鍛造上限に達しました', 'Límite diario de forja alcanzado', 'Limite diário de forja atingido', '일일 단조 한도 도달', 'Đã đạt giới hạn rèn hôm nay');
  static String get forgeDailyMax => _v('今日已滿', 'MAX TODAY', '本日上限', 'MÁXIMO HOY', 'MÁXIMO HOJE', '오늘 최대', 'TỐI ĐA HÔM NAY');
  static String get tapToClose => _v('點擊關閉', 'Tap to close', 'タップで閉じる', 'Toca para cerrar', 'Toque para fechar', '탭하여 닫기', 'Nhấn để đóng');

  // ============ Rewards System ============
  static String get rewardsTitle => _v('獎勵收藏', 'Rewards', '報酬', 'Recompensas', 'Recompensas', '보상', 'Phần thưởng');
  static String get rewardsThemeColors => _v('主題色', 'Theme Colors', 'テーマカラー', 'Colores tema', 'Cores tema', '테마 색상', 'Màu chủ đề');
  static String get rewardsHistoryLimit => _v('記錄容量', 'History Limit', '記録容量', 'Límite historial', 'Limite histórico', '기록 용량', 'Giới hạn lịch sử');
  static String get rewardsLegendary => _v('傳奇獎勵', 'Legendary', '伝説', 'Legendario', 'Lendário', '전설', 'Huyền thoại');
  static String get rewardsNextUnlock => _v('下一個', 'Next', '次', 'Siguiente', 'Próximo', '다음', 'Tiếp theo');
  static String get rewardsNextStage => _v('下一階段：', 'Next stage:', '次のステージ：', 'Siguiente etapa:', 'Próxima etapa:', '다음 단계:', 'Giai đoạn tiếp:');
  static String get rewardsUnlocked => _v('已解鎖', 'Unlocked', '解放済み', 'Desbloqueado', 'Desbloqueado', '잠금 해제됨', 'Đã mở khóa');
  static String get rewardsLocked => _v('未解鎖', 'Locked', '未解放', 'Bloqueado', 'Bloqueado', '잠김', 'Đã khóa');

  // Reward unlock popup
  static String get rewardUnlockTitle => _v('獎勵解鎖！', 'Reward Unlocked!', '報酬解放！', '¡Recompensa desbloqueada!', 'Recompensa desbloqueada!', '보상 잠금 해제!', 'Mở khóa phần thưởng!');
  static String get rewardNewThemeColor => _v('新主題色', 'New Theme Color', '新テーマカラー', 'Nuevo color tema', 'Nova cor tema', '새 테마 색상', 'Màu chủ đề mới');
  static String get rewardHistoryLimitUp => _v('記錄上限提升', 'History Limit Up', '記録容量アップ', 'Límite aumentado', 'Limite aumentado', '기록 용량 증가', 'Tăng giới hạn');
  static String get rewardLegendaryUnlock => _v('傳奇解鎖！', 'Legendary Unlocked!', '伝説解放！', '¡Legendario!', 'Lendário!', '전설 잠금 해제!', 'Huyền thoại!');
  static String get rewardContinue => _v('太棒了！', 'Awesome!', 'すごい！', '¡Genial!', 'Incrível!', '멋져요!', 'Tuyệt vời!');

  // Growth intro (first time)
  static String get growthIntroTitle => _v('歡迎來到機械工坊！', 'Welcome to Mech Workshop!', '機械工房へようこそ！', '¡Bienvenido al taller!', 'Bem-vindo à oficina!', '기계 공방에 오신 것을 환영합니다!', 'Chào mừng đến xưởng cơ khí!');
  static String get growthIntroDesc => _v('每天使用 App 收集賽博零件，解鎖主題色和更多記錄空間！', 'Use the app daily to collect cyber parts and unlock theme colors and more storage!', '毎日アプリを使ってサイバーパーツを集め、テーマカラーやストレージを解放しよう！', '¡Usa la app diariamente para coleccionar piezas y desbloquear colores y almacenamiento!', 'Use o app diariamente para coletar peças e desbloquear cores e armazenamento!', '매일 앱을 사용하여 사이버 부품을 수집하고 테마 색상과 저장 공간을 잠금 해제하세요!', 'Sử dụng app hàng ngày để thu thập linh kiện và mở khóa màu sắc và dung lượng!');
  static String get growthIntroStart => _v('開始旅程', 'Start Journey', '旅を始める', 'Comenzar viaje', 'Iniciar jornada', '여정 시작', 'Bắt đầu hành trình');
  static String get growthIntroInitialRewards => _v('初始獎勵', 'Initial Rewards', '初期報酬', 'Recompensas iniciales', 'Recompensas iniciais', '초기 보상', 'Phần thưởng ban đầu');

  /// Get localized module name by module ID
  static String growthModuleName(String moduleId) {
    return _moduleNames[moduleId]?[_language] ?? moduleId;
  }

  static const Map<String, Map<String, String>> _moduleNames = {
    // Year 1 modules
    'y1_physical_base': {'zh': '物理底座', 'en': 'Physical Base', 'ja': '物理基盤', 'es': 'Base física', 'pt': 'Base física', 'ko': '물리 기반', 'vi': 'Đế vật lý'},
    'y1_energy_core': {'zh': '能源核心', 'en': 'Energy Core', 'ja': 'エネルギーコア', 'es': 'Núcleo energía', 'pt': 'Núcleo energia', 'ko': '에너지 코어', 'vi': 'Lõi năng lượng'},
    'y1_optical_module': {'zh': '光學模組', 'en': 'Optical Module', 'ja': '光学モジュール', 'es': 'Módulo óptico', 'pt': 'Módulo óptico', 'ko': '광학 모듈', 'vi': 'Mô-đun quang'},
    'y1_storage_array': {'zh': '存儲陣列', 'en': 'Storage Array', 'ja': 'ストレージアレイ', 'es': 'Almacenamiento', 'pt': 'Armazenamento', 'ko': '저장 배열', 'vi': 'Mảng lưu trữ'},
    'y1_cooling_system': {'zh': '冷卻系統', 'en': 'Cooling System', 'ja': '冷却システム', 'es': 'Sistema enfriamiento', 'pt': 'Sistema resfriamento', 'ko': '냉각 시스템', 'vi': 'Hệ tản nhiệt'},
    'y1_comm_mast': {'zh': '通訊桅桿', 'en': 'Comm Mast', 'ja': '通信マスト', 'es': 'Mástil comunicación', 'pt': 'Mastro comunicação', 'ko': '통신 마스트', 'vi': 'Cột viễn thông'},
    'y1_structure_keel': {'zh': '結構龍骨', 'en': 'Structure Keel', 'ja': '構造キール', 'es': 'Quilla estructural', 'pt': 'Quilha estrutural', 'ko': '구조 용골', 'vi': 'Xương cấu trúc'},
    'y1_solar_wing': {'zh': '光能翼板', 'en': 'Solar Wing', 'ja': 'ソーラーウィング', 'es': 'Ala solar', 'pt': 'Asa solar', 'ko': '태양광 날개', 'vi': 'Cánh năng lượng'},
    'y1_repair_drones': {'zh': '維修工蜂', 'en': 'Repair Drones', 'ja': '修理ドローン', 'es': 'Drones reparación', 'pt': 'Drones reparo', 'ko': '수리 드론', 'vi': 'Drone sửa chữa'},
    'y1_quantum_shield': {'zh': '量子防護', 'en': 'Quantum Shield', 'ja': '量子シールド', 'es': 'Escudo cuántico', 'pt': 'Escudo quântico', 'ko': '양자 방패', 'vi': 'Lá chắn lượng tử'},
    'y1_data_relay': {'zh': '數據中繼', 'en': 'Data Relay', 'ja': 'データリレー', 'es': 'Relé de datos', 'pt': 'Relé de dados', 'ko': '데이터 중계', 'vi': 'Tiếp sóng dữ liệu'},
    'y1_propulsion': {'zh': '推進噴口', 'en': 'Propulsion', 'ja': '推進ノズル', 'es': 'Propulsión', 'pt': 'Propulsão', 'ko': '추진 장치', 'vi': 'Hệ đẩy'},
    'y1_heavy_assembly': {'zh': '重裝合成', 'en': 'Heavy Assembly', 'ja': '重装組立', 'es': 'Ensamblaje pesado', 'pt': 'Montagem pesada', 'ko': '중장비 조립', 'vi': 'Lắp ráp nặng'},
    'y1_ai_command': {'zh': 'AI指揮台', 'en': 'AI Command', 'ja': 'AI司令台', 'es': 'Mando IA', 'pt': 'Comando IA', 'ko': 'AI 지휘대', 'vi': 'Đài chỉ huy AI'},
    'y1_ultimate_activation': {'zh': '終極啟動', 'en': 'Ultimate Activation', 'ja': '究極起動', 'es': 'Activación final', 'pt': 'Ativação final', 'ko': '최종 활성화', 'vi': 'Kích hoạt tối thượng'},
    // Year 2 modules
    'y2_neural_network': {'zh': '神經網路', 'en': 'Neural Network', 'ja': 'ニューラルネット', 'es': 'Red neuronal', 'pt': 'Rede neural', 'ko': '신경망', 'vi': 'Mạng thần kinh'},
    'y2_spinal_frame': {'zh': '脊椎骨架', 'en': 'Spinal Frame', 'ja': '脊椎フレーム', 'es': 'Marco espinal', 'pt': 'Quadro espinhal', 'ko': '척추 프레임', 'vi': 'Khung xương sống'},
    'y2_energy_heart': {'zh': '能源心臟', 'en': 'Energy Heart', 'ja': 'エネルギー心臓', 'es': 'Corazón energía', 'pt': 'Coração energia', 'ko': '에너지 심장', 'vi': 'Tim năng lượng'},
    'y2_visual_sensors': {'zh': '視覺感知', 'en': 'Visual Sensors', 'ja': '視覚センサー', 'es': 'Sensores visuales', 'pt': 'Sensores visuais', 'ko': '시각 센서', 'vi': 'Cảm biến thị giác'},
    'y2_left_power_arm': {'zh': '左舷動力臂', 'en': 'Left Power Arm', 'ja': '左パワーアーム', 'es': 'Brazo izquierdo', 'pt': 'Braço esquerdo', 'ko': '좌측 파워암', 'vi': 'Cánh tay trái'},
    'y2_right_work_arm': {'zh': '右舷作業臂', 'en': 'Right Work Arm', 'ja': '右作業アーム', 'es': 'Brazo derecho', 'pt': 'Braço direito', 'ko': '우측 작업암', 'vi': 'Cánh tay phải'},
    'y2_support_legs': {'zh': '支撐下肢', 'en': 'Support Legs', 'ja': 'サポートレッグ', 'es': 'Piernas soporte', 'pt': 'Pernas suporte', 'ko': '지지 다리', 'vi': 'Chân hỗ trợ'},
    'y2_hydraulic_system': {'zh': '液壓系統', 'en': 'Hydraulic System', 'ja': '油圧システム', 'es': 'Sistema hidráulico', 'pt': 'Sistema hidráulico', 'ko': '유압 시스템', 'vi': 'Hệ thủy lực'},
    'y2_internal_loop': {'zh': '內部循環', 'en': 'Internal Loop', 'ja': '内部循環', 'es': 'Circuito interno', 'pt': 'Circuito interno', 'ko': '내부 순환', 'vi': 'Vòng nội bộ'},
    'y2_defense_chestplate': {'zh': '防禦胸甲', 'en': 'Defense Chestplate', 'ja': '防御チェストプレート', 'es': 'Peto defensa', 'pt': 'Peitoral defesa', 'ko': '방어 흉갑', 'vi': 'Giáp ngực'},
    'y2_shoulder_radar': {'zh': '肩部雷達', 'en': 'Shoulder Radar', 'ja': '肩部レーダー', 'es': 'Radar hombro', 'pt': 'Radar ombro', 'ko': '어깨 레이더', 'vi': 'Radar vai'},
    'y2_jet_pack': {'zh': '噴射背囊', 'en': 'Jet Pack', 'ja': 'ジェットパック', 'es': 'Mochila jet', 'pt': 'Mochila jato', 'ko': '제트팩', 'vi': 'Ba lô phản lực'},
    'y2_shell_assembly': {'zh': '外殼總成', 'en': 'Shell Assembly', 'ja': 'シェル組立', 'es': 'Ensamblaje carcasa', 'pt': 'Montagem carcaça', 'ko': '외장 조립', 'vi': 'Lắp ráp vỏ'},
    'y2_ai_interface': {'zh': 'AI介面', 'en': 'AI Interface', 'ja': 'AIインターフェース', 'es': 'Interfaz IA', 'pt': 'Interface IA', 'ko': 'AI 인터페이스', 'vi': 'Giao diện AI'},
    'y2_ultimate_awakening': {'zh': '終極覺醒', 'en': 'Ultimate Awakening', 'ja': '究極覚醒', 'es': 'Despertar final', 'pt': 'Despertar final', 'ko': '최종 각성', 'vi': 'Thức tỉnh tối thượng'},
    // Year 3 modules
    'y3_underground_fiber': {'zh': '地底光纖', 'en': 'Underground Fiber', 'ja': '地下光ファイバー', 'es': 'Fibra subterránea', 'pt': 'Fibra subterrânea', 'ko': '지하 광섬유', 'vi': 'Cáp quang ngầm'},
    'y3_giant_foundation': {'zh': '巨型地基', 'en': 'Giant Foundation', 'ja': '巨大基礎', 'es': 'Cimiento gigante', 'pt': 'Fundação gigante', 'ko': '거대 기초', 'vi': 'Móng khổng lồ'},
    'y3_power_room': {'zh': '能源室', 'en': 'Power Room', 'ja': 'パワールーム', 'es': 'Sala de energía', 'pt': 'Sala de energia', 'ko': '동력실', 'vi': 'Phòng năng lượng'},
    'y3_cooling_pool': {'zh': '冷卻池', 'en': 'Cooling Pool', 'ja': '冷却プール', 'es': 'Piscina enfriamiento', 'pt': 'Piscina resfriamento', 'ko': '냉각 풀', 'vi': 'Bể làm mát'},
    'y3_central_stairs': {'zh': '中央梯間', 'en': 'Central Stairs', 'ja': '中央階段', 'es': 'Escaleras centrales', 'pt': 'Escadas centrais', 'ko': '중앙 계단', 'vi': 'Cầu thang trung tâm'},
    'y3_server_floor': {'zh': '伺服器層', 'en': 'Server Floor', 'ja': 'サーバーフロア', 'es': 'Piso servidores', 'pt': 'Andar servidores', 'ko': '서버 층', 'vi': 'Tầng máy chủ'},
    'y3_data_terminal': {'zh': '數據終端', 'en': 'Data Terminal', 'ja': 'データターミナル', 'es': 'Terminal de datos', 'pt': 'Terminal de dados', 'ko': '데이터 터미널', 'vi': 'Thiết bị đầu cuối'},
    'y3_external_frame': {'zh': '外部結構架', 'en': 'External Frame', 'ja': '外部フレーム', 'es': 'Marco externo', 'pt': 'Quadro externo', 'ko': '외부 프레임', 'vi': 'Khung bên ngoài'},
    'y3_signal_tower': {'zh': '信號發射塔', 'en': 'Signal Tower', 'ja': '信号タワー', 'es': 'Torre de señal', 'pt': 'Torre de sinal', 'ko': '신호 타워', 'vi': 'Tháp tín hiệu'},
    'y3_solar_curtain': {'zh': '太陽能帷幕', 'en': 'Solar Curtain', 'ja': 'ソーラーカーテン', 'es': 'Cortina solar', 'pt': 'Cortina solar', 'ko': '태양광 커튼', 'vi': 'Màn năng lượng'},
    'y3_drone_port': {'zh': '無人機港口', 'en': 'Drone Port', 'ja': 'ドローンポート', 'es': 'Puerto de drones', 'pt': 'Porto de drones', 'ko': '드론 포트', 'vi': 'Cảng drone'},
    'y3_quantum_chamber': {'zh': '量子處理室', 'en': 'Quantum Chamber', 'ja': '量子チェンバー', 'es': 'Cámara cuántica', 'pt': 'Câmara quântica', 'ko': '양자 챔버', 'vi': 'Buồng lượng tử'},
    'y3_lightning_radar': {'zh': '防雷雷達', 'en': 'Lightning Radar', 'ja': '避雷レーダー', 'es': 'Radar de rayos', 'pt': 'Radar de raios', 'ko': '번개 레이더', 'vi': 'Radar chống sét'},
    'y3_neon_spire': {'zh': '霓虹尖塔', 'en': 'Neon Spire', 'ja': 'ネオンスパイア', 'es': 'Aguja de neón', 'pt': 'Espira de néon', 'ko': '네온 첨탑', 'vi': 'Tháp neon'},
    'y3_data_ascension': {'zh': '數據通天', 'en': 'Data Ascension', 'ja': 'データアセンション', 'es': 'Ascensión de datos', 'pt': 'Ascensão de dados', 'ko': '데이터 승천', 'vi': 'Thăng hoa dữ liệu'},
  };

  /// Get localized part name by part ID
  static String growthPartName(String partId) {
    // Extract base name from part ID (e.g., 'y1_m0_p0_screw' -> 'screw')
    final segments = partId.split('_');
    if (segments.length < 4) return partId;

    // Remove trailing numbers and '_reuse' suffix
    var baseName = segments.sublist(3).join('_');
    baseName = baseName.replaceAll('_reuse', '');

    return _partNames[baseName]?[_language] ?? _partNames[baseName]?['en'] ?? baseName;
  }

  static const Map<String, Map<String, String>> _partNames = {
    // Common parts - Hardware
    'screw': {'zh': '螺絲', 'en': 'Screw', 'ja': 'ネジ', 'es': 'Tornillo', 'pt': 'Parafuso', 'ko': '나사', 'vi': 'Ốc vít'},
    'brick': {'zh': '磚塊', 'en': 'Brick', 'ja': 'レンガ', 'es': 'Ladrillo', 'pt': 'Tijolo', 'ko': '벽돌', 'vi': 'Gạch'},
    'construction': {'zh': '建築', 'en': 'Construction', 'ja': '建設', 'es': 'Construcción', 'pt': 'Construção', 'ko': '건설', 'vi': 'Xây dựng'},
    'hammer': {'zh': '鐵鎚', 'en': 'Hammer', 'ja': 'ハンマー', 'es': 'Martillo', 'pt': 'Martelo', 'ko': '망치', 'vi': 'Búa'},
    'ladder': {'zh': '梯子', 'en': 'Ladder', 'ja': 'はしご', 'es': 'Escalera', 'pt': 'Escada', 'ko': '사다리', 'vi': 'Thang'},
    'ruler': {'zh': '尺規', 'en': 'Ruler', 'ja': '定規', 'es': 'Regla', 'pt': 'Régua', 'ko': '자', 'vi': 'Thước'},
    // Energy
    'battery': {'zh': '電池', 'en': 'Battery', 'ja': 'バッテリー', 'es': 'Batería', 'pt': 'Bateria', 'ko': '배터리', 'vi': 'Pin'},
    'plug': {'zh': '插頭', 'en': 'Plug', 'ja': 'プラグ', 'es': 'Enchufe', 'pt': 'Plugue', 'ko': '플러그', 'vi': 'Phích cắm'},
    'lightning': {'zh': '閃電', 'en': 'Lightning', 'ja': '稲妻', 'es': 'Rayo', 'pt': 'Relâmpago', 'ko': '번개', 'vi': 'Sét'},
    'gear': {'zh': '齒輪', 'en': 'Gear', 'ja': 'ギア', 'es': 'Engranaje', 'pt': 'Engrenagem', 'ko': '기어', 'vi': 'Bánh răng'},
    'fire': {'zh': '火焰', 'en': 'Fire', 'ja': '炎', 'es': 'Fuego', 'pt': 'Fogo', 'ko': '불', 'vi': 'Lửa'},
    'hotspring': {'zh': '熱氣', 'en': 'Hot Spring', 'ja': '温泉', 'es': 'Aguas termales', 'pt': 'Fonte termal', 'ko': '온천', 'vi': 'Suối nóng'},
    'flask': {'zh': '燒瓶', 'en': 'Flask', 'ja': 'フラスコ', 'es': 'Matraz', 'pt': 'Frasco', 'ko': '플라스크', 'vi': 'Bình'},
    'flask2': {'zh': '燒瓶', 'en': 'Flask', 'ja': 'フラスコ', 'es': 'Matraz', 'pt': 'Frasco', 'ko': '플라스크', 'vi': 'Bình'},
    // Optical
    'magnify': {'zh': '放大鏡', 'en': 'Magnifier', 'ja': '虫眼鏡', 'es': 'Lupa', 'pt': 'Lupa', 'ko': '돋보기', 'vi': 'Kính lúp'},
    'telescope': {'zh': '望遠鏡', 'en': 'Telescope', 'ja': '望遠鏡', 'es': 'Telescopio', 'pt': 'Telescópio', 'ko': '망원경', 'vi': 'Kính viễn vọng'},
    'crystal': {'zh': '水晶球', 'en': 'Crystal', 'ja': '水晶', 'es': 'Cristal', 'pt': 'Cristal', 'ko': '수정', 'vi': 'Pha lê'},
    'eye': {'zh': '眼睛', 'en': 'Eye', 'ja': '目', 'es': 'Ojo', 'pt': 'Olho', 'ko': '눈', 'vi': 'Mắt'},
    'camera': {'zh': '相機', 'en': 'Camera', 'ja': 'カメラ', 'es': 'Cámara', 'pt': 'Câmera', 'ko': '카메라', 'vi': 'Máy ảnh'},
    'flashlight': {'zh': '手電筒', 'en': 'Flashlight', 'ja': '懐中電灯', 'es': 'Linterna', 'pt': 'Lanterna', 'ko': '손전등', 'vi': 'Đèn pin'},
    'rainbow': {'zh': '彩虹', 'en': 'Rainbow', 'ja': '虹', 'es': 'Arcoíris', 'pt': 'Arco-íris', 'ko': '무지개', 'vi': 'Cầu vồng'},
    // Storage
    'floppy': {'zh': '磁碟', 'en': 'Floppy', 'ja': 'フロッピー', 'es': 'Disquete', 'pt': 'Disquete', 'ko': '플로피', 'vi': 'Đĩa mềm'},
    'folder': {'zh': '資料夾', 'en': 'Folder', 'ja': 'フォルダ', 'es': 'Carpeta', 'pt': 'Pasta', 'ko': '폴더', 'vi': 'Thư mục'},
    'folderopen': {'zh': '開啟資料夾', 'en': 'Open Folder', 'ja': '開いたフォルダ', 'es': 'Carpeta abierta', 'pt': 'Pasta aberta', 'ko': '열린 폴더', 'vi': 'Mở thư mục'},
    'cd': {'zh': '光碟', 'en': 'CD', 'ja': 'CD', 'es': 'CD', 'pt': 'CD', 'ko': 'CD', 'vi': 'Đĩa CD'},
    'vhs': {'zh': '錄影帶', 'en': 'VHS', 'ja': 'ビデオテープ', 'es': 'VHS', 'pt': 'VHS', 'ko': 'VHS', 'vi': 'Băng video'},
    'pager': {'zh': '呼叫器', 'en': 'Pager', 'ja': 'ポケベル', 'es': 'Buscapersonas', 'pt': 'Pager', 'ko': '호출기', 'vi': 'Máy nhắn tin'},
    'brain': {'zh': '大腦', 'en': 'Brain', 'ja': '脳', 'es': 'Cerebro', 'pt': 'Cérebro', 'ko': '뇌', 'vi': 'Não'},
    // Cooling
    'thermometer': {'zh': '溫度計', 'en': 'Thermometer', 'ja': '温度計', 'es': 'Termómetro', 'pt': 'Termômetro', 'ko': '온도계', 'vi': 'Nhiệt kế'},
    'snowflake': {'zh': '雪花', 'en': 'Snowflake', 'ja': '雪の結晶', 'es': 'Copo de nieve', 'pt': 'Floco de neve', 'ko': '눈송이', 'vi': 'Bông tuyết'},
    'ice': {'zh': '冰塊', 'en': 'Ice', 'ja': '氷', 'es': 'Hielo', 'pt': 'Gelo', 'ko': '얼음', 'vi': 'Đá'},
    'droplet': {'zh': '水滴', 'en': 'Droplet', 'ja': '水滴', 'es': 'Gota', 'pt': 'Gota', 'ko': '물방울', 'vi': 'Giọt nước'},
    'wind': {'zh': '風', 'en': 'Wind', 'ja': '風', 'es': 'Viento', 'pt': 'Vento', 'ko': '바람', 'vi': 'Gió'},
    'bubble': {'zh': '氣泡', 'en': 'Bubble', 'ja': '泡', 'es': 'Burbuja', 'pt': 'Bolha', 'ko': '거품', 'vi': 'Bong bóng'},
    // Communication
    'satellite_dish': {'zh': '衛星天線', 'en': 'Satellite Dish', 'ja': '衛星アンテナ', 'es': 'Antena', 'pt': 'Antena', 'ko': '위성 안테나', 'vi': 'Chảo vệ tinh'},
    'signal': {'zh': '訊號', 'en': 'Signal', 'ja': '信号', 'es': 'Señal', 'pt': 'Sinal', 'ko': '신호', 'vi': 'Tín hiệu'},
    'phone': {'zh': '電話', 'en': 'Phone', 'ja': '電話', 'es': 'Teléfono', 'pt': 'Telefone', 'ko': '전화', 'vi': 'Điện thoại'},
    'megaphone': {'zh': '擴音器', 'en': 'Megaphone', 'ja': 'メガホン', 'es': 'Megáfono', 'pt': 'Megafone', 'ko': '확성기', 'vi': 'Loa'},
    'radio': {'zh': '收音機', 'en': 'Radio', 'ja': 'ラジオ', 'es': 'Radio', 'pt': 'Rádio', 'ko': '라디오', 'vi': 'Radio'},
    'globe': {'zh': '地球', 'en': 'Globe', 'ja': '地球儀', 'es': 'Globo', 'pt': 'Globo', 'ko': '지구본', 'vi': 'Quả địa cầu'},
    // Structure
    'chain': {'zh': '鏈條', 'en': 'Chain', 'ja': 'チェーン', 'es': 'Cadena', 'pt': 'Corrente', 'ko': '사슬', 'vi': 'Xích'},
    'link': {'zh': '連結', 'en': 'Link', 'ja': 'リンク', 'es': 'Enlace', 'pt': 'Link', 'ko': '링크', 'vi': 'Liên kết'},
    'paperclip': {'zh': '迴紋針', 'en': 'Paperclip', 'ja': 'クリップ', 'es': 'Clip', 'pt': 'Clipe', 'ko': '클립', 'vi': 'Kẹp giấy'},
    'shield': {'zh': '護盾', 'en': 'Shield', 'ja': 'シールド', 'es': 'Escudo', 'pt': 'Escudo', 'ko': '방패', 'vi': 'Khiên'},
    'barrier': {'zh': '屏障', 'en': 'Barrier', 'ja': 'バリア', 'es': 'Barrera', 'pt': 'Barreira', 'ko': '장벽', 'vi': 'Rào chắn'},
    // Solar
    'bluesquare': {'zh': '藍板', 'en': 'Blue Panel', 'ja': '青パネル', 'es': 'Panel azul', 'pt': 'Painel azul', 'ko': '파란 패널', 'vi': 'Tấm xanh'},
    'triangle': {'zh': '三角', 'en': 'Triangle', 'ja': '三角', 'es': 'Triángulo', 'pt': 'Triângulo', 'ko': '삼각형', 'vi': 'Tam giác'},
    'sun': {'zh': '太陽', 'en': 'Sun', 'ja': '太陽', 'es': 'Sol', 'pt': 'Sol', 'ko': '태양', 'vi': 'Mặt trời'},
    'sunrise': {'zh': '日出', 'en': 'Sunrise', 'ja': '日の出', 'es': 'Amanecer', 'pt': 'Nascer do sol', 'ko': '일출', 'vi': 'Bình minh'},
    'sunset': {'zh': '日落', 'en': 'Sunset', 'ja': '日の入り', 'es': 'Atardecer', 'pt': 'Pôr do sol', 'ko': '일몰', 'vi': 'Hoàng hôn'},
    'star': {'zh': '星星', 'en': 'Star', 'ja': '星', 'es': 'Estrella', 'pt': 'Estrela', 'ko': '별', 'vi': 'Ngôi sao'},
    'sparkles': {'zh': '閃光', 'en': 'Sparkles', 'ja': 'キラキラ', 'es': 'Destellos', 'pt': 'Brilhos', 'ko': '반짝임', 'vi': 'Lấp lánh'},
    // Repair drones
    'bee': {'zh': '蜜蜂', 'en': 'Bee', 'ja': 'ミツバチ', 'es': 'Abeja', 'pt': 'Abelha', 'ko': '꿀벌', 'vi': 'Ong'},
    'wrench': {'zh': '扳手', 'en': 'Wrench', 'ja': 'レンチ', 'es': 'Llave', 'pt': 'Chave', 'ko': '렌치', 'vi': 'Cờ lê'},
    'screwdriver': {'zh': '螺絲起子', 'en': 'Screwdriver', 'ja': 'ドライバー', 'es': 'Destornillador', 'pt': 'Chave de fenda', 'ko': '드라이버', 'vi': 'Tua vít'},
    'magnet': {'zh': '磁鐵', 'en': 'Magnet', 'ja': '磁石', 'es': 'Imán', 'pt': 'Ímã', 'ko': '자석', 'vi': 'Nam châm'},
    'toolbox': {'zh': '工具箱', 'en': 'Toolbox', 'ja': 'ツールボックス', 'es': 'Caja de herramientas', 'pt': 'Caixa de ferramentas', 'ko': '공구함', 'vi': 'Hộp dụng cụ'},
    'ant': {'zh': '螞蟻', 'en': 'Ant', 'ja': 'アリ', 'es': 'Hormiga', 'pt': 'Formiga', 'ko': '개미', 'vi': 'Kiến'},
    'robot': {'zh': '機器人', 'en': 'Robot', 'ja': 'ロボット', 'es': 'Robot', 'pt': 'Robô', 'ko': '로봇', 'vi': 'Robot'},
    // Quantum/Shield
    'atom': {'zh': '原子', 'en': 'Atom', 'ja': '原子', 'es': 'Átomo', 'pt': 'Átomo', 'ko': '원자', 'vi': 'Nguyên tử'},
    'infinity': {'zh': '無限', 'en': 'Infinity', 'ja': '無限', 'es': 'Infinito', 'pt': 'Infinito', 'ko': '무한', 'vi': 'Vô cực'},
    'recycle': {'zh': '回收', 'en': 'Recycle', 'ja': 'リサイクル', 'es': 'Reciclaje', 'pt': 'Reciclagem', 'ko': '재활용', 'vi': 'Tái chế'},
    'dna': {'zh': 'DNA', 'en': 'DNA', 'ja': 'DNA', 'es': 'ADN', 'pt': 'DNA', 'ko': 'DNA', 'vi': 'DNA'},
    'sparkle': {'zh': '火花', 'en': 'Sparkle', 'ja': 'スパークル', 'es': 'Chispa', 'pt': 'Faísca', 'ko': '스파클', 'vi': 'Tia lửa'},
    'cyclone': {'zh': '旋風', 'en': 'Cyclone', 'ja': 'サイクロン', 'es': 'Ciclón', 'pt': 'Ciclone', 'ko': '사이클론', 'vi': 'Lốc xoáy'},
    // Data relay
    'laptop': {'zh': '筆電', 'en': 'Laptop', 'ja': 'ノートPC', 'es': 'Portátil', 'pt': 'Notebook', 'ko': '노트북', 'vi': 'Laptop'},
    'desktop': {'zh': '電腦', 'en': 'Desktop', 'ja': 'デスクトップ', 'es': 'Ordenador', 'pt': 'Computador', 'ko': '데스크탑', 'vi': 'Máy tính'},
    'keyboard': {'zh': '鍵盤', 'en': 'Keyboard', 'ja': 'キーボード', 'es': 'Teclado', 'pt': 'Teclado', 'ko': '키보드', 'vi': 'Bàn phím'},
    'mouse': {'zh': '滑鼠', 'en': 'Mouse', 'ja': 'マウス', 'es': 'Ratón', 'pt': 'Mouse', 'ko': '마우스', 'vi': 'Chuột'},
    'printer': {'zh': '印表機', 'en': 'Printer', 'ja': 'プリンター', 'es': 'Impresora', 'pt': 'Impressora', 'ko': '프린터', 'vi': 'Máy in'},
    'modem': {'zh': '數據機', 'en': 'Modem', 'ja': 'モデム', 'es': 'Módem', 'pt': 'Modem', 'ko': '모뎀', 'vi': 'Modem'},
    // Propulsion
    'rocket': {'zh': '火箭', 'en': 'Rocket', 'ja': 'ロケット', 'es': 'Cohete', 'pt': 'Foguete', 'ko': '로켓', 'vi': 'Tên lửa'},
    'plane': {'zh': '飛機', 'en': 'Plane', 'ja': '飛行機', 'es': 'Avión', 'pt': 'Avião', 'ko': '비행기', 'vi': 'Máy bay'},
    'helicopter': {'zh': '直升機', 'en': 'Helicopter', 'ja': 'ヘリコプター', 'es': 'Helicóptero', 'pt': 'Helicóptero', 'ko': '헬리콥터', 'vi': 'Trực thăng'},
    'satellite': {'zh': '衛星', 'en': 'Satellite', 'ja': '衛星', 'es': 'Satélite', 'pt': 'Satélite', 'ko': '위성', 'vi': 'Vệ tinh'},
    'ufo': {'zh': '飛碟', 'en': 'UFO', 'ja': 'UFO', 'es': 'OVNI', 'pt': 'OVNI', 'ko': 'UFO', 'vi': 'UFO'},
    'comet': {'zh': '彗星', 'en': 'Comet', 'ja': '彗星', 'es': 'Cometa', 'pt': 'Cometa', 'ko': '혜성', 'vi': 'Sao chổi'},
    'meteor': {'zh': '流星', 'en': 'Meteor', 'ja': '流星', 'es': 'Meteoro', 'pt': 'Meteoro', 'ko': '유성', 'vi': 'Sao băng'},
    // AI/Command
    'joystick': {'zh': '搖桿', 'en': 'Joystick', 'ja': 'ジョイスティック', 'es': 'Joystick', 'pt': 'Joystick', 'ko': '조이스틱', 'vi': 'Cần điều khiển'},
    'gamepad': {'zh': '遊戲手把', 'en': 'Gamepad', 'ja': 'ゲームパッド', 'es': 'Mando', 'pt': 'Controle', 'ko': '게임패드', 'vi': 'Tay cầm'},
    'trophy': {'zh': '獎盃', 'en': 'Trophy', 'ja': 'トロフィー', 'es': 'Trofeo', 'pt': 'Troféu', 'ko': '트로피', 'vi': 'Cúp'},
    'medal': {'zh': '獎章', 'en': 'Medal', 'ja': 'メダル', 'es': 'Medalla', 'pt': 'Medalha', 'ko': '메달', 'vi': 'Huy chương'},
    'crown': {'zh': '皇冠', 'en': 'Crown', 'ja': '王冠', 'es': 'Corona', 'pt': 'Coroa', 'ko': '왕관', 'vi': 'Vương miện'},
    'gem': {'zh': '寶石', 'en': 'Gem', 'ja': '宝石', 'es': 'Gema', 'pt': 'Gema', 'ko': '보석', 'vi': 'Đá quý'},
    'diamond': {'zh': '鑽石', 'en': 'Diamond', 'ja': 'ダイヤモンド', 'es': 'Diamante', 'pt': 'Diamante', 'ko': '다이아몬드', 'vi': 'Kim cương'},
    // Year 2 - Mecha parts
    'circuit': {'zh': '電路', 'en': 'Circuit', 'ja': '回路', 'es': 'Circuito', 'pt': 'Circuito', 'ko': '회로', 'vi': 'Mạch'},
    'chip': {'zh': '晶片', 'en': 'Chip', 'ja': 'チップ', 'es': 'Chip', 'pt': 'Chip', 'ko': '칩', 'vi': 'Chip'},
    'wire': {'zh': '電線', 'en': 'Wire', 'ja': 'ワイヤー', 'es': 'Cable', 'pt': 'Fio', 'ko': '전선', 'vi': 'Dây'},
    'bone': {'zh': '骨骼', 'en': 'Bone', 'ja': '骨', 'es': 'Hueso', 'pt': 'Osso', 'ko': '뼈', 'vi': 'Xương'},
    'spine': {'zh': '脊椎', 'en': 'Spine', 'ja': '背骨', 'es': 'Columna', 'pt': 'Coluna', 'ko': '척추', 'vi': 'Cột sống'},
    'heart': {'zh': '心臟', 'en': 'Heart', 'ja': 'ハート', 'es': 'Corazón', 'pt': 'Coração', 'ko': '심장', 'vi': 'Tim'},
    'mechanical_arm': {'zh': '機械臂', 'en': 'Mechanical Arm', 'ja': '機械腕', 'es': 'Brazo mecánico', 'pt': 'Braço mecânico', 'ko': '기계팔', 'vi': 'Cánh tay máy'},
    'mechanical_leg': {'zh': '機械腿', 'en': 'Mechanical Leg', 'ja': '機械脚', 'es': 'Pierna mecánica', 'pt': 'Perna mecânica', 'ko': '기계다리', 'vi': 'Chân máy'},
    'claw': {'zh': '爪子', 'en': 'Claw', 'ja': '爪', 'es': 'Garra', 'pt': 'Garra', 'ko': '발톱', 'vi': 'Móng vuốt'},
    'fist': {'zh': '拳頭', 'en': 'Fist', 'ja': '拳', 'es': 'Puño', 'pt': 'Punho', 'ko': '주먹', 'vi': 'Nắm đấm'},
    'foot': {'zh': '腳', 'en': 'Foot', 'ja': '足', 'es': 'Pie', 'pt': 'Pé', 'ko': '발', 'vi': 'Chân'},
    'leg': {'zh': '腿', 'en': 'Leg', 'ja': '脚', 'es': 'Pierna', 'pt': 'Perna', 'ko': '다리', 'vi': 'Chân'},
    'oil': {'zh': '油', 'en': 'Oil', 'ja': 'オイル', 'es': 'Aceite', 'pt': 'Óleo', 'ko': '기름', 'vi': 'Dầu'},
    'tank': {'zh': '儲槽', 'en': 'Tank', 'ja': 'タンク', 'es': 'Tanque', 'pt': 'Tanque', 'ko': '탱크', 'vi': 'Bể chứa'},
    'pipe': {'zh': '管道', 'en': 'Pipe', 'ja': 'パイプ', 'es': 'Tubería', 'pt': 'Tubo', 'ko': '파이프', 'vi': 'Ống'},
    'valve': {'zh': '閥門', 'en': 'Valve', 'ja': 'バルブ', 'es': 'Válvula', 'pt': 'Válvula', 'ko': '밸브', 'vi': 'Van'},
    'armor': {'zh': '裝甲', 'en': 'Armor', 'ja': 'アーマー', 'es': 'Armadura', 'pt': 'Armadura', 'ko': '갑옷', 'vi': 'Giáp'},
    'helmet': {'zh': '頭盔', 'en': 'Helmet', 'ja': 'ヘルメット', 'es': 'Casco', 'pt': 'Capacete', 'ko': '헬멧', 'vi': 'Mũ bảo hiểm'},
    'visor': {'zh': '護目鏡', 'en': 'Visor', 'ja': 'バイザー', 'es': 'Visor', 'pt': 'Visor', 'ko': '바이저', 'vi': 'Kính che'},
    'radar': {'zh': '雷達', 'en': 'Radar', 'ja': 'レーダー', 'es': 'Radar', 'pt': 'Radar', 'ko': '레이더', 'vi': 'Radar'},
    'jetpack': {'zh': '噴射背包', 'en': 'Jetpack', 'ja': 'ジェットパック', 'es': 'Mochila propulsora', 'pt': 'Mochila a jato', 'ko': '제트팩', 'vi': 'Ba lô phản lực'},
    'thruster': {'zh': '推進器', 'en': 'Thruster', 'ja': 'スラスター', 'es': 'Propulsor', 'pt': 'Propulsor', 'ko': '추진기', 'vi': 'Động cơ đẩy'},
    'exhaust': {'zh': '排氣管', 'en': 'Exhaust', 'ja': '排気', 'es': 'Escape', 'pt': 'Escapamento', 'ko': '배기', 'vi': 'Ống xả'},
    // Year 3 - Data Spire parts
    'cable': {'zh': '電纜', 'en': 'Cable', 'ja': 'ケーブル', 'es': 'Cable', 'pt': 'Cabo', 'ko': '케이블', 'vi': 'Cáp'},
    'fiber': {'zh': '光纖', 'en': 'Fiber', 'ja': 'ファイバー', 'es': 'Fibra', 'pt': 'Fibra', 'ko': '광섬유', 'vi': 'Sợi quang'},
    'foundation': {'zh': '地基', 'en': 'Foundation', 'ja': '基礎', 'es': 'Cimiento', 'pt': 'Fundação', 'ko': '기초', 'vi': 'Nền móng'},
    'pillar': {'zh': '柱子', 'en': 'Pillar', 'ja': '柱', 'es': 'Pilar', 'pt': 'Pilar', 'ko': '기둥', 'vi': 'Cột'},
    'beam': {'zh': '樑', 'en': 'Beam', 'ja': '梁', 'es': 'Viga', 'pt': 'Viga', 'ko': '보', 'vi': 'Dầm'},
    'generator': {'zh': '發電機', 'en': 'Generator', 'ja': '発電機', 'es': 'Generador', 'pt': 'Gerador', 'ko': '발전기', 'vi': 'Máy phát'},
    'turbine': {'zh': '渦輪', 'en': 'Turbine', 'ja': 'タービン', 'es': 'Turbina', 'pt': 'Turbina', 'ko': '터빈', 'vi': 'Tuabin'},
    'pool': {'zh': '水池', 'en': 'Pool', 'ja': 'プール', 'es': 'Piscina', 'pt': 'Piscina', 'ko': '수영장', 'vi': 'Bể'},
    'stairs': {'zh': '樓梯', 'en': 'Stairs', 'ja': '階段', 'es': 'Escaleras', 'pt': 'Escadas', 'ko': '계단', 'vi': 'Cầu thang'},
    'elevator': {'zh': '電梯', 'en': 'Elevator', 'ja': 'エレベーター', 'es': 'Ascensor', 'pt': 'Elevador', 'ko': '엘리베이터', 'vi': 'Thang máy'},
    'server': {'zh': '伺服器', 'en': 'Server', 'ja': 'サーバー', 'es': 'Servidor', 'pt': 'Servidor', 'ko': '서버', 'vi': 'Máy chủ'},
    'rack': {'zh': '機架', 'en': 'Rack', 'ja': 'ラック', 'es': 'Rack', 'pt': 'Rack', 'ko': '랙', 'vi': 'Giá đỡ'},
    'terminal': {'zh': '終端', 'en': 'Terminal', 'ja': 'ターミナル', 'es': 'Terminal', 'pt': 'Terminal', 'ko': '터미널', 'vi': 'Thiết bị đầu cuối'},
    'monitor': {'zh': '螢幕', 'en': 'Monitor', 'ja': 'モニター', 'es': 'Monitor', 'pt': 'Monitor', 'ko': '모니터', 'vi': 'Màn hình'},
    'frame': {'zh': '框架', 'en': 'Frame', 'ja': 'フレーム', 'es': 'Marco', 'pt': 'Quadro', 'ko': '프레임', 'vi': 'Khung'},
    'antenna': {'zh': '天線', 'en': 'Antenna', 'ja': 'アンテナ', 'es': 'Antena', 'pt': 'Antena', 'ko': '안테나', 'vi': 'Ăng-ten'},
    'tower': {'zh': '塔', 'en': 'Tower', 'ja': 'タワー', 'es': 'Torre', 'pt': 'Torre', 'ko': '타워', 'vi': 'Tháp'},
    'panel': {'zh': '面板', 'en': 'Panel', 'ja': 'パネル', 'es': 'Panel', 'pt': 'Painel', 'ko': '패널', 'vi': 'Tấm'},
    'curtain': {'zh': '帷幕', 'en': 'Curtain', 'ja': 'カーテン', 'es': 'Cortina', 'pt': 'Cortina', 'ko': '커튼', 'vi': 'Rèm'},
    'drone': {'zh': '無人機', 'en': 'Drone', 'ja': 'ドローン', 'es': 'Dron', 'pt': 'Drone', 'ko': '드론', 'vi': 'Drone'},
    'port': {'zh': '港口', 'en': 'Port', 'ja': 'ポート', 'es': 'Puerto', 'pt': 'Porto', 'ko': '포트', 'vi': 'Cổng'},
    'quantum': {'zh': '量子', 'en': 'Quantum', 'ja': '量子', 'es': 'Cuántico', 'pt': 'Quântico', 'ko': '양자', 'vi': 'Lượng tử'},
    'chamber': {'zh': '室', 'en': 'Chamber', 'ja': 'チェンバー', 'es': 'Cámara', 'pt': 'Câmara', 'ko': '챔버', 'vi': 'Buồng'},
    'rod': {'zh': '桿', 'en': 'Rod', 'ja': 'ロッド', 'es': 'Varilla', 'pt': 'Haste', 'ko': '막대', 'vi': 'Thanh'},
    'spire': {'zh': '尖塔', 'en': 'Spire', 'ja': '尖塔', 'es': 'Aguja', 'pt': 'Pináculo', 'ko': '첨탑', 'vi': 'Tháp nhọn'},
    'neon': {'zh': '霓虹', 'en': 'Neon', 'ja': 'ネオン', 'es': 'Neón', 'pt': 'Néon', 'ko': '네온', 'vi': 'Neon'},
    'cloud': {'zh': '雲端', 'en': 'Cloud', 'ja': 'クラウド', 'es': 'Nube', 'pt': 'Nuvem', 'ko': '클라우드', 'vi': 'Đám mây'},
    'data': {'zh': '數據', 'en': 'Data', 'ja': 'データ', 'es': 'Datos', 'pt': 'Dados', 'ko': '데이터', 'vi': 'Dữ liệu'},
    'stream': {'zh': '串流', 'en': 'Stream', 'ja': 'ストリーム', 'es': 'Flujo', 'pt': 'Fluxo', 'ko': '스트림', 'vi': 'Luồng'},
  };
}
