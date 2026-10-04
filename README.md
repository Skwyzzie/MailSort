# MailSort
A cross-platform mail sorting program built for forward operating locations and designed to work seamlessly with AMPS. Built with Flutter, MailSort handles bulk PDF manifesting, hardware barcode scanning, and custom PDF report generation.

## 🚀 Core Features
* **Ubiquitous Hardware Scanning:** Utilizes a global background listener to intercept rapid keystrokes from hardware scanners on any screen, allowing continuous scanning without needing a focused text field.
* **Intelligent PDF Import Pipeline:** Converts multi-page PDF manifests into high-resolution images and uses Google ML Kit Text Recognition (OCR) to extract package data.
* **Advanced Data Extraction:** Employs spatial sorting, anchor-based Regex parsing, and Modulo-10 checksum validation to isolate 22-digit and 30-digit tracking numbers.
* **Automated Blacklisting:** Automatically rejects internal warehouse labels (such as Amazon FNSKU) and corrupted 2D MaxiCode fragments during the scan process.
* **Custom PDF Exporting:** Superimposes validated tracking data, checkmarks, and slip numbers onto high-resolution template images to generate perfectly aligned export reports.
* **Reactive Local Database:** Powered by Hive, the dashboard and history tables update instantly via `ValueListenableBuilder` when new packages are scanned, imported, or manually added.
* **Customizable Settings:** Allows users to manage default assignment branches, clear database records, set default Bill IDs, and toggle dark mode dynamically.

## 🏗️ Technical Architecture
### 1. The Import Engine
When a user imports a PDF, the app uses `pdfx` to render each page at a 2x scale. Google ML Kit processes these high-contrast images, returning bounding boxes for all detected text. MailSort mathematically sorts these bounding boxes into header, footer, and column zones, applying Regex to pull metadata (like Delivery Date and Bill ID) and valid tracking numbers.

### 2. The Scanning & Reconciliation System
The application is wrapped in a `BarcodeKeyboardListener` at the AppShell level. When a tracking number is scanned, the app checks the Hive database:
* If the package was previously imported from a PDF manifest (status: Pending), its status is updated to Scanned and the timestamp is logged.
* If it is an unmanifested package, it is added to the database as a new "Slipless" entry.

### 3. The Export Engine
Using the `pdf` package, MailSort constructs new documents by layering `MemoryImage` templates as full-bleed backgrounds. Package data is dynamically laid out using PDF point coordinates (where 72 points = 1 inch), generating multi-page reports with up to 50 tracking numbers per page.

## 🛠️ Tech Stack & Dependencies

* **Framework:** Flutter (Dart) - Cross-platform support (Android, Windows, iOS, macOS)

* **Local Storage:** `hive_flutter` for high-performance, NoSQL local data persistence

* **PDF Rendering:** `pdfx` for rasterizing imported documents

* **OCR / Vision:** `google_mlkit_text_recognition` for on-device text extraction

* **PDF Generation:** `pdf` for building custom superimposed export files

* **Hardware Integration:** `flutter_barcode_listener` for capturing external scanner input


## 💻 Getting Started

### Prerequisites

* Flutter SDK (latest stable)
* Android Studio / Visual Studio (for Windows compilation)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Skwyzzie/MailSort.git

```

2. Fetch dependencies:
```bash
flutter pub get

```

3. Generate Hive type adapters (if modifying models):
```bash
flutter pub run build_runner build

```

4. Run the application:
```bash
flutter run

```