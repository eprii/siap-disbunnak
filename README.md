# SIAP (Sistem Informasi-Administrasi Pegawai) Dinas Perkebunan dan Pertanian Provinsi Kalimantan Selatan



```
sikap_disbunnak
├─ .firebase
│  └─ hosting.YnVpbGRcd2Vi.cache
├─ .firebaserc
├─ .metadata
├─ analysis_options.yaml
├─ firebase.json
├─ lib
│  ├─ config
│  │  ├─ app_routes.dart
│  │  ├─ app_theme.dart
│  │  ├─ firebase_options.dart
│  │  ├─ sk_definitions.dart
│  │  └─ supabase_config.dart
│  ├─ firebase_options.dart
│  ├─ main.dart
│  ├─ models
│  │  ├─ comment_model.dart
│  │  ├─ notification_model.dart
│  │  ├─ profilepegawai_model.dart
│  │  ├─ reply_model.dart
│  │  ├─ riwayat
│  │  │  ├─ riwayat_diklat_model.dart
│  │  │  └─ riwayat_pendidikan_model.dart
│  │  ├─ sk
│  │  │  ├─ sk_angka_kredit_model.dart
│  │  │  ├─ sk_cpns_model.dart
│  │  │  ├─ sk_cuti_model.dart
│  │  │  ├─ sk_diklat_model.dart
│  │  │  ├─ sk_jabatan_model.dart
│  │  │  ├─ sk_kgb_model.dart
│  │  │  ├─ sk_pangkat_model.dart
│  │  │  ├─ sk_pendidikan_model.dart
│  │  │  ├─ sk_penghargaan_model.dart
│  │  │  ├─ sk_penugasan_tim_model.dart
│  │  │  └─ sk_pns_model.dart
│  │  └─ users_model.dart
│  ├─ pages
│  │  ├─ data_tersimpan
│  │  │  └─ data_tersimpan_page.dart
│  │  ├─ home
│  │  │  ├─ home_page.dart
│  │  │  └─ home_page.dart.old
│  │  ├─ kelola_data
│  │  │  ├─ form_sk
│  │  │  │  ├─ form_sk_angka_kredit_page.dart
│  │  │  │  ├─ form_sk_cpns_page.dart
│  │  │  │  ├─ form_sk_cuti_page.dart
│  │  │  │  ├─ form_sk_diklat_page.dart
│  │  │  │  ├─ form_sk_jabatan_page.dart
│  │  │  │  ├─ form_sk_kgb_page.dart
│  │  │  │  ├─ form_sk_pangkat_page.dart
│  │  │  │  ├─ form_sk_pendidikan_page.dart
│  │  │  │  ├─ form_sk_penghargaan_page.dart
│  │  │  │  ├─ form_sk_penugasan_tim_page.dart
│  │  │  │  ├─ form_sk_pns_page.dart
│  │  │  │  └─ v
│  │  │  ├─ kelola_data_page.dart
│  │  │  └─ pilih_pegawai_page.dart
│  │  ├─ login
│  │  │  ├─ forgot_password_page.dart
│  │  │  └─ login_page.dart
│  │  ├─ notifications
│  │  │  └─ notification_page.dart
│  │  ├─ pages
│  │  │  └─ profile
│  │  │     ├─ admin_profile_page.dart
│  │  │     └─ admin_sk_explorer_page.dart
│  │  ├─ pegawai
│  │  │  └─ detail_pegawai_page.dart
│  │  ├─ pratinjau_dokumen
│  │  │  └─ pratinjau_pdf_page.dart
│  │  ├─ profile
│  │  │  ├─ admin_profile_page.dart
│  │  │  ├─ admin_sk_explorer_page.dart
│  │  │  ├─ edit_profile_page.dart
│  │  │  └─ profile_page.dart
│  │  ├─ register
│  │  │  └─ register_page.dart
│  │  ├─ riwayat
│  │  │  ├─ diklat
│  │  │  │  ├─ form_riwayat_diklat_page.dart
│  │  │  │  └─ riwayat_diklat_page.dart
│  │  │  └─ pendidikan
│  │  │     ├─ form_riwayat_pendidikan_page.dart
│  │  │     └─ riwayat_pendidikan_page.dart
│  │  ├─ saved_sk
│  │  │  └─ admin
│  │  │     └─ saved_sk_page.dart
│  │  ├─ splash
│  │  │  └─ splash_screen.dart
│  │  └─ upload_sk
│  │     └─ upload_sk_page.dart
│  ├─ services
│  │  ├─ admin_dashboard_service.dart
│  │  ├─ admin_sk_explorer_service.dart
│  │  ├─ admin_sk_review_service.dart
│  │  ├─ admin_user_service.dart
│  │  ├─ auth_service.dart
│  │  ├─ employee_sk_file_service.dart
│  │  ├─ employee_sk_management_service.dart
│  │  ├─ firestore_service.dart
│  │  ├─ notification_service.dart
│  │  ├─ pegawai_directory_service.dart
│  │  ├─ profile_account_service.dart
│  │  ├─ profile_completion_service.dart
│  │  ├─ profile_photo_service.dart
│  │  ├─ profile_service.dart
│  │  ├─ saved_sk_service.dart
│  │  ├─ saved_user_service.dart
│  │  ├─ sk_comment_service.dart
│  │  ├─ sk_document_service.dart
│  │  ├─ sk_firestore_service.dart
│  │  ├─ storage_service.dart
│  │  ├─ supabase_storage_service.dart
│  │  └─ whatsapp_service.dart
│  ├─ utils
│  │  ├─ common_first_names.dart
│  │  ├─ date_formatter.dart
│  │  ├─ dropdown_options.dart
│  │  ├─ file_helper.dart
│  │  └─ validators.dart
│  └─ widgets
│     ├─ feedback
│     │  └─ siap_top_notification.dart
│     ├─ navigation
│     │  └─ bottom_navigation_bar.dart
│     ├─ profile
│     │  └─ pegawai_avatar.dart
│     └─ sk
│        ├─ sk_pdf_picker.dart
│        ├─ sk_section_card.dart
│        ├─ sk_text_field.dart
│        └─ user_sk_dashboard.dart
├─ pubspec.lock
├─ pubspec.yaml
├─ README.md
└─ sikap_disbunnak.zip

```
