LIST P=16F628A
    INCLUDE "P16F628A.INC"
    __CONFIG _WDT_OFF & _INTOSC_OSC_NOCLKOUT & _MCLRE_ON & _LVP_OFF

    CBLOCK 0x20
    SAYAC       ; Toplam yolcu (0-100)
    BIRLER      ; Birler basamağı verisi
    ONLAR       ; Onlar basamağı verisi
    S1, S2      ; Gecikme döngüleri
    ENDC

    ORG 0x00
    GOTO BASLAT

; --- 7 SEGMENT TABLOSU ---
TABLO:
    ADDWF   PCL, F
    RETLW   B'00111111' ; 0
    RETLW   B'00000110' ; 1
    RETLW   B'01011011' ; 2
    RETLW   B'01001111' ; 3
    RETLW   B'01100110' ; 4
    RETLW   B'01101101' ; 5
    RETLW   B'01111101' ; 6
    RETLW   B'00000111' ; 7
    RETLW   B'01111111' ; 8
    RETLW   B'01101111' ; 9

BASLAT
    MOVLW   0x07
    MOVWF   CMCON       ; Komparatörleri kapat (Dijital Giriş için şart)
    BANKSEL TRISA
    MOVLW   B'00000011' ; RA0-RA1 Giriş, Diğerleri Çıkış
    MOVWF   TRISA
    CLRF    TRISB       ; PORTB Komple Çıkış
    BANKSEL PORTA
    CLRF    SAYAC       ; Başlangıçta 0 yolcu
    BSF     PORTA, 3    ; Ekranları başta kapat (1 = Kapalı)
    BSF     PORTA, 4

ANA_DONGU:
    CALL    BASAMAK_AYIR
    CALL    EKRAN_GOSTER

    ; --- BINEN BUTONU (RA0) ---
    BTFSC   PORTA, 0    ; Butona basıldı mı? (0 mı?)
    GOTO    INEN_BAK    ; Hayır, inene bak
    
    MOVLW   D'100'      ; 100 kişi kontrolü
    XORWF   SAYAC, W
    BTFSC   STATUS, Z
    GOTO    ANA_DONGU   ; 100 ise daha artırma
    
    INCF    SAYAC, F    ; Yolcu ekle
    CALL    BIRAK_BEKLE ; Elini çekene kadar ekranı tazele ve bekle
    GOTO    ANA_DONGU

INEN_BAK:
    ; --- INEN BUTONU (RA1) ---
    BTFSC   PORTA, 1
    GOTO    LED_KONTROL
    
    MOVF    SAYAC, F    ; 0 kontrolü
    BTFSC   STATUS, Z
    GOTO    ANA_DONGU   ; 0 ise daha düşürme
    
    DECF    SAYAC, F    ; Yolcu çıkar
    CALL    BIRAK_BEKLE
    GOTO    ANA_DONGU

LED_KONTROL:
    MOVLW   D'100'
    XORWF   SAYAC, W
    BTFSC   STATUS, Z
    BSF     PORTA, 2    ; 100 ise DOLU LED'ini yak
    BTFSS   STATUS, Z
    BCF     PORTA, 2    ; Değilse söndür
    GOTO    ANA_DONGU

; --- ALT PROGRAMLAR ---

BASAMAK_AYIR:
    CLRF    ONLAR
    MOVF    SAYAC, W
    MOVWF   BIRLER
    
    MOVLW   D'100'      ; Eğer 100 ise ekranda 00 göster
    XORWF   SAYAC, W
    BTFSC   STATUS, Z
    GOTO    YUZ_OLDU
    
BOL_10:
    MOVLW   D'10'
    SUBWF   BIRLER, W
    BTFSS   STATUS, C
    RETURN
    MOVWF   BIRLER
    INCF    ONLAR, F
    GOTO    BOL_10

YUZ_OLDU:
    CLRF    BIRLER
    CLRF    ONLAR
    RETURN

EKRAN_GOSTER:
    ; Birler Basamağı (RA4 Aktif)
    BSF     PORTA, 3    ; Onlar Kapalı
    MOVF    BIRLER, W
    CALL    TABLO
    MOVWF   PORTB
    BCF     PORTA, 4    ; Birler Açık (0 ile)
    CALL    GECIKME
    
    ; Onlar Basamağı (RA3 Aktif)
    BSF     PORTA, 4    ; Birler Kapalı
    MOVF    ONLAR, W
    CALL    TABLO
    MOVWF   PORTB
    BCF     PORTA, 3    ; Onlar Açık (0 ile)
    CALL    GECIKME
    RETURN

BIRAK_BEKLE:
    ; Butondan elini çekene kadar ekranın sönmemesini sağlar
    CALL    BASAMAK_AYIR
    CALL    EKRAN_GOSTER
    BTFSS   PORTA, 0    ; RA0 hala basılı mı?
    GOTO    BIRAK_BEKLE
    BTFSS   PORTA, 1    ; RA1 hala basılı mı?
    GOTO    BIRAK_BEKLE
    RETURN

GECIKME:
    MOVLW   D'255'      ; Simülasyon titrememesi için uygun değer
    MOVWF   S1
L1: DECFSZ  S1, F
    GOTO    L1
    RETURN

    END