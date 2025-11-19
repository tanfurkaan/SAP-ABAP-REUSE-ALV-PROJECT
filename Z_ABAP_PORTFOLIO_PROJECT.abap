*&---------------------------------------------------------------------*
*& Report  ZFTK_EGT_0022 (Portfolio Version)
*&---------------------------------------------------------------------*
*& Description: Bu rapor, SCARR ve SFLIGHT tablolarını kullanarak 
*&              dinamik ALV raporlaması, hücre renklendirme ve 
*&              interaktif kullanıcı komutlarını içerir.
*&---------------------------------------------------------------------*
REPORT zftk_egt_0022.

*======================================================================*
* 1. DATA VE TİP TANIMLAMALARI (TOP KISMI)
*======================================================================*
TYPES: BEGIN OF gty_list,
         selkz      TYPE char1,                " Seçim kutusu
         carrid     TYPE s_carr_id,            " Havayolu Kodu
         carrname   TYPE s_carrname,           " Havayolu Adı
         fldate     TYPE s_date,               " Uçuş Tarihi
         connid     TYPE s_conn_id,            " Bağlantı No
         line_color TYPE char4,                " Satır Rengi
         cell_color TYPE slis_t_specialcol_alv," Hücre Rengi
       END OF gty_list.

DATA: gs_cell_color TYPE slis_specialcol_alv.

DATA: gs_list TYPE gty_list,
      gt_list TYPE TABLE OF gty_list.

DATA: gt_fieldcatalog TYPE slis_t_fieldcat_alv,
      gs_fieldcatalog TYPE slis_fieldcat_alv.

DATA: gs_layout TYPE slis_layout_alv.

DATA: gt_events TYPE slis_t_event,
      gs_event  TYPE slis_alv_event.

DATA: gt_exclude TYPE slis_t_extab,
      gs_exclude TYPE slis_extab.

DATA: gt_sort TYPE slis_t_sortinfo_alv,
      gs_sort TYPE slis_sortinfo_alv.

DATA: gt_filter TYPE slis_t_filter_alv,
      gs_filter TYPE slis_filter_alv.

*======================================================================*
* 2. ANA PROGRAM MANTIĞI (START-OF-SELECTION)
*======================================================================*
START-OF-SELECTION.

  PERFORM get_data.
  PERFORM set_fc.
  PERFORM set_layout.
  PERFORM display_alv.

*======================================================================*
* 3. ALT PROGRAMLAR (FORMS)
*======================================================================*

*--- Veri Çekme ve İşleme ---*
FORM get_data.
  SELECT scarr~carrid scarr~carrname sflight~fldate sflight~connid
    INTO CORRESPONDING FIELDS OF TABLE gt_list
    FROM scarr
    INNER JOIN sflight ON sflight~carrid EQ scarr~carrid.

  " Mantıksal işlemler ve Renklendirme
  LOOP AT gt_list INTO gs_list.
    IF gs_list-connid EQ '400'.
      gs_list-line_color = 'C410'. " Mavi tonu
      MODIFY gt_list FROM gs_list.
    ELSEIF gs_list-connid EQ '555'.
      gs_list-line_color = 'C710'. " Turuncu tonu
      MODIFY gt_list FROM gs_list.
    ENDIF.
  ENDLOOP.
ENDFORM.

*--- Field Catalog (Sütun Ayarları) ---*
FORM set_fc.
  PERFORM set_fc_sub USING 'CARRID'   'X' 'S.Kod'    'Şirket Kod'   'Şirket Kod'        '' ''.
  PERFORM set_fc_sub USING 'CARRNAME' ''  'S.Ad'     'Şirket Ad'    'Şirket Adı'        '' 'X'.
  PERFORM set_fc_sub USING 'FLDATE'   ''  'U.Tarih'  'Uçuş Tarihi'  'Uçuş Tarihi'       '' 'X'.
  PERFORM set_fc_sub USING 'CONNID'   ''  'B.No.'    'Bağ. Num.'    'Bağlantı Numarası' 'X' ''.
ENDFORM.

FORM set_fc_sub USING p_fieldname p_key p_seltext_s p_seltext_m p_seltext_l p_do_sum p_hotspot.
  CLEAR: gs_fieldcatalog.
  gs_fieldcatalog-fieldname = p_fieldname.
  gs_fieldcatalog-key       = p_key.
  gs_fieldcatalog-seltext_s = p_seltext_s.
  gs_fieldcatalog-seltext_m = p_seltext_m.
  gs_fieldcatalog-seltext_l = p_seltext_l.
  gs_fieldcatalog-do_sum    = p_do_sum.
  gs_fieldcatalog-hotspot   = p_hotspot.
  APPEND gs_fieldcatalog TO gt_fieldcatalog.
ENDFORM.

*--- Layout Ayarları ---*
FORM set_layout.
  gs_layout-window_titlebar    = 'REUSE ALV Portfolyo Projesi'.
  gs_layout-zebra              = abap_true.
  gs_layout-colwidth_optimize  = abap_true.
  gs_layout-box_fieldname      = 'SELKZ'.
  gs_layout-info_fieldname     = 'LINE_COLOR'.
  gs_layout-coltab_fieldname   = 'CELL_COLOR'.
ENDFORM.

*--- Rapor Başlığı (Top of Page) ---*
FORM top_of_page.
  DATA: lt_header TYPE slis_t_listheader,
        ls_header TYPE slis_listheader.
  DATA: lv_date TYPE char10.

  CLEAR: ls_header.
  ls_header-typ  = 'H'.
  ls_header-info = 'Havaalanı Uçak Takip Listesi'.
  APPEND ls_header TO lt_header.

  CLEAR: ls_header.
  ls_header-typ = 'S'.
  ls_header-key = 'Tarih'.
  CONCATENATE sy-datum+6(2) '.' sy-datum+4(2) '.' sy-datum+0(4) INTO lv_date.
  ls_header-info = lv_date.
  APPEND ls_header TO lt_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.

*--- Rapor Sonu (End of List) ---*
FORM end_of_list.
  DATA: lt_header  TYPE slis_t_listheader,
        ls_header  TYPE slis_listheader.
  DATA: lv_lines   TYPE i,
        lv_lines_c TYPE char10.

  CLEAR: ls_header.
  DESCRIBE TABLE gt_list LINES lv_lines.
  lv_lines_c = lv_lines.

  ls_header-typ = 'A'.
  CONCATENATE 'Bu rapor' lv_lines_c 'satırdan oluşmaktadır.'
              INTO ls_header-info SEPARATED BY space.
  APPEND ls_header TO lt_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.

*--- PF Status (Butonlar) ---*
FORM pf_status_set USING p_extab TYPE slis_t_extab.
  SET PF-STATUS 'STANDARD'. " Not: Github'da bu status'un ekran görüntüsü de eklenebilir.
ENDFORM.

*--- User Command (Tıklama İşlemleri) ---*
FORM user_command USING p_ucomm TYPE sy-ucomm
                        ps_selfield TYPE slis_selfield.
  DATA: lv_mes TYPE char200,
        lv_ind TYPE numc2.

  CASE p_ucomm.
    WHEN '&MSG'.
      LOOP AT gt_list INTO gs_list WHERE selkz EQ 'X'.
        lv_ind = lv_ind + 1.
      ENDLOOP.
      CONCATENATE lv_ind 'sayı kadar satır seçildi' INTO lv_mes SEPARATED BY space.
      MESSAGE lv_mes TYPE 'I'.
      
    WHEN '&DEN'.
      MESSAGE 'Deneme butonuna basıldı' TYPE 'I'.
      
    WHEN '&IC1'. " Çift Tıklama
      CASE ps_selfield-fieldname.
        WHEN 'FLDATE'.
          CONCATENATE ps_selfield-value 'tarihine bastınız' INTO lv_mes SEPARATED BY space.
          MESSAGE lv_mes TYPE 'I'.
        WHEN 'CARRNAME'.
          CONCATENATE ps_selfield-value 'isimli uçağa tıkladınız' INTO lv_mes SEPARATED BY space.
          MESSAGE lv_mes TYPE 'I'.
      ENDCASE.
  ENDCASE.
ENDFORM.

*--- ALV Görüntüleme ---*
FORM display_alv.
  " Event'leri Tanımla
  gs_event-name = slis_ev_top_of_page.
  gs_event-form = 'TOP_OF_PAGE'.
  APPEND gs_event TO gt_events.

  gs_event-name = slis_ev_end_of_list.
  gs_event-form = 'END_OF_LIST'.
  APPEND gs_event TO gt_events.

  gs_event-name = slis_ev_pf_status_set.
  gs_event-form = 'PF_STATUS_SET'.
  APPEND gs_event TO gt_events.

  gs_event-name = slis_ev_user_command.
  gs_event-form = 'USER_COMMAND'.
  APPEND gs_event TO gt_events.

  " İstenmeyen butonları kaldır
  gs_exclude-fcode = '&UMC'.
  APPEND gs_exclude TO gt_exclude.

  " Sıralama ekle
  gs_sort-spos = 1.
  gs_sort-tabname = 'GT_LIST'.
  gs_sort-fieldname = 'FLDATE'.
  gs_sort-up = abap_true.
  APPEND gs_sort TO gt_sort.

  " ALV'yi Çağır
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = sy-repid
      is_layout               = gs_layout
      it_fieldcat             = gt_fieldcatalog
      it_excluding            = gt_exclude
      it_sort                 = gt_sort
      it_filter               = gt_filter
      it_events               = gt_events
    TABLES
      t_outtab                = gt_list
    EXCEPTIONS
      program_error           = 1
      OTHERS                  = 2.
  
  IF sy-subrc <> 0.
    MESSAGE 'ALV Gösteriminde Hata Oluştu' TYPE 'E'.
  ENDIF.
ENDFORM.