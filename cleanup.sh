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

# Hapus gambar
echo "Hapus gambar dulu..."
rm -f cam*.png

# Remove temporary HTML files
echo "Removing temporary HTML files..."
rm -f index.php
rm -f index2.html
rm -f index3.html

# Ini buat hapus lokasi yang di simpan
echo "hapus lokasi yang di simpan dulu..."
if [ -d "saved_locations" ]; then
  rm -f saved_locations/*
fi

# Hapus log sampah
echo "Oke ini terakhir buat hapus log sampahnya..."
rm -f LocationLog.log
rm -f LocationError.log
rm -f Log.log

echo "Yeyyyyy udah bersih!"
