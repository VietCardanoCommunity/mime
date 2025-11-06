#!/bin/bash

INPUT="nounce.txt"
TEMP="/tmp/nounce_tmp.txt"

# Tạo file tạm rỗng
> "$TEMP"

while IFS=',' read -r timestamp nonce challengeid address; do
    
    # Loại bỏ khoảng trắng, xuống dòng
    nonce=$(echo "$nonce" | xargs)
    challengeid=$(echo "$challengeid" | xargs)
    address=$(echo "$address" | xargs)

    # Validate format
    if [[ "$address" != addr1* || "$challengeid" != \*\*D* || -z "$nonce" ]]; then
        echo "⚠️ Sai format, giữ lại dòng: $timestamp"
        echo "$timestamp,$nonce,$challengeid,$address" >> "$TEMP"
        continue
    fi

    URL="https://scavenger.prod.gd.midnighttge.io/solution/$address/$challengeid/$nonce"
    echo "🚀 Calling: $URL"

    # Gửi request và lấy HTTP code
    http_code=$(curl -s -o /tmp/resp.out -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{}' \
        "$URL")

    echo "📩 HTTP: $http_code"
    echo "📨 BODY: $(cat /tmp/resp.out)"

    # Nếu 201 → xoá dòng (không ghi vào temp)
    if [[ "$http_code" == "201" ]]; then
        echo "✅ Thành công → XÓA dòng khỏi file"
    else
        # Ghi lại dòng vào temp
        echo "$timestamp,$nonce,$challengeid,$address" >> "$TEMP"
        echo "❌ Không thành công → GIỮ dòng lại"
    fi

    # Random delay 5-10 giây
    delay=$((RANDOM % 6 + 5))
    echo "⏳ Chờ ${delay}s..."
    sleep $delay

done < "$INPUT"

# Ghi đè file gốc
mv "$TEMP" "$INPUT"

echo "🎯 DONE — File đã được cập nhật!"
