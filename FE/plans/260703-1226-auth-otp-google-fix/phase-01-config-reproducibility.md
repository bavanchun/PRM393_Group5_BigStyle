---
phase: 1
title: Config Reproducibility
status: completed
effort: ''
---

# Phase 1: Config Reproducibility

## Overview

Làm cho `.env` tái lập được: chuẩn hoá vị trí file, hoàn thiện `.env.example`, thêm setup script + hướng dẫn README. Mục tiêu: máy mới clone về chạy được sau vài lệnh, không phụ thuộc máy người làm feature.

## Requirements
- Functional: `flutter run` chạy được trên máy mới sau khi chạy setup script + điền `.env`.
- Non-functional: `.env` vẫn gitignore (giữ bí mật); không hardcode key vào code.

## Architecture

Chốt 1 vị trí duy nhất cho env = `FE/.env` (gốc project Flutter), khớp với `pubspec.yaml` (`assets: - .env`) và `lib/main.dart` (`dotenv.load(fileName: '.env')`). Bỏ file lạc `FE/assets/.env` để hết nhầm lẫn (chính nó gây lỗi path mismatch + comment sai trong `.env.example`).

`.env.example` là nguồn tài liệu key cho cả nhóm — phải đủ 5 key, đặc biệt `GOOGLE_WEB_CLIENT_ID` (hiện `.env` thật thiếu).

## Related Code Files
- Modify: `.env.example` — sửa comment "Copy this file to assets/.env" → "Copy this file to .env"; đảm bảo đủ key: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_MAPS_API_KEY`, `GOOGLE_WEB_CLIENT_ID`, `CLAUDE_API_KEY`.
- Create: `scripts/setup.sh` — copy `.env.example` → `.env` (nếu chưa có) + nhắc điền value + chạy `flutter pub get`.
- Modify: `README.md` — thêm mục "Setup / Run" ngắn.
- Delete: `assets/.env` — file lạc gây nhầm (sau khi xác nhận `.env` gốc đã đủ value).
- Verify: `pubspec.yaml` (`- .env`) và `lib/main.dart` (`dotenv.load('.env')`) — đã khớp, không sửa.

## Implementation Steps
1. Xác nhận `FE/.env` (gốc) đã có đủ value thật (đang chạy được). Bổ sung `GOOGLE_WEB_CLIENT_ID=` (lấy từ `.env.example`) vào `.env` thật.
2. Sửa `.env.example`: đổi dòng comment vị trí về `.env`; kiểm tra đủ 5 key với value mẫu/placeholder an toàn (giữ nguyên các key vốn public như SUPABASE_URL/ANON_KEY/GOOGLE_WEB_CLIENT_ID, để trống GOOGLE_MAPS_API_KEY/CLAUDE_API_KEY).
3. Tạo `scripts/setup.sh`: `#!/usr/bin/env bash`, `set -euo pipefail`; nếu `.env` chưa tồn tại thì `cp .env.example .env` + in nhắc điền value; chạy `flutter pub get`. `chmod +x`.
4. Xoá `assets/.env` (đảm bảo `.env` gốc đủ trước khi xoá).
5. Thêm mục Setup vào `README.md`: các bước `bash scripts/setup.sh` → điền `.env` → `flutter run`.
6. Kiểm tra `.gitignore` vẫn ignore `.env` (đúng, dòng 47), và `.env.example` được track.

## Success Criteria
- [ ] `.env.example` đủ 5 key + comment vị trí đúng (`.env`)
- [ ] `scripts/setup.sh` chạy được, tạo `.env` từ example nếu thiếu
- [ ] `assets/.env` đã xoá; `flutter run` vẫn chạy (env load từ `FE/.env`)
- [ ] README có mục setup rõ ràng
- [ ] `.env` vẫn gitignore, `.env.example` được commit

## Risk Assessment
- Xoá nhầm `.env` thật thay vì `assets/.env` → mất value. Mitigation: xác nhận `FE/.env` đủ value trước, chỉ xoá `assets/.env`.
- `flutter run` cache asset cũ → chạy `flutter clean` nếu asset không load lại.
