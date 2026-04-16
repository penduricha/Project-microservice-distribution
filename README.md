# Dự án Phân tích Dữ liệu Lớn với Spark & Hadoop (HDFS)

Hệ thống hỗ trợ khởi tạo môi trường lập trình, lưu trữ dữ liệu trên HDFS và huấn luyện mô hình học máy Random Forest sử dụng PySpark.

## 🛠 Yêu cầu hệ thống (Prerequisites)
Để đảm bảo dự án vận hành ổn định, hệ thống cần đáp ứng các tiêu chuẩn sau:
* **Hệ điều hành:** Ubuntu 24.04 LTS hoặc mới hơn.
* **Công cụ:** `docker.io` & `docker-compose`.
* **Ngôn ngữ:** Python 3.12.3.
* **Môi trường Java:** JDK 21.

---

## 🚀 Hướng dẫn triển khai (Setup Guide)

Thực hiện theo các bước dưới đây để thiết lập môi trường và chạy dự án:

### Bước 1: Khởi tạo môi trường Docker
Mở terminal tại thư mục gốc của dự án và chạy lệnh sau để tự động cài đặt `.venv` và các container cần thiết:
```bash
docker compose up
```

### Bước 2: Khởi tạo cấu trúc HDFS
Mở và chạy file Notebook sau để thiết lập hệ thống lưu trữ Hadoop:
* File: `hdfs/create-hdfs.ipynb`

### Bước 3: Phát sinh dữ liệu mẫu
Để tạo tập dữ liệu lớn phục vụ cho việc huấn luyện, thực hiện chạy file:
* File: `generate-data/gen-data.ipynb`

### Bước 4: Huấn luyện mô hình Machine Learning
Nạp dữ liệu từ HDFS và thực hiện huấn luyện mô hình **Random Forest** bằng Spark:
* File: `spark/jobs/train_random_forest.ipynb`

---
*Lưu ý: Đảm bảo VS Code của bạn đã chọn đúng Kernel từ thư mục `.venv` được tạo ra sau Bước 1.*
