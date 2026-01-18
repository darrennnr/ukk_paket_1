graph TD
    Start([Mulai Pembuatan Sistem]) --> Phase1[FASE 1: SETUP & KONFIGURASI]
    
    Phase1 --> A1[Setup Flutter Project]
    A1 --> A2[Konfigurasi Multi-platform<br/>Web & Android]
    A2 --> A3[Install Dependencies:<br/>- http/dio<br/>- provider/bloc<br/>- shared_preferences<br/>- flutter_secure_storage]
    A3 --> A4[Setup Environment Config<br/>API Base URL]
    
    A4 --> Phase2[FASE 2: ARSITEKTUR & STRUKTUR]
    
    Phase2 --> B1[Buat Folder Structure:<br/>- lib/models<br/>- lib/services<br/>- lib/screens<br/>- lib/widgets<br/>- lib/utils]
    B1 --> B2[Setup State Management<br/>Provider/Bloc/GetX]
    B2 --> B3[Buat Config Routes/Navigation]
    
    B3 --> Phase3[FASE 3: LAYER MODELS & SERVICES]
    
    Phase3 --> C1[Buat Model Classes:<br/>- User, Role<br/>- TipeHewan, Hewan<br/>- Penitipan<br/>- TipeTreatment<br/>- DailyTreatment<br/>- Pembayaran]
    C1 --> C2[Buat API Service Class<br/>Base HTTP Client]
    C2 --> C3[Implement Auth Service:<br/>- login<br/>- getMe<br/>- token management]
    C3 --> C4[Implement CRUD Services:<br/>- UserService<br/>- TipeHewanService<br/>- HewanService<br/>- PenitipanService<br/>- TreatmentService<br/>- PembayaranService]
    C4 --> C5[Implement Report Service:<br/>- Treatment per Hewan<br/>- Income per Period]
    C5 --> C6[Implement Import/Export Service]
    
    C6 --> Phase4[FASE 4: AUTHENTICATION MODULE]
    
    Phase4 --> D1[Buat Login Screen<br/>Form & Validation]
    D1 --> D2[Implement Authentication Logic:<br/>- Login API call<br/>- Store token securely<br/>- Handle response]
    D2 --> D3[Buat Auth Provider/Bloc<br/>Manage auth state]
    D3 --> D4[Setup Auth Guard/Middleware<br/>Protect routes]
    D4 --> D5[Implement Auto-login<br/>Check stored token]
    
    D5 --> Phase5[FASE 5: DASHBOARD & NAVIGATION]
    
    Phase5 --> E1[Buat Main Layout:<br/>- AppBar<br/>- Drawer/Bottom Nav<br/>- Responsive design]
    E1 --> E2[Buat Dashboard Screen<br/>Statistik overview]
    E2 --> E3[Implement Role-based Menu:<br/>Admin, Petugas, Owner]
    E3 --> E4[Setup Navigation Logic]
    
    E4 --> Phase6[FASE 6: MASTER DATA MODULES]
    
    Phase6 --> F1[Module User Management:<br/>- List users screen<br/>- Form create/edit<br/>- Delete confirmation]
    F1 --> F2[Module Tipe Hewan:<br/>- List screen + DataTable<br/>- Form CRUD<br/>- Import/Export Excel]
    F2 --> F3[Module Hewan:<br/>- List dengan filter owner<br/>- Form dengan dropdown tipe<br/>- Import/Export]
    F3 --> F4[Module Tipe Treatment:<br/>- List screen<br/>- Form CRUD<br/>- Import/Export]
    
    F4 --> Phase7[FASE 7: TRANSAKSI PENITIPAN]
    
    Phase7 --> G1[Buat List Penitipan Screen:<br/>- Filter by status<br/>- Search function<br/>- Status badge]
    G1 --> G2[Buat Form Penitipan:<br/>- Dropdown hewan<br/>- Date picker check-in/out<br/>- Auto calculate days & price]
    G2 --> G3[Implement Create Logic:<br/>- Validation<br/>- API call<br/>- Success notification]
    G3 --> G4[Implement Update/Checkout:<br/>- Edit check-out date<br/>- Recalculate price<br/>- Change status]
    G4 --> G5[Detail Penitipan Screen<br/>Show all info + treatments]
    G5 --> G6[Export Penitipan to Excel]
    
    G6 --> Phase8[FASE 8: DAILY TREATMENT MODULE]
    
    Phase8 --> H1[Buat List Treatment Screen:<br/>- Filter by penitipan<br/>- Filter by date<br/>- Group by date]
    H1 --> H2[Buat Form Treatment:<br/>- Select penitipan aktif<br/>- Select petugas<br/>- Date picker<br/>- Checkbox tipe treatment<br/>- Notes textarea]
    H2 --> H3[Implement Create Treatment:<br/>- Send tipe_treatment_ids array<br/>- Handle many-to-many relation]
    H3 --> H4[Detail Treatment Screen<br/>Show treatment types]
    H4 --> H5[Implement Edit & Delete]
    
    H5 --> Phase9[FASE 9: PEMBAYARAN MODULE]
    
    Phase9 --> I1[Buat List Pembayaran:<br/>- Filter by penitipan<br/>- Show payment status]
    I1 --> I2[Buat Form Pembayaran:<br/>- Select penitipan<br/>- Input amount<br/>- Select payment method<br/>- Date picker]
    I2 --> I3[Implement Payment Logic:<br/>- Validation<br/>- Create payment<br/>- Update penitipan status]
    I3 --> I4[Payment Receipt Screen<br/>Print/Export]
    
    I4 --> Phase10[FASE 10: LAPORAN/REPORTS]
    
    Phase10 --> J1[Laporan Treatment per Hewan:<br/>- Select hewan<br/>- Show all treatments<br/>- Display statistics]
    J1 --> J2[Export Treatment Report<br/>Excel format]
    J2 --> J3[Laporan Pemasukan:<br/>- Date range picker<br/>- Show total income<br/>- List all payments<br/>- Chart visualization]
    J3 --> J4[Export Income Report<br/>Excel with summary]
    
    J4 --> Phase11[FASE 11: UI/UX ENHANCEMENT]
    
    Phase11 --> K1[Implement Loading States<br/>Skeleton/Shimmer]
    K1 --> K2[Implement Error Handling:<br/>- Network errors<br/>- API errors<br/>- Show error messages]
    K2 --> K3[Add Form Validations:<br/>- Required fields<br/>- Email format<br/>- Phone format<br/>- Date validations]
    K3 --> K4[Implement Notifications:<br/>- Success toast<br/>- Error snackbar<br/>- Confirmation dialogs]
    K4 --> K5[Add Search & Filter:<br/>- Search bars<br/>- Filter dropdowns<br/>- Sort options]
    K5 --> K6[Responsive Design:<br/>- Mobile layout<br/>- Tablet layout<br/>- Web layout]
    K6 --> K7[Add Animations & Transitions]
    
    K7 --> Phase12[FASE 12: TESTING & DEBUGGING]
    
    Phase12 --> L1[Unit Testing:<br/>- Test models<br/>- Test services<br/>- Test validators]
    L1 --> L2[Widget Testing:<br/>- Test forms<br/>- Test navigation<br/>- Test interactions]
    L2 --> L3[Integration Testing:<br/>- Test complete flows<br/>- Test API integration]
    L3 --> L4[Manual Testing:<br/>- Test semua fitur<br/>- Test di berbagai device<br/>- Test role-based access]
    L4 --> L5[Bug Fixing & Optimization]
    
    L5 --> Phase13[FASE 13: DOKUMENTASI]
    
    Phase13 --> M1[Buat User Manual:<br/>- Cara login<br/>- Panduan tiap modul<br/>- Screenshot]
    M1 --> M2[Buat Technical Documentation:<br/>- Architecture diagram<br/>- API integration guide<br/>- Deployment guide]
    M2 --> M3[Code Documentation:<br/>- Comments<br/>- README.md]
    
    M3 --> Complete([Sistem Selesai 100%<br/>Siap Deployment])
    
    style Start fill:#e1f5e1
    style Complete fill:#e1f5e1
    style Phase1 fill:#fff3cd
    style Phase2 fill:#fff3cd
    style Phase3 fill:#fff3cd
    style Phase4 fill:#d1ecf1
    style Phase5 fill:#d1ecf1
    style Phase6 fill:#f8d7da
    style Phase7 fill:#f8d7da
    style Phase8 fill:#f8d7da
    style Phase9 fill:#f8d7da
    style Phase10 fill:#d4edda
    style Phase11 fill:#e2e3e5
    style Phase12 fill:#fff3cd
    style Phase13 fill:#cfe2ff