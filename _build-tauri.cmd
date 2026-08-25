@echo off
rem Internal helper launcher: cargo build + auto-sign SAC-blocked intermediates
cd /d C:\Users\Neweye\desktop\workspace\asur-find
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Neweye\desktop\workspace\asur-find\_build-tauri-inner.ps1" >> .tooling\cargo-build.log 2>&1