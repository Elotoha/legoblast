@echo off
"%~dp0asset_preview.exe" "%~dp0demo-assets"
if errorlevel 1 pause
