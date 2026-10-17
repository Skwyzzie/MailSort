# MailSort Documentation

**MailSort** is a cross-platform mail sorting application developed with Flutter, engineered specifically for forward operating locations and designed to integrate seamlessly with the Automated Military Postal System (AMPS). It streamlines bulk package intake, barcode reconciliation, and manifest reporting without requiring an active internet connection.

---

## Overview & Architecture

MailSort operates entirely locally using an on-device embedded database and computer vision pipeline to ensure operational security and high performance.

```
┌────────────────────────┐      ┌─────────────────────────┐
│ Hardware Scanner / UI  │      │   AMPS PDF Manifests    │
└───────────┬────────────┘      └────────────┬────────────┘
            │ Keystrokes                     │ Rasterize & OCR
            ▼                                ▼
┌─────────────────────────────────────────────────────────┐
│                     MailSort Core                       │
│  - Spatial Zone Sorting & Anchor Regex                  │
│  - Modulo-10 Validation & Blacklist Filtering           │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
              ┌───────────────────────────┐
              │    Local Storage (Hive)   │
              │  - Packages, Slips, Scans │
              └─────────────┬─────────────┘
                            │
                            ▼
              ┌───────────────────────────┐
              │ Custom PDF Export Service │
              │  - Superimposed Markups   │
              └───────────────────────────┘

```

---

## Core Features

### 1. Ubiquitous Hardware Scanning

* **Global Input Listener:** Integrates a keyboard listener at the root shell level (`AppShell`), intercepting rapid keystrokes from connected handheld barcode scanners across any screen.


* **Focus-Free Operation:** Users do not need to tap or focus on a text field to record scans.


* **Manual Entry Fallback:** Provides a dedicated modal interface for manual keyboard entry when labels are unreadable or physically damaged.

### 2. Digital PDF Manifest Ingestion

* **High-Resolution Rasterization:** Ingests multi-page AMPS PDF manifests and converts each page to a 2x scaled image buffer.


* **On-Device Vision (OCR):** Utilizes Google ML Kit Text Recognition locally to detect text blocks and bounding boxes across manifest sheets.



### 3. Intelligent Data Extraction & Validation

* **Spatial Cropping & Column Sorting:** Mathematically calculates header (top 15%), footer (bottom 15%), and column body zones to reliably isolate package tracking numbers regardless of margin drift.


* **Anchor-Based Regex Parsing:** Identifies line boundaries using document anchors (e.g., `(NC)` tokens) to strip line numbers and unwanted artifacts.


* **Modulo-10 Checksum Validation:** Validates standard 22-digit and 30-digit tracking numbers before database ingestion.


* **Noise Blacklisting:** Automatically rejects internal warehouse labels (e.g., Amazon FNSKU) and corrupted 2D MaxiCode fragments.



### 4. Reactive Local Persistence

* **Hive NoSQL Storage:** Stores package metadata, import logs, and manifest slips locally on disk.


* **Real-Time UI Synchronization:** Screens observe storage changes through reactive listeners, updating dashboard metrics, recent activity feeds, and history tables instantly upon scan or import.



### 5. Compliance PDF Slip Generation

* **Template Superimposition:** Generates compliance export sheets by superimposing validated tracking numbers, dates, checkmarks, and bill numbers onto high-resolution manifest templates.


* **Pagination & Alignment:** Dynamically formats lists into dual-column grids supporting up to 50 packages per sheet using exact PDF typographical points (72 points = 1 inch).


* **Multi-File Sharing:** Exports generated documents via system share sheets or direct file system access for distribution and printing.

---

## How It Works: Step-by-Step

### Workflow 1: Manifest Import

1. Navigate to the **Import** section and select an AMPS manifest PDF.


2. The import engine renders pages into high-contrast images and executes local OCR.


3. Extracted tracking numbers and header metadata (e.g., Delivery Date, Bill ID) are parsed and added to local storage with a status of **Pending**.



### Workflow 2: Package Intake & Reconciliation

1. Scan packages continuously using a connected USB/Bluetooth hardware scanner.


2. If the scanned tracking number exists in the database as **Pending**, its status changes to **Scanned** with an updated timestamp.


3. If an unmanifested tracking number is scanned, a new **Slipless** package entry is automatically created and marked as scanned.



### Workflow 3: Report Exporting

1. Open the **Export** menu to review processed packages and pending slips.
2. The export engine lays out the tracking numbers, applies visual checkmarks next to verified items, and compiles the document into a printable PDF slip.


3. Files are bundled for sharing, printing, or archival.

---

## Configuration & Settings

* **Assignment Defaults:** Configure the default branch assignment applied to newly scanned or imported packages.


* **Default Bill ID:** Define standard identifier prefixes for packages scanned without an existing manifest slip.


* **Appearance:** Toggle dynamically between light and dark modes.


* **Maintenance & Debugging:** Clear cached manifests and reset database boxes directly from the interface.