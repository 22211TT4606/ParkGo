# ParkGo

Ứng dụng iOS demo tìm kiếm và quản lý bãi đỗ xe, xây dựng bằng **SwiftUI**, **Firebase**, **MapKit** và **CoreLocation**.

## Tính năng

### User

- Xem bãi xe gần vị trí hiện tại trên bản đồ
- Tìm kiếm, lọc bãi xe theo tên / khoảng cách / giá / trạng thái
- Lưu bãi xe yêu thích
- Ghi nhớ vị trí đỗ xe
- Xem lịch sử đỗ xe và tìm kiếm
- Check-in / check-out tại bãi xe
- Đánh giá bãi xe

### Admin

- Dashboard tổng quan
- Quản lý bãi xe (thêm / sửa / xoá)
- Quản lý users
- Quản lý reviews
- Cài đặt hệ thống

## Tech Stack

| Thành phần | Công nghệ |
|---|---|
| Ngôn ngữ | Swift 5.7 |
| UI Framework | SwiftUI |
| Bản đồ | MapKit + CoreLocation |
| Backend | Firebase (Auth + Cloud Firestore) |
| Push Notification | Firebase Messaging (hook sẵn) |
| Kiến trúc | MVVM |
| Quản lý dependencies | Swift Package Manager |
| Tạo Xcode project | XcodeGen |
| Deployment target | iOS 16.0+ |

## Cấu trúc thư mục

```text
ParkGo/
├── App/                    # Entry point, dependencies, theme
│   ├── ParkGoApp.swift
│   ├── AppDependencies.swift
│   └── AppTheme.swift
├── Models/                 # Data models (Codable + Firestore)
├── Repositories/           # Firestore CRUD cho từng collection
├── SeedData/               # Demo data + seed service
├── Services/
│   ├── Firebase/           # Auth, bootstrapper, async helpers
│   ├── Location/           # CoreLocation service
│   └── Map/                # MapKit service
├── Utilities/              # Helpers, extensions
├── ViewModels/             # MVVM view models
└── Views/
    ├── Auth/               # Màn hình đăng nhập / đăng ký
    ├── Admin/              # Dashboard, quản lý lots/users/reviews
    ├── User/               # Home, Map, Search, Favorites, Profile
    └── Common/             # RootView, shared components

Firebase/
├── firestore.rules         # Security rules cho Firestore
└── firestore.indexes.json  # Indexes config

project.yml                 # Cấu hình XcodeGen
firebase.json               # Cấu hình Firebase CLI
GoogleService-Info.plist.sample
```

## Yêu cầu môi trường

- **Xcode 14.2+**
- **iOS Simulator 16+**
- **Homebrew** (để cài XcodeGen)
- **XcodeGen** — cài bằng:

```bash
brew install xcodegen
```

- **Firebase CLI** (tuỳ chọn, chỉ cần khi deploy rules):

```bash
npm install -g firebase-tools
```

- Tài khoản Firebase (Spark Plan — miễn phí)

## Bắt đầu

### Quick Start

Dành cho ai muốn chạy nhanh nhất có thể:

1. Tạo Firebase project → bật **Authentication (Email/Password)** → tạo **Cloud Firestore**
2. Tải `GoogleService-Info.plist` → copy vào root repo
3. Chạy:

```bash
xcodegen generate
open ParkGo.xcodeproj
```

4. Chọn simulator → Run → bấm **Seed Demo Data** trong app
5. Đăng nhập bằng tài khoản demo (xem bên dưới)

### Hướng dẫn chi tiết

#### 1. Clone repo

```bash
git clone <repo-url>
cd ParkGo
```

#### 2. Tạo Firebase project

1. Vào [Firebase Console](https://console.firebase.google.com) → tạo project mới
2. Bật **Authentication** → chọn **Email/Password**
3. Tạo **Cloud Firestore** (chọn region phù hợp)

> **Không cần bật**: Phone Auth, SMS, Google Maps Platform, Storage, hoặc bất kỳ dịch vụ trả phí nào.

#### 3. Tạo iOS app trong Firebase

1. Trong Firebase Console → **Add app** → chọn **iOS**
2. Nhập Bundle ID:

```text
com.demo.ParkGo
```

> Nếu muốn đổi Bundle ID, cập nhật trong `project.yml`.

3. Tải file `GoogleService-Info.plist`
4. Copy vào root repo (cùng cấp với `project.yml`)

> File `GoogleService-Info.plist.sample` chỉ là mẫu tham khảo. App đọc file `GoogleService-Info.plist` thật.

#### 4. Deploy Firestore rules (tuỳ chọn)

Nếu đã cài Firebase CLI và muốn deploy rules:

```bash
firebase login
firebase init
```

Khi `firebase init` hỏi:

| Câu hỏi | Chọn |
|---|---|
| Which features? | **Chỉ chọn Firestore** (không chọn Storage) |
| Use existing project? | **Yes** → chọn project vừa tạo |
| Firestore rules file? | `Firebase/firestore.rules` |
| Firestore indexes file? | `Firebase/firestore.indexes.json` |

Sau đó deploy:

```bash
firebase deploy --only firestore:rules
```

> **Lưu ý**: Nếu lỡ chọn **Storage** trong `firebase init`, sẽ gặp lỗi yêu cầu bật bucket. Chạy lại `firebase init` và chỉ chọn **Firestore**.

#### 5. Generate Xcode project

```bash
xcodegen generate
```

Kết quả: file `ParkGo.xcodeproj` được tạo.

#### 6. Mở project

```bash
open ParkGo.xcodeproj
```

#### 7. Resolve Swift Packages

Xcode sẽ tự fetch Firebase packages qua SPM. Nếu chưa tự resolve:

**File → Packages → Resolve Package Versions**

#### 8. Build & Run

1. Chọn simulator tương thích (ví dụ **iPhone 14** chạy **iOS 16** hoặc thiết bị thật chạy **iOS 16.0+**)
2. Nhấn **Run** (⌘R)

## Dữ liệu demo

### Seed data

Khi app mở lần đầu, bấm **Seed Demo Data** để tạo dữ liệu mẫu. Service sẽ tạo:

| Collection | Nội dung |
|---|---|
| `users` | Tài khoản admin + users mẫu |
| `vehicles` | Xe của users |
| `parking_lots` | Bãi xe với tên, địa chỉ, toạ độ, giá, trạng thái |
| `parking_history` | Lịch sử đỗ xe |
| `reviews` | Đánh giá bãi xe |
| `favorites` | Bãi xe yêu thích |
| `checkins` | Check-in tại bãi xe |
| `search_history` | Lịch sử tìm kiếm |

### Tài khoản demo

**Admin**

| Email | Password |
|---|---|
| `admin@parkgo.demo` | `Admin@123` |

**User**

| Email | Password |
|---|---|
| `minh@parkgo.demo` | `User@123` |
| `linh@parkgo.demo` | `User@123` |
| `bao@parkgo.demo` | `User@123` |

### Phân luồng theo role

Sau khi đăng nhập, app đọc `role` từ collection `users` trong Firestore:

- `role == "admin"` → giao diện **Admin** (Dashboard, quản lý)
- `role == "user"` → giao diện **User** (Home, Map, Search, Favorites, Profile)

## Vì sao không dùng Firebase Storage

Để giữ project hoàn toàn miễn phí (Spark Plan):

- Không upload ảnh lên Firebase Storage
- Không cần tạo Storage bucket
- Không cần deploy `storage.rules`
- Ảnh bãi xe dùng key dạng `demo://...` → app render preset nội bộ
- Admin chọn ảnh preset thay vì upload file

## Các lệnh thường dùng

```bash
# Generate lại Xcode project
xcodegen generate

# Mở project
open ParkGo.xcodeproj

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Build bằng terminal (không cần mở Xcode)
xcodebuild -quiet \
  -project ParkGo.xcodeproj \
  -scheme ParkGo \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData \
  build
```

# Start app
open ParkGo.xcodeproj

## Giả lập vị trí trong Simulator

Simulator không có GPS thật nên mặc định hiển thị San Francisco. Để dùng vị trí thật khi test:

### Bước 1 — Tạo file GPX

Trong Xcode, chuột phải vào folder `ParkGo` → **New File** → tìm **GPX File** → đặt tên `MyLocation`.

Sửa nội dung file với tọa độ thật của bạn (lấy từ Google Maps):

```xml
<?xml version="1.0"?>
<gpx version="1.1" creator="Xcode">
    <wpt lat="10.7769" lon="106.7009">
        <name>My Location</name>
    </wpt>
</gpx>
```

### Bước 2 — Cấu hình Scheme

1. Bấm vào tên scheme **"ParkGo"** trên toolbar → **Edit Scheme...**
2. Chọn **Run** ở cột trái → tab **Options**
3. Tìm mục **Core Location** → tick **Allow Location Simulation** → chọn **Default Location: MyLocation**
4. Bấm **Close**

### Bước 3 — Kích hoạt khi app đang chạy

Build & Run app → vào menu **Debug > Simulate Location > MyLocation**

> Muốn dùng GPS thật 100%: cắm iPhone thật vào Mac và chọn thiết bị thật thay vì Simulator.

## Troubleshooting

| Vấn đề | Kiểm tra |
|---|---|
| App crash khi mở | Đã có file `GoogleService-Info.plist` thật chưa? |
| Firebase Auth lỗi | Đã bật **Email/Password** trong Firebase Console chưa? |
| Firestore không ghi được | Đã tạo **Cloud Firestore** trong Console chưa? Rules đã deploy chưa? |
| Xcode lỗi package | Vào **File → Packages → Resolve Package Versions** |
| Bundle ID không khớp | So sánh Firebase Console với `bundleIdPrefix` trong `project.yml` |
| `firebase use` lỗi | Chạy `firebase init` trước ở thư mục project |
| Chọn nhầm Storage | Chạy lại `firebase init`, chỉ chọn **Firestore** |

## File quan trọng

| File | Vai trò |
|---|---|
| `ParkGo/App/ParkGoApp.swift` | Entry point |
| `ParkGo/App/AppDependencies.swift` | Dependency container |
| `ParkGo/Views/Common/RootView.swift` | Routing theo auth state + role |
| `ParkGo/SeedData/SeedDataService.swift` | Tạo dữ liệu demo |
| `ParkGo/Services/Firebase/FirebaseBootstrapper.swift` | Khởi tạo Firebase (skip nếu thiếu plist) |
| `Firebase/firestore.rules` | Security rules cho Firestore |
| `project.yml` | Cấu hình XcodeGen (source of truth) |
