# Thiết lập phân hệ quản trị trên gói Spark

Phân hệ Admin chạy trực tiếp bằng Firebase Authentication, Custom Claims,
Cloud Firestore và Firestore Security Rules. Project không cần Cloud Functions
hoặc gói Blaze.

## Chức năng hỗ trợ

- Xem tổng số hồ sơ người dùng.
- Thống kê người dùng hoạt động trong 30 ngày gần nhất.
- Thống kê người dùng mới trong tháng và biểu đồ đăng ký 6 tháng.
- Tìm kiếm, xem thông tin cơ bản của người dùng.
- Tạo, sửa, phát hành và đặt hạn thông báo hệ thống.
- Cấu hình tên ứng dụng, hỗ trợ, hạn mức giao dịch, bảo trì và đăng ký.
- Thêm, sửa, sắp xếp và ẩn/hiện danh mục Thu/Chi mặc định.
- Xem nhật ký thay đổi cấu hình, thông báo và danh mục nền.

Ứng dụng không khóa/mở khóa tài khoản Firebase Authentication, không đọc giao
dịch riêng tư của người dùng và không tạo nhật ký khóa tài khoản.

## Cấp quyền Admin

Quyền truy cập dựa trên Firebase Custom Claim `admin: true`. Sau khi cấp claim,
người dùng cần đăng xuất rồi đăng nhập lại để nhận token mới.

Hồ sơ `users/{uid}` nên có:

```text
role: admin
```

Trường Firestore này dùng để hiển thị; Security Rules vẫn kiểm tra Custom Claim.

## Dữ liệu

- `users/{uid}`: hồ sơ cơ bản, ngày tạo và lần đăng nhập gần nhất.
- `default_categories/{id}`: danh mục Thu/Chi mặc định.
- `system_notifications/{id}`: thông báo hệ thống có thời hạn.
- `app_config/general`: cấu hình vận hành chung.
- `admin_audit_logs/{id}`: nhật ký thay đổi bất biến.

Admin chỉ đọc hồ sơ trong `users`. Ví và giao dịch chi tiết vẫn thuộc riêng từng
người dùng.

## Triển khai

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

## Kiểm tra

```powershell
flutter analyze
flutter test
```
