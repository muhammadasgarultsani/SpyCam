#!/bin/bash
# skrip menghapus sampah spycam
echo "Yaa kita mulai hapus dulu sabar yaahh..."

# hapus filelog
echo "Ini lagi hapus log dulu..."
rm -f *.log
rm -f .cloudflared.log

# ini hapus lokasi
echo "Ini hapus lokasi..."
rm -f location_*.txt
rm -f current_location.bak

# Hapus gambar dari folder capture
echo "Hapus gambar dari folder capture..."
if [ -d "capture" ]; then
  rm -f capture/capture_*.png
  rm -f capture/*.log
fi

# Hapus gambar lama dari root (jika ada)
echo "Hapus gambar lama dari root..."
rm -f cam*.png

# Ini buat hapus lokasi yang di simpan
echo "hapus lokasi yang di simpan dulu..."
if [ -d "saved_locations" ]; then
  rm -f saved_locations/*
fi

# Hapus log sampah
echo "Oke ini terakhir buat hapus log sampahnya..."
rm -f LocationLog.log
rm -f LocationError.log
rm -f saved.ip.txt
rm -f saved.locations.txt

echo "Yeyyyyy udah bersih!"
