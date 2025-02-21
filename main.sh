#!/bin/ash

# Colores para resaltar
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m' # Sin color

# Limpiar pantalla
clear

# Mostrar banner
show_banner() {
    echo -e "${GREEN}"
    echo "███╗   ██╗ █████╗ ██╗   ██╗ █████╗ ██████╗ "
    echo "████╗  ██║██╔══██╗╚██╗ ██╔╝██╔══██╗██╔══██╗"
    echo "██╔██╗ ██║███████║ ╚████╔╝ ███████║██████╔╝"
    echo "██║╚██╗██║██╔══██║  ╚██╔╝  ██╔══██║██╔══██╗"
    echo "██║ ╚████║██║  ██║   ██║   ██║  ██║██║  ██║"
    echo "╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝"
    echo "████████╗ ██████╗  ██████╗ ██╗     ███████╗"
    echo "╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝"
    echo "   ██║   ██║   ██║██║   ██║██║     ███████╗"
    echo "   ██║   ██║   ██║██║   ██║██║     ╚════██║"
    echo "   ██║   ╚██████╔╝╚██████╔╝███████╗███████║"
    echo "   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝"
    echo -e "${NC}"
}
# ====================================================================================================
#                                           Información de red
# ====================================================================================================

network_info() {
    clear
    show_banner

    # Inicializar variables
    red_movil="No disponible"
    wifi="No disponible"
    ethernet="No disponible"
    conexion="Desconocida"

    # Comprobar conectividad real (UP + IP asignada)
    if ip a show ppp0 | grep -q "inet "; then
        red_movil="Disponible"
    fi

    if ip a show wlan0 | grep -q "inet "; then
        wifi="Disponible"
    fi

    if ip a show eth0 | grep -q "inet "; then
        ethernet="Disponible"
    fi

    # Determinar conexión activa por la ruta por defecto
    default_route=$(ip r | grep default)

    if echo "$default_route" | grep -q "ppp0"; then
        conexion="Red móvil"
    elif echo "$default_route" | grep -q "wlan"; then
        conexion="WiFi"
    elif echo "$default_route" | grep -q "eth"; then
        conexion="Ethernet"
    fi

    # Mostrar la información de manera clara
    echo -e "\n${CYAN}### Información de Red ###${NC}\n"
    echo "┌───────────────────────────┐"
    printf "│ %-25s │\n" "Red móvil: $red_movil"
    printf "│ %-25s │\n" "WiFi: $wifi"
    printf "│ %-25s │\n" "Ethernet: $ethernet"
    echo "└───────────────────────────┘"

    echo -e "\n${GREEN}Está conectado por: ${YELLOW}$conexion${NC}\n"
    
    echo -e "\n${YELLOW}Presione Enter para continuar...${NC}"
    read -r
    clear
}
# ====================================================================================================
#                                           MRC
# ====================================================================================================

# Función para detectar USB y validar compatibilidad con la versión del sistema
detect_usb() {
    clear
    show_banner
    echo -e "\n${CYAN}### Detección de USB y Validación de Versión ###${NC}\n"

    # Obtener la versión del sistema
    system_version=$(uname -a)

    # Determinar la versión del firmware (93 o 138)
    firmware_version=""
    if echo "$system_version" | grep -q "93"; then
        firmware_version="93"
    elif echo "$system_version" | grep -q "138"; then
        firmware_version="138"
    else
        echo -e "${RED} Error: No se pudo determinar la versión del firmware${NC}"
        echo -e "\n${YELLOW}Presione Enter para continuar...${NC}"
        read -r
        return
    fi

    echo -e "Versión del sistema detectada: ${YELLOW}$firmware_version${NC}\n"

    # Ejecutar lsusb y filtrar dispositivos relevantes
    usb_devices=$(lsusb 2>/dev/null)
    detected_usb=$(echo "$usb_devices" | grep -E "7523|2303")

    usb_detected=false
    usb_valid=false

    # Comprobar si hay USB detectado
    if [[ -n "$detected_usb" ]]; then
        usb_detected=true
    fi

    # Validar compatibilidad del USB con la versión del sistema
    if echo "$firmware_version" | grep -q "93" && echo "$detected_usb" | grep -q "2303"; then
        usb_valid=true
    elif echo "$firmware_version" | grep -q "138" && echo "$detected_usb" | grep -q "7523"; then
        usb_valid=true
    fi

    # Mostrar resultados
    if [[ "$usb_detected" == true ]]; then
        echo -e "Estado del USB: ${GREEN}USB detectado${NC}"
        echo -e "\n${GREEN}Detalles del USB:${NC}"
        echo "$detected_usb"

        # Mostrar error si el USB no es compatible con la versión del sistema
        if [[ "$usb_valid" == false ]]; then
            echo -e "\n${RED} Error: USB incompatible con la versión del sistema${NC}"
        fi
    else
        echo -e "Estado del USB: ${RED}USB no detectado${NC}"
    fi

    echo -e "\n${YELLOW}Presione Enter para continuar...${NC}"
    read -r
    clear
}

# Función para reiniciar V-Modem
restart_vmodem() {
    clear
    show_banner
    echo -e "\n${CYAN}### Reiniciando V-Modem ###${NC}\n"

    # Buscar el proceso vmodem y obtener su PID
    vmodem_pid=$(ps | grep "/bin/vmodem -C /etc/n4m/vmodem.conf" | grep -v grep | awk '{print $1}')

    if [[ -n "$vmodem_pid" ]]; then
        # Si el proceso está en ejecución, detenerlo y luego reiniciarlo
        echo -e "${YELLOW}Deteniendo V-Modem (PID: $vmodem_pid)...${NC}"
        kill "$vmodem_pid"
        sleep 2  # Esperar a que se cierre el proceso
        echo -e "${GREEN}Iniciando V-Modem...${NC}"
        /bin/vmodem -C /etc/n4m/vmodem.conf &
        echo -e "${GREEN}V-Modem Reiniciado${NC}"
    else
        # Si el proceso no está en ejecución, no hacer nada
        echo -e "${RED}No se encontró un proceso V-Modem en ejecución. No se realizará ninguna acción.${NC}"
    fi

    echo -e "\n${YELLOW}Presione Enter para continuar...${NC}"
    read -r
    clear
}

# Menú de MCR
mcr_menu() {
    while true; do
        clear
        show_banner
        echo -e "\n${BLUE}--- Menú de MCR ---${NC}\n"
        echo "1) Detectar USB"
        echo "2) Reiniciar V-Modem"
        echo "3) Volver al menú principal"
        read -p "Seleccione una opción: " choice

        case $choice in
            1) detect_usb ;;
            2) restart_vmodem ;;
            3) clear; return ;;
            *) echo -e "${RED}Opción no válida.${NC}" ;;
        esac
    done
}
# ====================================================================================================
#                                           Controladora
# ====================================================================================================

# Función para mostrar reglas de iptables
iptables_info() {
    clear
    show_banner
    printf "\n${CYAN}### Reglas de iptables (PREROUTING) ###${NC}\n\n"

    # Ejecutar iptables y formatear la salida
    iptables -t nat -L PREROUTING -n -v | awk '
        BEGIN {
            printf "%-8s | %-10s | %-22s | %-6s | %-18s | %-18s | %-6s | %-18s\n", "Pkts", "Bytes", "Target", "Proto", "Source", "Destination", "DPort", "To Address";
            print "----------------------------------------------------------------------------------------------------------------------------------";
        }
        NR>2 {
            # Inicializamos variables con valores por defecto
            pkts = $1;
            bytes = $2;
            target = ($3 != "") ? $3 : "-";
            proto = "-";
            source = ($8 != "") ? $8 : "-";
            destination = ($9 != "") ? $9 : "-";
            dport = "-";
            to_address = "-";

            for (i=1; i<=NF; i++) {
                if ($i == "tcp" || $i == "udp") proto = $i;
                if ($i ~ /dpt:/) dport = substr($i, 5);
                if ($i ~ /^to:/) to_address = substr($i, 4);  # Captura la IP y el puerto después de "to:"
            }

            # Filtrar reglas vacías o que solo sean comentarios
            if (target != "-" || proto != "-" || dport != "-" || to_address != "-") {
                printf "%-8s | %-10s | %-22s | %-6s | %-18s | %-18s | %-6s | %-18s\n", pkts, bytes, target, proto, source, destination, dport, to_address;
            }
        }'

    printf "\n${YELLOW}Presione Enter para continuar...${NC}\n"
    read -r
    clear
}

# Función para obtener la IP de la interfaz br-lan
br_lan_info() {
    clear
    show_banner
    echo -e "\n${CYAN}### Obteniendo IP de br-lan ###${NC}\n"

    # Ejecutamos el comando 'ip a' y usamos awk para obtener solo la IP de br-lan
    ip_brlan=$(ip a show br-lan 2>/dev/null | awk '/inet / {print $2; exit}')

    # Si encontramos una IP, la mostramos
    if [ -n "$ip_brlan" ]; then
        echo -e "${GREEN}La IP de br-lan es: ${ip_brlan}${NC}"
    else
        echo -e "${RED}No se encontró la interfaz br-lan o no tiene una dirección IP configurada.${NC}"
    fi

    echo -e "\n${YELLOW}Presione Enter para continuar...${NC}"
    read -r
    clear
}

bucle_for() {
    clear
    show_banner
    echo -e "\n${CYAN}### Barrido de IPs en la red ###${NC}\n"

    # Pedir al usuario que ingrese el tercer número de la IP
    echo -e "${YELLOW}Ingrese el rango de la IP (1-255):${NC}"
    read -r octeto

    # Validar que sea un número entre 1 y 255
    if ! echo "$octeto" | grep -qE '^[1-9][0-9]{0,2}$|^255$'; then
        echo -e "${RED}Valor inválido. Debe ser un número entre 1 y 255.${NC}"
        sleep 2
        return
    fi

    clear
    show_banner
    echo -e "\n${CYAN}### Barrido de IPs en la red ###${NC}\n"
    echo -e "${GREEN}IPs con dispositivos conectados:${NC}\n"

    for i in $(seq 254); do ping -c1 -W1 192.168.$octeto.$i & done | grep "from" | awk '{print $4}' | tr -d ':'
    echo -e "\n${YELLOW}Presione Enter para continuar...${NC}"
    read -r
    clear
}

bucle_for_nmap() {
    clear
    show_banner
    echo -e "\n${CYAN}### Barrido de IPs en la red ###${NC}\n"

    # Pedir al usuario que ingrese el tercer número de la IP
    echo -e "${YELLOW}Ingrese el rango de la IP (1-255):${NC}"
    read -r octeto

    # Validar que sea un número entre 1 y 255
    if ! echo "$octeto" | grep -qE '^[1-9][0-9]{0,2}$|^255$'; then
        echo -e "${RED}Valor inválido. Debe ser un número entre 1 y 255.${NC}"
        sleep 2
        return
    fi

    clear
    show_banner
    echo -e "\n${CYAN}### Barrido de IPs en la red ###${NC}\n"
    echo -e "${GREEN}IPs con dispositivos conectados:${NC}\n"

    # Obtener IPs activas y almacenarlas en una variable
    active_ips=$(for i in $(seq 254); do ping -c1 -W1 192.168.$octeto.$i & done | grep "from" | awk '{print $4}' | tr -d ':')

    # Mostrar las IPs activas
    echo "$active_ips"

    # Escanear con nmap cada IP detectada
    if [ -n "$active_ips" ]; then
        echo -e "\n${CYAN}### Escaneo de puertos con Nmap ###${NC}\n"
        for ip in $active_ips; do
            echo -e "${YELLOW}Escaneando $ip...${NC}"
            nmap "$ip"
            echo ""
        done
    else
        echo -e "${RED}No se detectaron dispositivos en la red.${NC}"
    fi

    echo -e "\n${YELLOW}Presione Enter para continuar...${NC}"
    read -r
    clear
}

# Menú de Controladora
controladora_menu() {
    while true; do
        clear
        show_banner
        echo -e "\n${BLUE}--- Menú de Controladora ---${NC}\n"
        echo "1) IPTABLES"
        echo "2) BR-LAN"
        echo "3) FOR (Ver dispositivos conectados)"
        echo "4) FOR Avanzado (+nmap)"
        echo "5) Volver al menú principal"
        read -p "Seleccione una opción: " choice

        case $choice in
            1) iptables_info ;;
            2) br_lan_info ;;
            3) bucle_for ;;
            4) bucle_for_nmap ;;
            5) clear; return ;;
            *) echo -e "${RED}Opción no válida.${NC}" ;;
        esac
    done
}
# ====================================================================================================
#                                       Menu principal
# ====================================================================================================
main_menu() {
    while true; do
        clear
        show_banner
        echo -e "\n${BLUE}--- Menú Principal ---${NC}\n"
        echo "1) Información de red"
        echo "2) MCR"
        echo "3) Controladora"
        echo "4) Salir"
        read -p "Seleccione una opción: " choice

        case $choice in
            1) network_info ;;
            2) mcr_menu ;;
            3) controladora_menu ;;
            4) echo -e "${RED}Saliendo...${NC}"; exit 0 ;;
            *) echo -e "${RED}Opción no válida.${NC}" ;;
        esac
    done
}

# Ejecutar el menú principal
main_menu
