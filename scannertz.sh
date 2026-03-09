#!/bin/bash

command -v adb  >/dev/null 2>&1 || pkg install android-tools -y >/dev/null 2>&1


CLR_ESCURO='\e[1;30m'
CLR_BRANCO='\e[1;37m'
CLR_CINZA='\e[0;37m'
CLR_VERDE='\e[1;32m'
CLR_AMARELO='\e[1;33m'
CLR_RED='\e[1;31m'
RESET='\e[0m'

PACOTE=""
LOG_PROBLEMAS=""
PROBLEMAS_COUNT=0

pause(){ 
    echo -e ""
    echo -ne "  ${GRAY}Pressione Enter para continuar...${NC}"
    read -r
}

draw_header() {
    get_device_info 
    printf "\033[H\033[J"
    echo -e "${CLR_BRANCO}"
    cat << 'EOF'
████████╗███████╗    ███████╗ ██████╗ █████╗ ███╗   ██╗███╗   ██╗███████╗██████╗ 
╚══██╔══╝╚══███╔╝    ██╔════╝██╔════╝██╔══██╗████╗  ██║████╗  ██║██╔════╝██╔══██╗
   ██║     ███╔╝     ███████╗██║     ███████║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝
   ██║    ███╔╝      ╚════██║██║     ██╔══██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗
   ██║   ███████╗    ███████║╚██████╗██║  ██║██║ ╚████║██║ ╚████║███████╗██║  ██║
   ╚═╝   ╚══════╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
EOF
    echo -e "${CLR_ESCURO}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CLR_ESCURO}   ${CLR_BRANCO}TZ SCANNER ${RESET}${CLR_ESCURO}| ${CLR_CINZA}DEV:${RESET} ${CLR_BRANCO}Tzbypass ${RESET}${CLR_ESCURO}| ${CLR_CINZA}DISCORD:${RESET} ${CLR_BRANCO}https://discord.gg/dc7P7euZ6${RESET}"
    echo -e "${CLR_ESCURO}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
}



adb_is_connected() {
    adb devices 2>/dev/null | grep -v "List of devices" | grep -q "device$"
}

spinner() {
    local msg="$1"
    local spin='|/-\'
    for i in {1..20}; do
        printf "\r  [%c] %s" "${spin:i%4:1}" "$msg"
        sleep 0.05
    done
    printf "\r  [✓] %s\n" "$msg"
}


gerenciar_conexao() {
    while true; do
        draw_header
        # Verifica status atual para o painel
        local adb_status="${CLR_RED}OFFLINE${RESET}"
        adb_is_connected && adb_status="${CLR_VERDE}ONLINE${RESET}"

        echo -e "${CLR_ESCURO}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "   ${CLR_BRANCO}STATUS ADB: ${adb_status}${RESET} | ${CLR_CINZA}SISTEMA DE PAREAMENTO TZ${RESET}"
        echo -e "${CLR_ESCURO}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
        
        echo -e "  ${CLR_BRANCO}[ 01 ]${RESET} ${CLR_CINZA}Conectar Novo Dispositivo (Wi-Fi)${RESET}"
        echo -e "  ${CLR_BRANCO}[ 02 ]${RESET} ${CLR_RED}Desconectar / Resetar ADB${RESET}"
        echo -e "  ${CLR_BRANCO}[ 00 ]${RESET} ${CLR_CINZA}Voltar ao Menu Principal${RESET}"
        echo -e "${CLR_ESCURO}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
        
        echo -ne "  ${CLR_BRANCO}SELECIONE UMA OPÇÃO > ${RESET}"
        read -r opt_conn

        case "$opt_conn" in
            1|01)
                draw_header
                # Parte da Check_network integrada
                spinner "${CLR_CINZA}Verificando latência com o servidor...${RESET}"
                if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
                    echo -e "  ${CLR_AMARELO}[!] Aviso: Sem conexão com a internet.${RESET}"
                    sleep 1
                fi

                # Parte da check_adb integrada
                spinner "${CLR_CINZA}Iniciando Servidor ADB...${RESET}"
                adb start-server >/dev/null 2>&1 || true
                
                # Tenta reconectar pelo cache se existir
                if ! adb_is_connected && [[ -f "$CACHE_FILE" ]]; then
                    LAST_PORT=$(cat "$CACHE_FILE")
                    adb connect "127.0.0.1:$LAST_PORT" >/dev/null 2>&1 || true
                fi

                # Se ainda não estiver conectado, pede pareamento
                if ! adb_is_connected; then
                    echo -e "  ${CLR_RED}[X] Aparelho não detectado via Wi-Fi${RESET}"
                    echo -e "  ${CLR_BRANCO}Ative o Pareamento nas Opções de Desenvolvedor.${RESET}\n"
                    
                    read -p "  Porta Pareamento (Pairing Port): " PP
                    read -p "  Código Pareamento (Pairing Code): " CP
                    adb pair "127.0.0.1:$PP" "$CP"
                    
                    echo -e ""
                    read -p "  Porta de Conexão (Port): " PC
                    if adb connect "127.0.0.1:$PC"; then
                        echo "$PC" > "$CACHE_FILE"
                        echo -e "  ${CLR_VERDE}[V] Conectado com sucesso!${RESET}"
                        sleep 1
                        return 0
                    else
                        echo -e "  ${CLR_RED}[!] Falha na conexão.${RESET}"
                        sleep 2
                    fi
                else
                    echo -e "  ${CLR_VERDE}[V] Dispositivo já está conectado!${RESET}"
                    sleep 1
                    return 0
                fi
                ;;
            2|02)
                draw_header
                spinner "${CLR_RED}Desconectando dispositivos e resetando servidor...${RESET}"
                adb disconnect >/dev/null 2>&1
                adb kill-server >/dev/null 2>&1
                rm -f "$CACHE_FILE"
                echo -e "  ${CLR_VERDE}[V] ADB Resetado com sucesso.${RESET}"
                sleep 1
                ;;
            0|00)
                return 0
                ;;
            *)
                echo -e "  ${CLR_RED}Opção inválida!${RESET}"
                sleep 1
                ;;
        esac
    done
}


registrar_erro() {
    LOG_PROBLEMAS+="${CLR_RED}[✗] $1${RESET}\n"
    ((PROBLEMAS_COUNT++))
}

registrar_aviso() {
    LOG_PROBLEMAS+="${CLR_AMARELO}[!] $1${RESET}\n"
    ((PROBLEMAS_COUNT++))
}


analisetz() {
    LOG_PROBLEMAS=""
    PROBLEMAS_COUNT=0
    draw_header
    echo -e "${CLR_CINZA}Analisando dispositivo... Aguarde.${RESET}"

    # --- [1] VERIFICANDO DISPOSITIVO CONECTADO ---
    local devices=$(adb devices 2>&1)
    if [[ -z "$devices" ]] || [[ ! "$devices" =~ "device"$ ]] || [[ "$devices" =~ "unauthorized" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Nenhum dispositivo detectado ou sem autorização!${RESET}\n"
        ((PROBLEMAS_COUNT++))
    else
        local check_perm=$(adb shell "ls /sdcard 2>&1")
        if [[ "$check_perm" == *"Permission denied"* ]]; then
            LOG_PROBLEMAS+="${CLR_RED}[✗] ADB sem permissões suficientes!${RESET}\n"
            ((PROBLEMAS_COUNT++))
        fi
    fi

        # --- [2] VERIFICANDO ESTADO DE BOOT VERIFICADO ---
    local verifiedBootState=$(adb shell getprop ro.boot.verifiedbootstate 2>/dev/null | tr -d '\r')
    
    if [[ "$verifiedBootState" == "yellow" ]]; then
        LOG_PROBLEMAS+="${CLR_AMARELO}[⚠] Boot State: YELLOW - Suspeita de modificação no sistema${RESET}\n"
        ((PROBLEMAS_COUNT++))
    elif [[ "$verifiedBootState" == "orange" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Boot State: ORANGE - Bootloader desbloqueado detectado${RESET}\n"
        ((PROBLEMAS_COUNT++))
    elif [[ "$verifiedBootState" != "green" && ! -z "$verifiedBootState" ]]; then
        LOG_PROBLEMAS+="${CLR_AMARELO}[⚠] Boot State: $verifiedBootState (Desconhecido)${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi

    # --- [3] VERIFICANDO STATUS DO SELINUX ---
    local selinux=$(adb shell getenforce 2>/dev/null | tr -d '\r')
    
    if [[ "$selinux" == "Permissive" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] SELinux: PERMISSIVE - Modo permissivo detectado (Root/Bypass)${RESET}\n"
        ((PROBLEMAS_COUNT++))
    elif [[ "$selinux" != "Enforcing" && ! -z "$selinux" ]]; then
        LOG_PROBLEMAS+="${CLR_AMARELO}[⚠] SELinux: $selinux (Status desconhecido)${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi
    
    # --- [4] VERIFICANDO PROPRIEDADES DO SISTEMA ---
    local props=(
        "ro.debuggable|1|Modo debug ativado"
        "ro.secure|0|Segurança desativada"
        "service.adb.root|1|ADB root ativo"
        "ro.build.selinux|0|SELinux desabilitado"
        "ro.boot.flash.locked|0|Flash desbloqueado"
        "ro.boot.veritymode|disabled|dm-verity desabilitado"
        "sys.oem_unlock_allowed|1|OEM unlock permitido"
        "persist.sys.usb.config|adb|ADB ativo"
        "ro.kernel.qemu|1|Emulador detectado"
    )

    for item in "${props[@]}"; do
        local p_name=$(echo $item | cut -d'|' -f1)
        local p_susp=$(echo $item | cut -d'|' -f2)
        local p_desc=$(echo $item | cut -d'|' -f3)
        
        local p_val=$(adb shell getprop "$p_name" 2>/dev/null | tr -d '\r')
        
        if [[ "$p_val" == "$p_susp" ]]; then
            LOG_PROBLEMAS+="${CLR_RED}[✗] Propriedade: $p_name = $p_val ($p_desc)${RESET}\n"
            ((PROBLEMAS_COUNT++))
        fi
    done
    
    # --- [5] VERIFICANDO BINÁRIOS SU (SUPERUSUÁRIO) ---
    local binariosSU=(
        "/system/bin/su" "/system/xbin/su" "/sbin/su" "/system/su"
        "/system/bin/.ext/.su" "/data/local/su" "/data/local/bin/su"
        "/data/local/xbin/su" "/su/bin/su" "/system/sbin/su"
        "/vendor/bin/su" "/system/app/Superuser.apk" "/data/adb/magisk"
        "/data/adb/ksu" "/data/adb/ap" "/cache/su"
        "/dev/com.koushikdutta.superuser.daemon"
    )

    for bin in "${binariosSU[@]}"; do
        local check_su=$(adb shell "test -e $bin && echo FOUND" 2>/dev/null | tr -d '\r')
        if [[ "$check_su" == "FOUND" ]]; then
            LOG_PROBLEMAS+="${CLR_RED}[✗] Binário/Vestígio SU encontrado: $bin${RESET}\n"
            ((PROBLEMAS_COUNT++))
        fi
    done
    
    # --- [6] DETECÇÃO AVANÇADA DE MAGISK ---
    local magiskPkgs=$(adb shell "pm list packages 2>/dev/null | grep -iE 'magisk|topjohnwu'" | tr -d '\r')
    if [[ ! -z "$magiskPkgs" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Pacote Magisk encontrado: $magiskPkgs${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi

    local magiskDirs=("/data/adb/magisk" "/sbin/.magisk" "/data/adb/modules" "/cache/magisk.log")
    for dir in "${magiskDirs[@]}"; do
        local check_dir=$(adb shell "test -e $dir && echo FOUND" 2>/dev/null | tr -d '\r')
        if [[ "$check_dir" == "FOUND" ]]; then
            LOG_PROBLEMAS+="${CLR_RED}[✗] Diretório/Arquivo Magisk: $dir${RESET}\n"
            ((PROBLEMAS_COUNT++))
        fi
    done

    local magiskProcs=$(adb shell "ps -A 2>/dev/null | grep -iE 'magisk|magiskd'" | tr -d '\r')
    if [[ ! -z "$magiskProcs" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Processo Magisk detectado: $(echo "$magiskProcs" | head -n 1)${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi

    local magiskMounts=$(adb shell "mount 2>/dev/null | grep magisk" | tr -d '\r')
    if [[ ! -z "$magiskMounts" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Mountpoint Magisk detectado${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi
    
    # --- [7] DETECÇÃO DE KERNELSU ---
    local kernelMod=$(adb shell "lsmod 2>/dev/null | grep -i kernelsu" | tr -d '\r')
    if [[ ! -z "$kernelMod" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Módulo KernelSU detectado no kernel${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi

    local ksuFiles=("/data/adb/ksud" "/data/adb/ksu" "/proc/kernelsu")
    for kfile in "${ksuFiles[@]}"; do
        local check_ksu=$(adb shell "test -e $kfile && echo FOUND" 2>/dev/null | tr -d '\r')
        if [[ "$check_ksu" == "FOUND" ]]; then
            LOG_PROBLEMAS+="${CLR_RED}[✗] Arquivo/Diretório KernelSU: $kfile${RESET}\n"
            ((PROBLEMAS_COUNT++))
        fi
    done

    local kernelVersion=$(adb shell "uname -r 2>/dev/null | grep -i ksu" | tr -d '\r')
    if [[ ! -z "$kernelVersion" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Kernel modificado (String KSU encontrada)${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi
    
    # --- [8] DETECÇÃO DE APATCH ---
    local apatchPkgs=$(adb shell "pm list packages 2>/dev/null | grep -i apatch" | tr -d '\r')
    if [[ ! -z "$apatchPkgs" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Pacote APatch encontrado: $(echo "$apatchPkgs" | xargs)${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi

    local check_apDir=$(adb shell "test -d /data/adb/ap && echo FOUND" 2>/dev/null | tr -d '\r')
    if [[ "$check_apDir" == "FOUND" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Diretório APatch encontrado: /data/adb/ap${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi

    local apatchProp=$(adb shell "getprop 2>/dev/null | grep -i apatch" | tr -d '\r')
    if [[ ! -z "$apatchProp" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Propriedade APatch detectada no sistema${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi
    
    # --- [9] ANÁLISE DE LOGS DO KERNEL E SISTEMA ---
    local log_cmd_1="logcat -b kernel -d 2>/dev/null | grep -iE 'kernelsu|magisk|apatch'"
    local log_cmd_2="dumpsys package 2>/dev/null | grep -iE 'kernelsu|magisk|apatch' | grep -v queriesPackages | grep -vE 'KernelSupport|Freecess|ChinaPolicy' | grep -v 'used by other apps'"
    local log_cmd_3="dumpsys activity 2>/dev/null | grep -iE 'kernelsu|magisk|apatch' | grep -v queriesPackages | grep -vE 'KernelSupport|Freecess|ChinaPolicy' | grep -v 'used by other apps'"
    local log_cmd_4="dumpsys activity processes 2>/dev/null | grep -iE 'kernelsu|magisk|apatch'"

    local i=1
    while [ $i -le 4 ]; do
        local var_name="log_cmd_$i"
        local output=$(eval "adb shell \"${!var_name}\"" | tr -d '\r' | head -n 1)
        
        if [[ ! -z "$output" ]]; then
            LOG_PROBLEMAS+="${CLR_RED}[✗] Rastro de Root/Bypass encontrado em Logs (Tipo $i)${RESET}\n"
            ((PROBLEMAS_COUNT++))
        fi
        ((i++))
    done


    
    # --- [10] TESTANDO ACESSO A DIRETÓRIOS CRÍTICOS (ULTRA COMPLEXO) ---
    local dirs_criticos=(
        "/system/bin|Binários do sistema"
        "/data/data/com.dts.freefireth/files|Dados Free Fire TH"
        "/data/data/com.dts.freefiremax/files|Dados Free Fire MAX"
        "/storage/emulated/0/Android/data|Dados de aplicativos"
        "/data/adb|Diretório ADB/Root"
        "/system/xbin|Binários estendidos"
        "/data/local/tmp|Pasta temporária shell"
    )

    for item in "${dirs_criticos[@]}"; do
        local d_path=$(echo "$item" | cut -d'|' -f1)
        local d_desc=$(echo "$item" | cut -d'|' -f2)

        local res_ls=$(adb shell "ls -la \"$d_path\" 2>&1 | head -n 5" | tr -d '\r')

        local is_bind=$(adb shell "mount 2>/dev/null | grep \"$d_path\"" | tr -d '\r')

        if [[ -z "$res_ls" ]]; then
          
             if [[ "$d_path" == "/system/bin" ]]; then
                LOG_PROBLEMAS+="${CLR_AMARELO}[⚠] Sem resposta crítica em: $d_path ($d_desc)${RESET}\n"
                ((PROBLEMAS_COUNT++))
             fi
        elif [[ "$res_ls" == *"blocked"* ]] || [[ "$res_ls" == *"redirected"* ]] || [[ "$res_ls" == *"bypass"* ]] || [[ "$res_ls" == *"Permission denied"* && "$d_path" == "/storage/emulated/0/Android/data" ]]; then
            LOG_PROBLEMAS+="${CLR_RED}[✗] BYPASS DETECTADO: Acesso manipulado em $d_path ($d_desc)${RESET}\n"
            LOG_PROBLEMAS+="${CLR_ESCURO}    Motivo: Bloqueio ou Redirecionamento de leitura.${RESET}\n"
            ((PROBLEMAS_COUNT++))
        fi

   
        if [[ ! -z "$is_bind" ]] && [[ "$d_path" == *"com.dts"* ]]; then
            LOG_PROBLEMAS+="${CLR_RED}[✗] REDIRECIONAMENTO ATIVO: $d_path está montado via software (Bypass)${RESET}\n"
            ((PROBLEMAS_COUNT++))
        fi
    done
    
    # --- [11] VERIFICANDO PROCESSOS SUSPEITOS (VARREDURA PROFUNDA) ---
    local ps_output=$(adb shell "ps -A" 2>/dev/null | grep -v "\[.*\]" | tr -d '\r')

    local regex_suspeito="(bypass|redirect|fake|hide|cloak|stealth|hook|inject|cheat|modded|vskin|re管理器|mt_manager|np_manager|lsposed|frida)"

    local regex_ignore="(drm_fake_vsync|mtk_drm_fake_vsync|mtk_drm_fake_vs|com.android|com.google|system_server)"


    local processos_encontrados=$(echo "$ps_output" | grep -iE "$regex_suspeito" | grep -vE "$regex_ignore")

    if [[ ! -z "$processos_encontrados" ]]; then

        local nomes_unicos=$(echo "$processos_encontrados" | awk '{print $NF}' | sort -u)
        
        LOG_PROBLEMAS+="${CLR_RED}[✗] PROCESSOS DE MANIPULAÇÃO DETECTADOS:${RESET}\n"
        while read -r proc_name; do
            LOG_PROBLEMAS+="${CLR_AMARELO}    • $proc_name${RESET}\n"
        done <<< "$nomes_unicos"
        
        ((PROBLEMAS_COUNT++))
    fi
    
# [12] VERIFICAÇÃO DE REDE E APPS SUSPEITOS
    local interfaces=$(adb shell "ip link 2>/dev/null | grep -E 'tun0|ppp0|wg0'" | tr -d '\r')
    if [[ ! -z "$interfaces" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[✗] Interface VPN/Tunnel detectada: $(echo "$interfaces" | xargs)${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi

    local privateDns=$(adb shell "settings get global private_dns_mode 2>/dev/null" | tr -d '\r')
    local dns1=$(adb shell "getprop net.dns1 2>/dev/null" | tr -d '\r')
    if [[ "$privateDns" == "hostname" ]] || [[ "$privateDns" != "off" && "$privateDns" != "null" && ! -z "$privateDns" ]]; then
        LOG_PROBLEMAS+="${CLR_AMARELO}[⚠] DNS Privado Ativo (Modo: $privateDns)${RESET}\n"
        ((PROBLEMAS_COUNT++))
    elif [[ "$dns1" == "1.1.1.1" || "$dns1" == "8.8.8.8" || "$dns1" == "9.9.9.9" ]]; then
        LOG_PROBLEMAS+="${CLR_AMARELO}[⚠] DNS Público Detectado: $dns1${RESET}\n"
    fi

    local pacotes=$(adb shell "pm list packages 2>/dev/null" | tr -d '\r')
    local apps=(
        "moe.shizuku.privileged.api|Shizuku"
        "com.lexa.fakegps|Fake GPS"
        "com.lbe.parallel|Parallel Space"
        "com.excelliance.multiaccounts|Multi Accounts"
        "trickystore|TrickyStore (Bypass)"
        "shamiko|Shamiko (Hide Root)"
        "com.topjohnwu.magisk|Magisk Manager"
        "io.github.huskydg.magisk|Delta Magisk"
        "com.kdrag0n.protoprop|ProtoProp"
        "com.pif.features|PIF (Bypass)"
    )

    for item in "${apps[@]}"; do
        local pkg=$(echo "$item" | cut -d'|' -f1)
        local nome=$(echo "$item" | cut -d'|' -f2)
        if [[ "$pacotes" == *"$pkg"* ]]; then
            LOG_PROBLEMAS+="${CLR_AMARELO}[⚠] App Suspeito: $nome ($pkg)${RESET}\n"
            ((PROBLEMAS_COUNT++))
        fi
    done
    
# [13] VERIFICAÇÃO DE ARQUIVOS EM /DATA/LOCAL/TMP
        local check_perm=$(adb shell "ls /data/local/tmp 2>&1")
    
    if [[ "$check_perm" == *"Permission denied"* ]]; then
        LOG_PROBLEMAS+="${CLR_RED}[!] ACESSO NEGADO: Pasta oculta pelo usuário. APLIQUE W.O.${RESET}\n"
        ((PROBLEMAS_COUNT++))
    else
        local tmp_files=$(adb shell "ls -A /data/local/tmp 2>/dev/null" | tr -d '\r')

        if [[ ! -z "$tmp_files" ]]; then
            LOG_PROBLEMAS+="${CLR_AMARELO}[⚠] Arquivos encontrados em /data/local/tmp:${RESET}\n"
            while read -r f; do
                [[ -z "$f" ]] && continue

                if [[ "$f" =~ (mantis|shaders|wall|holograma|\.sh) ]]; then
                    LOG_PROBLEMAS+="${CLR_RED}    ✗ DETECTADO: $f (rastros)${RESET}\n"
                    ((PROBLEMAS_COUNT++))
                else
                    LOG_PROBLEMAS+="${CLR_CINZA}    • $f${RESET}\n"
                fi
            done <<< "$tmp_files"
        fi
    fi

   


    
    # [14] VERIFICANDO APLICATIVOS DESINSTALADOS SUSPEITOS
    local log_output=$(adb shell "logcat -d -v time -s ActivityManager:I PackageManager:I | grep -iE 'deletePackageX|pkg removed'" | tr -d '\r')
    local encontrou_removido=0
    local agora_seg=$(date +%s)

    if [[ ! -z "$log_output" ]]; then
        while read -r line; do

            local pkg_name=$(echo "$line" | grep -oE 'Force stopping [^ ]+' | awk '{print $3}')
            local log_time_str=$(echo "$line" | awk '{print $1" "$2}' | cut -d'.' -f1)

            local log_seg=$(date -d "$(date +%Y)-$log_time_str" +%s 2>/dev/null)


            if [[ ! -z "$log_seg" ]] && (( agora_seg - log_seg <= 3600 )); then

                local manual=$(adb shell "logcat -d -v time | grep -iE 'android.intent.action.DELETE|UninstallerActivity' | grep '$pkg_name'" | tr -d '\r')
                
                if [[ -z "$manual" ]]; then
                    LOG_PROBLEMAS+="${CLR_RED}[!] DESINSTALAÇÃO SUSPEITA: $pkg_name${RESET}\n"
                    LOG_PROBLEMAS+="${CLR_AMARELO}    Método: Comando/Script (Sem interface gráfica)${RESET}\n"
                    ((PROBLEMAS_COUNT++))
                    encontrou_removido=1
                fi
            fi
        done <<< "$log_output"
    fi
    
    # [15] DETECTOR DE REPLAY (PASSADOR)
           local replay_path="/storage/emulated/0/Android/data/$SELECT_PACK/files/MReplays"
    local last_replay=$(adb shell "ls -t $replay_path/*.bin 2>/dev/null | head -n 1" | tr -d '\r')

    if [[ -z "$last_replay" ]]; then
        LOG_PROBLEMAS+="${CLR_CINZA}[i] Nenhum arquivo de Replay (.bin) encontrado.${RESET}\n"
    else
        local replay_name=$(basename "$last_replay")
        local stat_replay=$(adb shell "stat '$last_replay'" 2>/dev/null)
        
        if [[ ! -z "$stat_replay" ]]; then
            LOG_PROBLEMAS+="${CLR_AMARELO}► DETECTOR DE PASSADOR DE REPLAY:${RESET}\n"
            LOG_PROBLEMAS+="${CLR_BRANCO}  ARQUIVO: ${CLR_CINZA}$replay_name${RESET}\n"
            
            # Extrai Uid, Gid e as datas do arquivo
            local uid_info=$(echo "$stat_replay" | grep "Uid:" | tail -n 1)
            local access_time=$(echo "$stat_replay" | grep "Access:" | tail -n 1)
            local modify_time=$(echo "$stat_replay" | grep "Modify:" | tail -n 1)
            local change_time=$(echo "$stat_replay" | grep "Change:" | tail -n 1)

            # Exibe no log final
            LOG_PROBLEMAS+="${CLR_CINZA}  $uid_info${RESET}\n"
            LOG_PROBLEMAS+="${CLR_CINZA}  $access_time${RESET}\n"
            LOG_PROBLEMAS+="${CLR_CINZA}  $modify_time${RESET}\n"
            LOG_PROBLEMAS+="${CLR_CINZA}  $change_time${RESET}\n"

            local m_timestamp=$(date -d "$(echo $modify_time | cut -d' ' -f2,3 | cut -d'.' -f1)" +%s 2>/dev/null)
            local c_timestamp=$(date -d "$(echo $change_time | cut -d' ' -f2,3 | cut -d'.' -f1)" +%s 2>/dev/null)

            if [[ "$m_timestamp" == "$c_timestamp" ]]; then
                LOG_PROBLEMAS+="${CLR_AMARELO}  [!] ANÁLISE A STAT PARA VER SE TEM ALGUMA MODIFICAÇÃO!!!${RESET}\n"
                ((PROBLEMAS_COUNT++))
            fi
        fi
    fi


   # [16] detector de bypass Wall
   
        local wall_path="/storage/emulated/0/Android/data/$SELECT_PACK/files/contentcache/Optional/android/gameassetbundles"
    # Procura o arquivo mais recente que começa com 'shader'
    local last_shader=$(adb shell "ls -t $wall_path/shader* 2>/dev/null | head -n 1" | tr -d '\r')

    if [[ -z "$last_shader" ]]; then
        LOG_PROBLEMAS+="${CLR_CINZA}[i] Nenhum Shader modificado encontrado no cache.${RESET}\n"
    else
        local shader_name=$(basename "$last_shader")
        local stat_shader=$(adb shell "stat '$last_shader'" 2>/dev/null)
        
        if [[ ! -z "$stat_shader" ]]; then
            LOG_PROBLEMAS+="${CLR_AMARELO}► DETECTOR DE BYPASS WALL:${RESET}\n"
            LOG_PROBLEMAS+="${CLR_BRANCO}  ARQUIVO: ${CLR_CINZA}$shader_name${RESET}\n"
            
            # Extrai Uid e as datas de modificação
            local s_uid=$(echo "$stat_shader" | grep "Uid:" | tail -n 1)
            local s_access=$(echo "$stat_shader" | grep "Access:" | tail -n 1)
            local s_modify=$(echo "$stat_shader" | grep "Modify:" | tail -n 1)
            local s_change=$(echo "$stat_shader" | grep "Change:" | tail -n 1)

            # Exibe no log final do TZ Scanner
            LOG_PROBLEMAS+="${CLR_CINZA}  $s_uid${RESET}\n"
            LOG_PROBLEMAS+="${CLR_CINZA}  $s_access${RESET}\n"
            LOG_PROBLEMAS+="${CLR_CINZA}  $s_modify${RESET}\n"
            LOG_PROBLEMAS+="${CLR_CINZA}  $s_change${RESET}\n"

            # Verificação de integridade do Shader
            local sm_ts=$(date -d "$(echo $s_modify | cut -d' ' -f2,3 | cut -d'.' -f1)" +%s 2>/dev/null)
            local sc_ts=$(date -d "$(echo $s_change | cut -d' ' -f2,3 | cut -d'.' -f1)" +%s 2>/dev/null)

            if [[ "$sm_ts" == "$sc_ts" ]]; then
                LOG_PROBLEMAS+="${CLR_AMARELO}  [!] ANÁLISE A STAT PARA VER SE TEM ALGUMA MODIFICAÇÃO!!!${RESET}\n"
                ((PROBLEMAS_COUNT++))
            fi
        fi
    fi

    # [17] DETECTOR DE MANIPULAÇÃO DE DATA E HORA
    local logcat_time=$(adb logcat -d -v time | head -n 2 | grep -oE '[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}')
    
    if [[ ! -z "$logcat_time" ]]; then
        LOG_PROBLEMAS+="${CLR_AMARELO}► STATUS DO SISTEMA:${RESET}\n"
        LOG_PROBLEMAS+="${CLR_BRANCO}  Primeira log: $logcat_time${RESET}\n"
        LOG_PROBLEMAS+="${CLR_CINZA}  (Se a data acima for após a partida, aplique W.O)${RESET}\n"
    else
        LOG_PROBLEMAS+="${CLR_RED}  ✗ Falha ao capturar timestamp do sistema.${RESET}\n"
    fi

    local fuso=$(adb shell getprop persist.sys.timezone | tr -d '\r')
    if [[ "$fuso" != "America/Sao_Paulo" ]]; then
        LOG_PROBLEMAS+="${CLR_AMARELO}  ⚠ Fuso Horário: $fuso (Suspeito)${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi

    local time_changes=$(adb logcat -d | grep "UsageStatsService: Time changed" | grep -v "HCALL" | tr -d '\r')
    if [[ ! -z "$time_changes" ]]; then
        LOG_PROBLEMAS+="${CLR_AMARELO}  ⚠ ALTERAÇÕES DE HORÁRIO DETECTADAS:${RESET}\n"
        while read -r line; do
            [[ -z "$line" ]] && continue
            LOG_PROBLEMAS+="${CLR_RED}    ! $line${RESET}\n"
            ((PROBLEMAS_COUNT++))
        done <<< "$time_changes"
    fi

    local auto_time=$(adb shell settings get global auto_time | tr -d '\r')
    local auto_zone=$(adb shell settings get global auto_time_zone | tr -d '\r')

    if [[ "$auto_time" != "1" ]] || [[ "$auto_zone" != "1" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}  ✗ BYPASS: Data/Hora Automática DESATIVADA!${RESET}\n"
        ((PROBLEMAS_COUNT++))
    else
        LOG_PROBLEMAS+="${CLR_VERDE}  [V] Data/Hora Automática: OK${RESET}\n"
    fi
    


    
    # [18] DETECTOR DE KERNEL E ASSINATURAS DE ROOT (KERNELSU / APATCH / MAGISK)
    local kernel_version=$(adb shell "cat /proc/version" 2>/dev/null | tr -d '\r')
    local uname_info=$(adb shell "uname -a" 2>/dev/null | tr -d '\r')
    local root_files=$(adb shell "ls -d /system/bin/su /system/xbin/su /sbin/su /data/local/xbin/su /data/local/bin/su /system/sd/xbin/su /system/bin/failsafe/su /data/local/su 2>/dev/null" | tr -d '\r')

    LOG_PROBLEMAS+="${CLR_AMARELO}► INTEGRIDADE DO KERNEL E ROOT:${RESET}\n"

    if [[ "$kernel_version" =~ (KernelSU|APatch|KSU|Magisk|Zen|Extreme|Performance|Custom|Chaos|Storm) ]]; then
        LOG_PROBLEMAS+="${CLR_RED}  [!] KERNEL SUSPEITO: $(echo $kernel_version | cut -d' ' -f1-4)${RESET}\n"
        LOG_PROBLEMAS+="${CLR_AMARELO}      Assinatura de modificação detectada no Kernel.${RESET}\n"
        ((PROBLEMAS_COUNT++))
    else
        LOG_PROBLEMAS+="${CLR_VERDE}  [V] Kernel: Oficial/Original${RESET}\n"
    fi

    if [[ "$uname_info" =~ (root|lineage|pixel|corvus|evolution|havoc|crDroid|arrow) ]]; then
        LOG_PROBLEMAS+="${CLR_CINZA}  • Info: $uname_info${RESET}\n"
    fi

    if [[ ! -z "$root_files" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}  [!] BINÁRIO SU ENCONTRADO:${RESET}\n"
        while read -r line; do
            [[ -z "$line" ]] && continue
            LOG_PROBLEMAS+="${CLR_RED}    ✗ $line${RESET}\n"
            ((PROBLEMAS_COUNT++))
        done <<< "$root_files"
    fi


    local mount_info=$(adb shell "mount" | grep " /system " | grep -E "rw,|rw " | tr -d '\r')
    if [[ ! -z "$mount_info" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}  [!] SISTEMA ABERTO: Partição /system montada como RW (Root).${RESET}\n"
        ((PROBLEMAS_COUNT++))
    fi
    
    
# [19] VERIFICADOR DE FONTE E INTEGRIDADE DO APK (UNIVERSAL ANDROID 8-14)
    LOG_PROBLEMAS+="${CLR_AMARELO}► ORIGEM E INTEGRIDADE ($SELECT_PACK):${RESET}\n"

    local installer_raw=$(adb shell "pm list packages -i $SELECT_PACK" 2>/dev/null | grep "package:$SELECT_PACK")
    local installer=$(echo "$installer_raw" | awk -F'installer=' '{print $2}' | tr -d '\r ')

    local sig_raw=$(adb shell "dumpsys package $SELECT_PACK | grep -A 1 'signatures=' | tail -n 1" | tr -d '[:space:]\r')
    local signature=$(echo "$sig_raw" | sed 's/[][]//g')

    if [[ -z "$installer" || "$installer" == "null" ]]; then
        LOG_PROBLEMAS+="${CLR_RED}  [!] ALERTA: Instalado via APK manual (Sideload/ADB)!${RESET}\n"
        ((PROBLEMAS_COUNT++))
    elif [[ "$installer" =~ (vending|google|xiaomi|mipicks|samsung|amazon|huawei|oppo|vivo|motorola|sony|lg|claro|tim|oi|vivo) ]]; then
        LOG_PROBLEMAS+="${CLR_VERDE}  [V] Fonte: Loja Oficial ($installer)${RESET}\n"
    else
        LOG_PROBLEMAS+="${CLR_AMARELO}  ⚠ Fonte: $installer (Verificar manual)${RESET}\n"
    fi

    if [[ -z "$signature" || ${#signature} -lt 10 ]]; then
        LOG_PROBLEMAS+="${CLR_RED}  [!] ASSINATURA: APK Inexistente ou Corrompido!${RESET}\n"
        ((PROBLEMAS_COUNT++))
    else
        LOG_PROBLEMAS+="${CLR_CINZA}  • Signature ID: ${signature:0:20}... (Verificada)${RESET}\n"
    fi

    local inst_date=$(adb shell "dumpsys package $SELECT_PACK | grep 'firstInstallTime'" | awk -F'=' '{print $2}' | tr -d '\r')
    if [[ ! -z "$inst_date" ]]; then
        LOG_PROBLEMAS+="${CLR_BRANCO}  Instalado em: $inst_date${RESET}\n"
    fi

    

# --- FINALIZAÇÃO E RESUMO (O "BOTÃO") ---

    while true; do
        draw_header
    echo -e "\n${CLR_BRANCO}  ╔════════════════════════════════════════════╗${RESET}"
    echo -e "${CLR_BRANCO}             RESUMO DA ANÁLISE            ${RESET}"
    echo -e "${CLR_BRANCO}  ╠════════════════════════════════════════════╣${RESET}"
    echo -e "${CLR_BRANCO}    Alertas: ${CLR_AMARELO}$PROBLEMAS_COUNT${CLR_BRANCO}                            ${RESET}"
    
    if [ $PROBLEMAS_COUNT -eq 0 ]; then
        echo -e "${CLR_BRANCO}    Status:  ${CLR_VERDE}● DISPOSITIVO LIMPO${CLR_BRANCO}           ${RESET}"
        echo -e "${CLR_BRANCO}  ╚════════════════════════════════════════════╝${RESET}"
        echo -e "\n  ${CLR_VERDE}✓ Nenhuma modificação crítica detectada.${RESET}"
    else
        echo -e "${CLR_BRANCO}    Status:  ${CLR_RED}● MODIFICAÇÕES DETECTADA${CLR_BRANCO}            ${RESET}"
        echo -e "${CLR_BRANCO}  ╚════════════════════════════════════════════╝${RESET}"
        
        echo -e "\n  ${CLR_RED}  MODIFICAÇÕES IDENTIFICADAS!${RESET}"
        echo -e "  ${CLR_ESCURO}--------------------------------------------${RESET}"
        
        # Aqui ele joga TODAS as logs de uma vez só, sem frescura
        echo -e "$LOG_PROBLEMAS"
        
        echo -e "  ${CLR_ESCURO}--------------------------------------------${RESET}"
       
    fi

    echo -ne "\n  ${CLR_BRANCO}PRESSIONE ENTER PARA VOLTAR AO MENU...${RESET}"
    read -r
    menu
    done
    
}

# --- Menu Principal ---
menu() {
    while true; do
        draw_header
        
        local adb_status="${CLR_RED}OFFLINE${RESET}"
        adb_is_connected && adb_status="${CLR_VERDE}ONLINE${RESET}"

        echo -e "${CLR_ESCURO}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "   ${CLR_BRANCO}ADB: ${adb_status}${RESET} | ${CLR_BRANCO}PROJETO:${RESET} ${CLR_CINZA}TZ SCANNER${RESET}"
        echo -e "${CLR_ESCURO}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
       
        echo -e "  ${CLR_BRANCO}[ 01 ]${RESET} ${CLR_CINZA}Analisar Free Fire Normal${RESET}"
        echo -e "  ${CLR_BRANCO}[ 02 ]${RESET} ${CLR_CINZA}Analisar Free Fire MAX${RESET}"
        echo -e "  ${CLR_BRANCO}[ 03 ]${RESET} ${CLR_CINZA}Reconectar ADB${RESET}"
        echo -e "  ${CLR_RED}[ 00 ]${RESET} ${CLR_RED}Sair do Scanner${RESET}"
        echo -e "${CLR_ESCURO}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
        
        echo -ne "  ${CLR_BRANCO}SELECIONE UMA OPÇÃO > ${RESET}"
        
        read -r opcao
        
        case "$opcao" in
            1|01) 
                SELECT_PACK="com.dts.freefireth"
                # Verifica se o Free Fire Normal está instalado
                if adb shell "pm list packages" | grep -q "$SELECT_PACK"; then
                    GAME_NAME="Free Fire Normal"
                    analisetz 
                else
                    echo -e "  ${CLR_RED}[X] Erro: Free Fire Normal não está instalado!${RESET}"
                    sleep 2
                fi
                ;;
            2|02) 
                SELECT_PACK="com.dts.freefiremax"
                # Verifica se o Free Fire MAX está instalado
                if adb shell "pm list packages" | grep -q "$SELECT_PACK"; then
                    GAME_NAME="Free Fire MAX"
                    analisetz 
                else
                    echo -e "  ${CLR_RED}[X] Erro: Free Fire MAX não está instalado!${RESET}"
                    sleep 2
                fi
                ;;
            3|03)
            echo -e "${CLR_AMARELO}Reiniciando servidor ADB...${RESET}"
                gerenciar_conexao
                ;;
            0|00) 
                echo -e "  ${CLR_CINZA}Saindo...${RESET}"
                exit 0 
                ;;
            *) 
                echo -e "  ${CLR_RED}Opção inválida!${RESET}" 
                sleep 1 
                ;;
        esac
    done
}


menu
