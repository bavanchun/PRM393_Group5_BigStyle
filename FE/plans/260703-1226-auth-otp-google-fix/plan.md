---
title: Fix Auth OTP + Google Sign-in + Config Reproducibility
description: ''
status: completed
priority: P2
branch: main
tags: []
blockedBy: []
blocks: []
created: '2026-07-03T05:33:52.955Z'
createdBy: 'ck:plan'
source: skill
---

# Fix Auth OTP + Google Sign-in + Config Reproducibility

## Overview

Sửa auth để chạy được trên MỌI máy (không chỉ máy người làm feature). Gốc rễ: config `.env` không tái lập được + OTP dùng magic-link chết + Google thiếu config.

Chiến lược đã chốt (brainstorm): OTP → **mã 6 số** (bỏ deep-link); config → **giữ `.env` bí mật + setup script**; dashboard (Supabase template + Google Cloud OAuth) → user tự làm theo checklist.

Nguồn: `plans/reports/auth-otp-google-signin-reproducibility-fix-260703-1226-auth-otp-google-fix-report.md`

## Phases

| Phase | Name | Status |
|-------|------|--------|
| 1 | [Config Reproducibility](./phase-01-config-reproducibility.md) | Completed |
| 2 | [OTP Cleanup + Dashboard Checklist](./phase-02-otp-cleanup-dashboard-checklist.md) | Completed |

## Dependencies

<!-- Cross-plan dependencies -->
