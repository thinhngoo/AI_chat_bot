# Hướng dẫn Thiết lập CI/CD cho AI Chat Bot

## 1. Tổng quan

Hệ thống CI/CD của AI Chat Bot sử dụng GitHub Actions để tự động hóa quá trình kiểm tra, xây dựng và triển khai. Hệ thống bao gồm:

- Kiểm tra mã nguồn (lint và test)
- Build ứng dụng Web
- Build ứng dụng Windows
- Build và triển khai Firebase Functions
- Triển khai lên Firebase Hosting

### 1.1. Các Workflow

Các workflow chính được cấu hình trong thư mục `.github/workflows/`:

| Workflow | Tệp | Mô tả | Kích hoạt |
|----------|-----|-------|-----------|
| Flutter Build & Test | `flutter_build_test.yml` | Kiểm tra và build ứng dụng Flutter | Push vào `main`, Pull Request |
| Firebase Functions | `firebase_functions.yml` | Build và triển khai Firebase Functions | Thay đổi trong thư mục `functions/` |
| Windows Build | `windows_build.yml` | Build ứng dụng Windows | Push vào `main`, Pull Request |
| Firebase Deployment | `firebase_deployment.yml` | Triển khai lên Firebase Hosting | Push vào `main`, Pull Request |
| PR Test | `pr_test.yml` | Kiểm tra mã nguồn khi có Pull Request | Pull Request vào `main`, `develop` |
| Create Release | `release.yml` | Tạo bản phát hành khi có tag mới | Push tag với định dạng `v*` (ví dụ: v1.0.0) |

### 1.2. Quy trình CI/CD

1. **Phát triển**: 
   - Các nhà phát triển làm việc trên nhánh tính năng
   - Chạy `test_ci_local.bat` để kiểm tra cục bộ

2. **Pull Request**:
   - Mở PR vào nhánh `develop` hoặc `main`
   - Workflow `pr_test.yml` tự động chạy để kiểm tra code

3. **Merge và Triển khai**:
   - Khi PR được merge vào `main`, các workflow build và triển khai tự động chạy
   - Web được triển khai lên Firebase Hosting
   - Functions được triển khai lên Firebase Functions

4. **Phát hành**:
   - Tạo tag với định dạng `v*` (ví dụ: v1.0.0)
   - Workflow `release.yml` tự động tạo GitHub Release
   - APK Android được đính kèm vào bản phát hành

## 2. Cấu hình cần thiết

### 2.1 Thiết lập Secret trên GitHub

1. Truy cập trang GitHub của dự án
2. Vào Settings > Secrets and variables > Actions
3. Thêm secret mới:
   - Name: `FIREBASE_SERVICE_ACCOUNT_VINH_AFF13`
   - Value: [Nội dung file JSON của service account Firebase]

### 2.2 Lấy Service Account Firebase

1. Đăng nhập vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn dự án "vinh-aff13"
3. Vào Project Settings > Service accounts
4. Chọn "Generate new private key"
5. Lưu file JSON được tạo
6. Sao chép toàn bộ nội dung của file này vào secret `FIREBASE_SERVICE_ACCOUNT_VINH_AFF13`

## 3. Các workflow GitHub Actions

### 3.1 Flutter Build & Test

- File: `.github/workflows/flutter_build_test.yml`
- Kích hoạt khi: Push vào nhánh main hoặc tạo pull request
- Chức năng:
  - Kiểm tra định dạng mã
  - Phân tích mã nguồn
  - Chạy các bài kiểm thử
  - Build phiên bản web

### 3.2 Build ứng dụng Windows

- File: `.github/workflows/windows_build.yml`
- Kích hoạt khi: Push vào nhánh main hoặc tạo pull request
- Chức năng:
  - Cài đặt Flutter và công cụ build Windows
  - Build ứng dụng Windows
  - Lưu trữ bản build dưới dạng artifact

### 3.3 Build và kiểm tra Firebase Functions

- File: `.github/workflows/firebase_functions.yml`
- Kích hoạt khi: Push hoặc tạo PR có thay đổi trong thư mục "functions"
- Chức năng:
  - Cài đặt dependencies
  - Lint mã TypeScript
  - Build Firebase Functions

### 3.4 Triển khai lên Firebase

- File: `.github/workflows/firebase_deployment.yml`
- Kích hoạt khi: Push vào nhánh main hoặc tạo pull request
- Chức năng:
  - Build ứng dụng web
  - Triển khai phiên bản preview cho pull requests
  - Triển khai phiên bản production khi merge vào main

## 4. Kiểm tra và xử lý sự cố

### 4.1 Xem trạng thái của workflows

1. Truy cập tab "Actions" trên GitHub repository
2. Xem lịch sử và trạng thái của các workflow

### 4.2 Xử lý lỗi thường gặp

- **Lỗi khi build web**: Kiểm tra xem Flutter version có khớp không, cần >= 3.29.1
- **Lỗi khi triển khai Firebase**: Kiểm tra lại secret service account
- **Lỗi build Functions**: Kiểm tra file package.json và dependencies

## 5. Triển khai thủ công (nếu cần)

Nếu cần triển khai thủ công không qua CI/CD:

### 5.1 Triển khai Web

```bash
flutter build web
firebase deploy --only hosting
```

### 5.2 Triển khai Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

## 6. Giám sát và tối ưu

- Kiểm tra Firebase Hosting trong Firebase Console
- Giám sát lỗi với Firebase Crashlytics
- Theo dõi hiệu năng qua Firebase Performance Monitoring
- Kiểm tra logs của Functions trong Firebase Console
