FROM redis:7.0.15

# Chép file cấu hình từ thư mục gốc vào đúng vị trí trong container
COPY redis.conf /usr/local/etc/redis/redis.conf

# Trao quyền sở hữu cho user redis
RUN chown redis:redis /usr/local/etc/redis/redis.conf

# Lệnh khởi động ép nạp file cấu hình
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]