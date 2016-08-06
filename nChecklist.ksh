#!/bin/ksh 

############################################
#                                          #
#    IBM - CHECKLIST - AIX - VIO           #
#                                          #
# Autor: Leonardo D`Angelo Goncalves       #
# E-mail: ldangelo@br.ibm.com              #
#                                          #
#                                          #
############################################
# Checklist de IBM AIX/VIO com objetivo de #
# levantar iformacoes para simples confe   #
# rencia apos boot do servidor             #
#                                          #
#                                          #
############################################

#################
# Configuracoes #
#################

# Dir

dirLog="/so_ibm/log/checklist"                                                  # Diretorio onde ficarao os checklists
dirZip="/so_ibm/log/checklist_old"                                              # Diretorio onde ficarao os checklists compactados ou rotacionados
dirImage="/so_ibm/log/image"
dirSup="/so_ibm/suporte"

# Files

backupFile="chkpath.bck"                                                        # Arquivo onde ficam os paths para efetuar backup
bestPracticeFile="$dirLog/$(hostname)-bp.wp"
finalWebFile="$dirLog/$(hostname).wp"                                           # Arquivo Web Final
formatFile=$(date +"%d-%m-%Y-%H-%M").$(hostname).checklist                      # Formato do arquivo de saida
tempWebSumFile="$dirLog/tempWebSumFile"                                         # Arquivo Web sumario temporario
tempWebCheckFile="$dirLog/tempWebCheckFile"                                     # Arquivo Web checks temporario

# Path

PATH="$PATH:/usr/es/sbin/cluster/utilities/:/usr/lpp/mmfs/bin/mmlspv"           # Variavel PATH
pathCluster="/usr/es/sbin/cluster/utilities/"                                   # PATH dos binarios do cluster
pathGpfs="/usr/lpp/mmfs/bin/mmlspv/"                                            # PATH dos binarios do GPFS

maxRotate="10"                                                                  # Rotacionar a partir de X checklists

###########
# Funcoes #
###########



######################################
# Nome: testDirs                     #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Testa a existencia dos diretorio,  #
# em caso da não existencia o mesmo  #
# é criado.                          #
######################################

function testDirs
{
    # Teste do diretorio de log #
    if [ ! -d "$dirLog" ]
    then
            echo "[INFO] Diretorio nao existe ou nao encontrado"
            echo "[INFO] Criando diretorio de log"
            mkdir -p $dirLog
            if [ $? -ne 0 ]
            then
                    echo "[ERRO] Falha ao criar diretorio"
                    exit 1
            fi
    fi
    
    # Teste do diretorio de log compactados #
    if [ ! -d "$dirZip" ]
    then
            echo "[INFO] Diretorio nao existe ou nao encontrado"
            echo "[INFO] Criando diretorio de logs compactados"
            mkdir -p $dirZip
            if [ $? -ne 0 ]
            then
                    echo "[ERRO] Falha ao criar diretorio"
                    exit 1
            fi
    fi
    if [ ! -d "$dirImage" ]
    then
            echo "[INFO] Diretorio nao existe ou nao encontrado"
            echo "[INFO] Criando diretorio de logs compactados"
            mkdir -p $dirImage
            if [ $? -ne 0 ]
            then
                    echo "[ERRO] Falha ao criar diretorio"
                    exit 1
            fi
    fi

}


######################################
# Nome: tputcmds                     #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #        
# Macros para a formatacao do termi  #
# nal                                #
######################################

function tputcmds
{
        tputClr=$(tput clear)           # Limpa a tela
        tputSc=$(tput sc)               # Salva a posicao do cursor
        tputRc=$(tput rc)               # Restaura a posicao do cursor
        tputB1=$(tput setb 1)           # Configura cor de fundo para azul
        tputB0=$(tput setb 0)           # Configura cor de fundo para preto
        tputF1=$(tput setf 1)           # Configura cor da fonte para azul
        tputF7=$(tput setf 7)           # Configura a cor da fonte para branco
}

######################################
# Nome: printTop                     #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Funcao responsavel pelo desenho do #
# cabecalho principal                #
######################################

function printTop
{
        clear
        tputcmds
        echo "$tputF1 ############################################################# $tputF7"
        echo "$tputF1 ## $tputF7             Checklist AIX - Virtual IO                $tputF1 ## $tputF7"
        echo "$tputF1 ## $tputF7                                                       $tputF1 ## $tputF7"
        echo "$tputF1 ## $tputF7                                                       $tputF1 ## $tputF7"
        echo "$tputF1 ############################################################# $tputF7"
        echo "$tputF1 ## $tputF7                                                       $tputF1 ## $tputF7"
        echo "$tputF1 ## $tputF7                                                       $tputF1 ## $tputF7"
}  

######################################
# Nome: printLeft                    #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Funcao responsavel pelo desenho da #
# lateral esquerda                   #
######################################

function printLeft
{
        echo "$tputF1 ## $tputF7" 
}

######################################
# Nome: checkUID                     #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Função para checagem do usuario    #
# que executa o script tem poderes   #
# de root                            #
######################################

function checkUID
{
        # Caso o UID de quem chama este scritp seja diferente de 0 (root)
    if [ `whoami` != "root" ]
    then
        echo "Apenas execute este script como root!"
        exit 1
    fi
}

######################################
# Nome: printPasso                   #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# função que exibe o progresso de    #
# execução                           #
######################################

function printPasso
{
        tput sc
        tput cup 20 "$count"
        echo ">"
        tput rc

}

######################################
# Nome: printGauge                   #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Exibe a barra de progresso         #
######################################

function printGauge
{
        echo "$tputF1 ############################################################# $tputF7"
        echo "[...............................................................]"
}

######################################
# Nome: printTittle                  #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Função que exibe na tela o item    #
# que esta sendo verificado          #
######################################

function printTittle
{
        tput sc
        echo "Executando: $chkTittle                      "
        sleep 1
        tput rc
        printPasso
}

######################################
# Nome: printHdr                     #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Cabeçalho do arquivo de cada item  #
######################################

function printHdr
{
        echo "################# Inicio #################" >> $dirLog/$cmd.$formatFile
        echo "############### $chkTittle ###############" >> $dirLog/$cmd.$formatFile
}

######################################
# Nome: printHdrWeb                  #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Cabeçalho d arquivo de cada item  #
# para a versão web                  #
######################################


function printHdrWeb
{
      echo "<h3>$1</h3>"                >> $tempWebCheckFile
      echo "Checklist: $2"              >> $tempWebCheckFile
      echo "<pre>"                      >> $tempWebCheckFile
}

######################################
# Nome: printBtm                     #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Rodapé do arquivo de cada item     #
######################################

function printBtm
{
        echo "################## Fim ###################" >> $dirLog/$cmd.$formatFile
}

######################################
# Nome: suporteFiles                 #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Funcao de criacao dos arquivos de  #
# suporte                            #
######################################

function suporteFiles
{
    # Teste do diretorio de log #
    if [ ! -d $dirSup ]
    then
            echo "[INFO] Diretorio nao existe ou nao encontrado"
            echo "[INFO] Criando diretorio de Suporte"
            mkdir -p $dirSup
    fi
    if [ ! -e $dirSup/suporte.txt ]
    then
         touch $dirSup/suporte.txt
         touch $dirSup/preboot.txt
         touch $dirSup/posboot.txt
                                echo "#######################"                                  >  $dirSup/suporte.txt
                                echo "# Informacoes Basicas #"                                  >> $dirSup/suporte.txt
                                echo "#######################"                                  >> $dirSup/suporte.txt
                                echo ""                                                         >> $dirSup/suporte.txt
                                echo "Contingencia do ambiente:"                                >> $dirSup/suporte.txt
                                echo "Bussiness Impact:"                                        >> $dirSup/suporte.txt
                                echo "Descricao do ambiente:"                                   >> $dirSup/suporte.txt
                                echo "Service line envolvidas:"                                 >> $dirSup/suporte.txt
                                echo "Melhor data para indisponibilidade"                       >> $dirSup/suporte.txt
                                echo "####################################################"     >> $dirSup/suporte.txt
                                echo ""                                                         >> $dirSup/suporte.txt
                                echo "############### LOG de Mudancas ####################"     >> $dirSup/suporte.txt
                                echo "####################################################"     >> $dirSup/suporte.txt
                                echo "EOF"                                                      >> $dirSup/suporte.txt

                                echo "#######################"                                  >  $dirSup/preboot.txt
                                echo "# Atividades Pre-boot #"                                  >> $dirSup/preboot.txt
                                echo "#######################"                                  >> $dirSup/preboot.txt
                                echo ""                                                         >> $dirSup/preboot.txt
                                echo "Ordem de atuacao das Service Lines:"                      >> $dirSup/preboot.txt
                                echo "####################################################"     >> $dirSup/preboot.txt
                                echo ""                                                         >> $dirSup/preboot.txt
                                echo "################ Atividades ########################"     >> $dirSup/preboot.txt
                                echo "EOF"                                                      >> $dirSup/preboot.txt

                                echo "#######################"                                  >  $dirSup/posboot.txt
                                echo "# Atividades Pos-boot #"                                  >> $dirSup/posboot.txt
                                echo "#######################"                                  >> $dirSup/posboot.txt
                                echo ""                                                         >> $dirSup/posboot.txt
                                echo "Ordem de atuacao das Service Lines:"                      >> $dirSup/posboot.txt
                                echo "####################################################"     >> $dirSup/posboot.txt
                                echo ""                                                         >> $dirSup/posboot.txt
                                echo "################ Atividades ########################"     >> $dirSup/posboot.txt    
                                echo "EOF"                                                      >> $dirSup/posboot.txt
                fi
                        if [ $? != 0 ]
                                then
                                        echo "[ERRO] Falha ao criar diretorio"
                                exit 1
                        fi
}

######################################
# Nome: printBtm                     #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          # 
#                                    #
# Rodapé do arquiv de cada item      #
# do checklist web                   #
######################################

function printBtmWeb
{
        echo "</pre>" >> $tempWebCheckFile
}

######################################
# Nome: sumarioHardware              #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Esta funcao coleta as informacoes  #
# a serem exibidas no momento de exe #
# cução do checklist                 #
######################################

function sumarioHardware
{
        tputcmds
        set -A variableArray LPARNAME CPUDESIRED CPUVIRTUAL MEMTOTAL SERIAL TYPEMODEL DATE DATEU CPUMHZ OSLEVEL IOSLEVEL HMC

        LPARNAME="$(uname -L | awk '{print $NF}')"
        CPUDESIRED="$(lparstat -i | grep 'Desired Capacity' | cut -d':' -f2)"
        CPUVIRTUAL="$(lparstat -i | grep 'Online Virtual CPUs' | cut -d':' -f2)"
        MEMTOTAL="$(lparstat -i | grep 'Online Memory' | cut -d':' -f2)"
        SERIAL="$(uname -u)"
        TYPEMODEL="$(uname -M)"
        DATE="$(date)"
        DATEU="$(date -u)"
        CPUMHZ="$(pmcycles -m | cut -d" " -f5 | uniq)"
        OSLEVEL="$(oslevel -s)"

        # Presume-se nao VIO ate que se prove o contrario
        IOSLEVEL="Not a VIO server"
        [ -f /usr/ios/cli/ioscli ] && IOSLEVEL="$(/usr/ios/cli/ioscli ioslevel 2> /dev/null)"

        HMC="$(lsrsrc IBM.MCP | egrep "KeyToken|HMCIPAddr" | awk '{ print $3}')"

        arrayCounter=0
        tputCol=6

                # Checklist Web - Gerador de sumario e cabecalho
        ##########################################################
        echo "<h2>Checklist Web</h2>"                   >  $tempWebSumFile
        echo "[toc]"                                                    >> $tempWebSumFile
        echo "<h3>Hostname: `uname -n`</h3>"    >> $tempWebSumFile
                echo "<h3>Server Summary:</h3>"                 >> $tempWebSumFile
        echo "[table style=\"1\"]"                              >> $tempWebSumFile
        echo "<table>"                                                  >> $tempWebSumFile
        echo "<tbody>"                                                  >> $tempWebSumFile


        while [ $arrayCounter -lt ${#variableArray[*]} ]
        do
                thisVariable=${variableArray[$arrayCounter]}    
                eval localVar=\$$thisVariable
                case $thisVariable in
                        LPARNAME)      thisLabel="LPAR Name:";;
                                CPUDESIRED)    thisLabel="CPU Desired:";;
                                        CPUVIRTUAL)    thisLabel="CPU Virtual:";;
                                        MEMTOTAL)      thisLabel="Memoria:";;
                                        TYPEMODEL)     thisLabel="Tipo e Modelo:";;
                                        SERIAL)        thisLabel="Serial:";;
                                        DATE)          thisLabel="Date:";;
                                        DATEU)         thisLabel="Date UTC:";;
                                        CPUMHZ)        thisLabel="CPU Mhz:";;
                                        OSLEVEL)       thisLabel="Versao AIX:";;
                                        IOSLEVEL)      thisLabel="Versao VIO:";;
                                        HMC)           thisLabel="Console HMC:";;
                        esac
                tputCol=$((tputCol+1));
                echo "$tputF1 ## $tputF7 $thisLabel $(tput cup $tputCol 20) $localVar" $(tput cup $tputCol 58) "$tputF1 ## $tputF7"

                # Saida do sumario para o arquivo web
                echo "<tr><td>`echo $thisLabel | cut -d: -f1`:</td><td>$localVar</td></tr>" >> $tempWebSumFile

                arrayCounter=$(($arrayCounter+1))
        done

                # Checklist Web - Fecha a tabela sumario web
                #################################
                echo "</tbody>" >> $tempWebSumFile
                echo "</table>" >> $tempWebSumFile
                echo "[/table]" >> $tempWebSumFile
}


######################################
# Nome: bplsathEnable                #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Verifica se todos os paths estão   #
# hablilitados e apresentado pelos 2 #
# VIOs                               #
######################################

        function bplspathEnable
        {

                # Verifica se os discos são entregues via VIO
                lspath | grep vscsi 1>/dev/null
                if [ $? = 0 ]
                then
                        # Verifica se há algum path que não esteja com a situacao de habilitado 
                        nrPathFail=$(lspath | grep -vi enable | wc -l) 
                        if [ 0 = $nrPathFail ] 
                        then 
                                # Caso algum hdisk não seja visualizado por 2 Paths ele irá retornar falho
                                nrPathdisk=$(lspath | awk '{print $1,$2}' | sort -n | uniq -u | wc -l) 
                                if [ 0 = $nrPathdisk ] 
                                then 
                                        return 0
                                else 
                                        return 1
                                fi 
                        else
                                return 1
                        fi
                else 
                        return 2
                fi 
        }

######################################
# Nome: bpbootlist                   #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Verifica se os discos presentes no #
# rootvg tambem estao presentes      #
# no bootlist                        #
######################################


        function bpbootlist 
        {
                # Verifica quais discos estao presentes no rootvg
                hdiskRootvg=$(lsvg -p rootvg | grep hdisk | awk '{print $1}' | uniq | sort)

                # Verifica quais discos estão no bootlist
                hdiskBootlist=$(bootlist -m normal -o | awk '{print $1}' | uniq | sort)    

                if [ "$hdiskRootvg" == "$hdiskBootlist" ]                                  
                then                                                                       
                        return 0                                   
                else
                        return 1
                fi
        }


######################################
# Nome: bpVscsiFastFail              #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Verifica se o parametro das        #
# interfaces vscsi  estao como       #
# fast_fail                          #
######################################

        function bpVscsiFastFail
        {
                # Verifica parametro vscsi_err_recov 
                lspath | grep vscsi 1> /dev/null
                if [ $? = 0 ]
                then
                        for i in `lspath | grep vscsi | awk '{print $3}' | sort | uniq`
                        do                                                             
                                vscsiFast=$(lsattr -El $i | grep vscsi_err_recov | awk '{print $2}')
                        done                                                                        
                                vscsiRes=$(echo $vscsiFast | grep delayed_fail | wc -l)              
                        if [ $vscsiRes = 0 ]                                                        
                        then                                                                        
                                return 0                                                            
                        else                                                                        
                                return 1
                        fi
                else
                        return 2
                fi
        }

######################################
# Nome: bpFscsiFastFail              #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Verifica se o parametro das        #
# interfaces ifscsi estao como       #
# fast_fail                          #
######################################

        function bpFscsiFastFail
        {
                $(lsdev | grep fscsi 1> /dev/null)
                if [ $? = 0 ]
                then
                        for i in `lsdev | grep fscsi | awk '{print $1}' | sort | uniq`
                        do
                                fscsiFast=$(lsattr -El $i | grep fc_err_recov | awk '{print $2}')
                        done
                        fscsiRes=$(echo $fscsiFast | grep delayed_fail | wc -l)
                        if [ $fscsiRes = 0 ]
                        then
                                return 0
                        else
                                return 1
                        fi
                else
                        return 2
                fi
        }

######################################
# Nome: bphdiskClose                 #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Verifica se ha algum disco CLOSE   #
######################################

function bphdiskClose
{
        if [ -e "/usr/bin/pcmpath" ]
        then
                hdiskClose=$(pcmpath query device | grep -p CLOSE | wc -l)
                if [ $hdiskClose -eq 0 ]
                then
                        return 0
                else
                        return 1
                fi
        else
                return 2
        fi
}

######################################
# Nome: bpAdapterFail                #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Verifica se ha Adapter com Falha   #
######################################

function bpAdapterFail
{
        if [ -e "/usr/bin/pcmpath" ]
        then
                adapterFail=$(pcmpath query adapter | grep fscsi | grep -vi NORMAL | wc -l)
                if [ $adapterFail = 0 ]
                then
                        return 0 
                else
                        return 1
                fi
        else
                return 2
        fi
}

######################################
# Nome: bpAutoMountFileSystem        #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Verifica se ha algum Fs nao        #
# configurado no boot                #
######################################

function bpAutoMountFileSystem
{
      lssrc -g cluster >/dev/null 2>&1
      if [ $? -ne 0 ]
      then
         result=$(cat /etc/filesystems | grep 'mount' | grep 'false' | wc -l)
         if [ $result = 0 ]
         then
            return 0
         else
            return 1
         fi
      fi
}

function bpAutoNegotiation
{
        for i in `ifconfig -a | grep ^en | awk '{print $1}' | sed 's/://'` 
        do 
                interface=$(netstat -v $i | grep -i auto_negotiation | wc -l)
        done
        if [ $interface = 0 ]
        then
                return 0
        else
                return 1
        fi
}

function bpPcmAdapterPath
{

        if [ -e "/usr/bin/pcmpath" ]
        then
                result=$(pcmpath query adapter | grep 'fsc' | awk '{if ($7 == $8) print "0" ; else print "1"}' |uniq)

                if [ $result -eq 0 ]
                then
                        return 0
                else
                        return 1
                fi
        else
                return 2
        fi
}

######################################
# Nome: bpSysdumpCheck               #
#                                    #
# Autor: lfvsilva@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Verifica a configuracao das areas  #
# de dump conforme IBM best-practice #
######################################

function bpSysdumpCheck
{
        # Set debug to 1 to get debug messages.
        debug=0

        # Check amount of disks in rootvg
        disksInRootvg=$(lsvg -p rootvg | egrep -v 'rootvg:|PV_NAME' | wc -l | awk '{print $1}')

        # Get configured dump areas
        primaryDumpArea=$(sysdumpdev -l | head -n1 | awk '{print $2}')
        secondaryDumpArea=$(sysdumpdev -l | head -n2 | tail -n1 | awk '{print $2}')

        # Extract their names
        primaryDumpAreaName=$(basename $primaryDumpArea)
        secondaryDumpAreaName=$(basename $secondaryDumpArea)

        # Is any of the areas null?
        primaryDumpAreaNull=0
        secondaryDumpAreaNull=0
        echo "$primaryDumpArea" | grep null 1>/dev/null || primaryDumpAreaNull=1
        echo "$secondaryDumpArea" | grep null 1>/dev/null || secondaryDumpAreaNull=2
        sumDumpArea=$(($primaryDumpAreaNull+$secondaryDumpAreaNull))

        # Get estimate dump size
        estimateDumpSizeBytes=$(sysdumpdev -e | awk '{print $NF}')

        # Convert estimate dump size to MB
        estimateDumpSizeMB=$((($estimateDumpSizeBytes/1024)/1024))

        # Ideal dump size
        # The ammount provided by sysdumpdev -e plus 50% of that
        fiftyPercentOfDumpSizeMB=$(($estimateDumpSizeMB/2))
        idealDumpSizeMB=$(($estimateDumpSizeMB+$fiftyPercentOfDumpSizeMB))

        # Procedure to get the size of the dump area
        procGetAreaSize(){
                thisLV=$(echo "$1" | awk -F'/' '{print $NF}')
                thisLVPPSize=$(lslv "$thisLV" | grep "PP SIZE:" | awk '{print $6}')
                thisLVPPs=$(lslv "$thisLV" | grep "PPs:" | head -n1 | awk '{print $NF}')
                echo $(($thisLVPPs*$thisLVPPSize))
        }

        # Procedure to compare the size of the areas against the ideal size
        procCompareSize(){
                if [ $1 -ge $idealDumpSizeMB ]
                        then
                        [ $debug = 1 ] && echo "larger than the ideal dump size."
                        export ok=1
                else
                        [ $debug = 1 ] && echo "smaller than the ideal dump size."
                        export ok=0
                fi
        }

        # Procedure to get the disk in which the LV is on
        getDiskFromLV(){
                lslv -m "$1" | grep hdisk | awk '{print $3}' | sort -u
        }

        # Check the status of the dump areas
        case $sumDumpArea in
                3)
                        [ $debug = 1 ] && echo "Both dump areas are set."
                        [ $debug = 1 ] && echo "The estimated size for a dump area on this system is $estimateDumpSizeMB MB."
                        [ $debug = 1 ] && echo "The ideal size for a dump area (estimated + 50%) on this system is $idealDumpSizeMB MB."
                                          # Get the area's sizes
                                          primaryAreaSize=$(procGetAreaSize $primaryDumpArea)
                                          secondaryAreaSize=$(procGetAreaSize $secondaryDumpArea)
                        [ $debug = 1 ] && echo "The primary dump area size is $primaryAreaSize"
                        [ $debug = 1 ] && echo "The secondary dump area size is $secondaryAreaSize"
                        [ $debug = 1 ] && printf "The primary dump area is ";
                                          # Compare the sizes
                                          procCompareSize $primaryAreaSize
                                          # Get the value of the ok var exported from the procedure and add it to dumpConfCheck
                                          dumpConfCheck=$ok
                        [ $debug = 1 ] && printf "The secondary dump are is ";
                                          # Compare the sizes
                                          procCompareSize $secondaryAreaSize
                                          # Get the value of the ok var exported from the procedure and add it to dumpConfCheck
                                          dumpConfCheck=$(($dumpConfCheck+$ok))

                        # If this rootvg has two disks, each dump area should be on a disk.
                        if [ $disksInRootvg -gt 1 ]
                                then
                                # Get the location (disks) of the LVs
                                primaryDumpAreaDisk=$(getDiskFromLV "$primaryDumpAreaName")
                                secondaryDumpAreaDisk=$(getDiskFromLV "$secondaryDumpAreaName")
                                [ $debug = 1 ] && echo "This system's rootvg has more than one disk."
                                [ $debug = 1 ] && echo "The primary dump area is located on disk $primaryDumpAreaDisk"
                                [ $debug = 1 ] && echo "The secondary dump area is located on disk $secondaryDumpAreaDisk"
                                # The disks should not be the same
                                if [ "$primaryDumpAreaDisk" != "$secondaryDumpAreaDisk" ]
                                        then
                                        [ $debug = 1 ] && echo "The dump areas are on separate disks."
                                        diskSeparationStatus=1
                                else
                                        [ $debug = 1 ] && echo "The dump areas are NOT on separate disks."
                                        diskSeparationStatus=0
                                fi
                        else
                                [ $debug = 1 ] && echo "This system's rootvg only has one disk, both dump areas are on the same disk."
                                diskSeparationStatus=1
                        fi
                        if [ $dumpConfCheck -eq 2 ] && [ $diskSeparationStatus -eq 1 ]
                                then
                                [ $debug = 1 ] && echo "This system dump configuration is ok."
                                return 0
                        else
                                [ $debug = 1 ] && echo "This system dump configuration is NOT ok."
                                return 1
                        fi
                ;;
                2)
                        [ $debug = 1 ] && echo "Only the secondary area is set."
                        [ $debug = 1 ] && echo "The estimated size for a dump area on this system is $estimateDumpSizeMB MB."
                        [ $debug = 1 ] && echo "The ideal size for a dump area (estimated + 50%) on this system is $idealDumpSizeMB MB."
                                          # Get the area's size
                                          secondaryAreaSize=$(procGetAreaSize $secondaryDumpArea)
                        [ $debug = 1 ] && echo "The secondary dump area size is $secondaryAreaSize"
                        [ $debug = 1 ] && printf "The secondary dump are is ";
                                          # Compare the size
                                          procCompareSize $secondaryAreaSize
                                          # Get the value of the ok var exported from the procedure and add it to dumpConfCheck
                                          dumpConfCheck=$ok
                        if [ $dumpConfCheck -ne 1 ]
                                then
                                [ $debug = 1 ] && echo "This system dump configuration is NOT ok."
                                return 1
                        else
                                [ $debug = 1 ] && echo "This system dump configuration is ok."
                                return 0
                        fi
                ;;
                1)
                        [ $debug = 1 ] && echo "Only the primary area is set."
                        [ $debug = 1 ] && echo "The estimated size for a dump area on this system is $estimateDumpSizeMB MB."
                        [ $debug = 1 ] && echo "The ideal size for a dump area (estimated + 50%) on this system is $idealDumpSizeMB MB."
                                                          # Get the area's size
                                                          primaryAreaSize=$(procGetAreaSize $primaryDumpArea)
                        [ $debug = 1 ] && echo "The primary dump area size is $primaryAreaSize MB"
                        [ $debug = 1 ] && printf "The primary dump area is ";
                                          # Compare the size
                                          procCompareSize $primaryAreaSize
                                          # Get the value of the ok var exported from the procedure and add it to dumpConfCheck
                                          dumpConfCheck=$ok
                        if [ $dumpConfCheck -ne 1 ]
                                then
                                [ $debug = 1 ] && echo "This system dump configuration is NOT ok."
                                return 1
                        else
                                [ $debug = 1 ] && echo "This system dump configuration is ok."
                                return 0
                        fi
                ;;
                0)
                        [ $debug = 1 ] && echo "No dump area is set."
                        return 1
                ;;
        esac
}

######################################
# Nome: bpnmon                       #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Verifica se o processo NMON esta   #
# ativo.                             #
######################################


function bpNmon
{
      result=$(ps -elf | grep -v 'grep' | grep 'nmon')
      if [ $? = 0 ]
      then
        return 0
      else
        return 1
      fi
}

######################################
# Nome: bpTftp                       #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Verifica se o tftp esta comentado  #
######################################

function bpTftp
{
        result=$(cat /etc/services | grep "# Trivial File" | grep -v "^#")
        if [ $? = 0 ]
        then
                return 0
        else
                return 1
        fi
}


######################################
# Nome: bpCmdElements                #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Ele verifica se o parametro        #
# cmd_elements esta configurado de   #
# acordo com a velocidade da HBA     #
######################################


function bpCmdElements
{
        hbaExists=$(lsdev | grep fcs)
        if [ $? -eq 0 ]
        then
                for i in $(lsdev | grep fcs | cut -d" " -f1)
                do
                        FcSpeed=$(fcstat -e $i | grep "(running)" | cut -d" " -f6)
                        FcCmdElements=$(lsattr -El $i | grep num_cmd_elems | cut -d" " -f2)
                        case $FcSpeed in
                        1) 
                                if [ $FcCmdElements -ne 1024 ]
                                then
                                        return 1
                                fi
                        ;;
                        2)
                                if [ $FcCmdElements -ne 2048 ]
                                then
                                        return 1
                                fi
                        ;;
                        4)
                                if [ $FcCmdElements -ne 2048 ]
                                then
                                        return 1
                                fi
                        ;;
                        8)
                                if [ $FcCmdElements -ne 2048 ]
                                then
                                        return 1
                                fi
                        ;;
                        *)
                                return 1
                        ;;
                        esac
                done
                        return 0
        else
                return 2
        fi

# Caso durante o laco execute ate o final a funcao ira retornar 0

}

######################################
# Nome: bpEcludeRootvg               #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Verifica se o arquivo exclude      #
# há filesystems de proprio SO       #
######################################

function bpExcludeRootvg
{

if [ -e "/etc/exclude.rootvg" ]
then
        for i in var usr opt etc sbin bin proc lib dev home 
        do
                result=$(cat "/etc/exclude.rootvg" | egrep "\^./$i/$")
                if [ ! $result = 0 ]
                then
                        return 1
                fi
        done
        return 0
else
        return 2
fi

}

######################################
# Nome: bpRootMirrorVg               #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Funcao que verifica se todos os lv #
# são mirrorados                     #
######################################

function bpRootMirrorVg
{
        result=$(lsvg rootvg | grep "TOTAL PVs" | awk '{ print $3}')
        if [ $result = 2 ]
        then
                for i in `lsvg -l rootvg | grep jfs | grep -v -e :$ -e ^"LV NAME"|awk '{print $1}' | grep -v "dump"`
                do 
                        if [ `lslv -m $i|tail -1|wc -w` -eq 3 ]
                        then
                                return 1
                        else
                                return 0
                        fi
                done
        else
                return 2
        fi
}

######################################
# Nome: bpService                    #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Esta funcao serve para verificar   #
# Se determinados servicos que nao   #
# deveriam estar online, estao       #
######################################


function bpService
{
        result=$(lssrc -s inetd | tail -1 | grep inoperative)
        if [ $? = 0 ]
        then
                return 0
        else
                return 1
        fi
}

######################################
# Nome: bpSyslog                     #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Verifica se todos os logs gerados  #
# pelo syslog estao sendo rotacio    #
# nados                              #
######################################

function bpSyslog
{
        result=$(cat /etc/syslog.conf | grep -v "^#" | grep -v "^$" | grep -v rotate | grep -v "@*" | wc -l)
        if [ $result = 0 ]
        then
                return 0
        else
                return 1
        fi

}
######################################
#Nome: bpInstFix                     #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição:                         #
#                                    #
# Verifica se a TL esta instalada    #
# corretamente                       #
######################################

function bpInstFix
{
        if [ -e /usr/ios/cli/ioscli ]
        then
                return 2
        else
                result=$(instfix -i | grep ML | grep Not | wc -l)
                if [ $result -gt 0 ]
                then
                        return 1
                else
                        return 0
                fi
        fi
}

######################################
# Nome: bpMultipath                  #
#                                    #
# Autor: lfvsilva@br.ibm.com         #
#                                    #
# Descrição:                         #
#                                    #
# Verifica se a todos os discos      #
# externos via pcmpath estao com a   #
# mesma quantidade de caminhos e se  #
# estes caminhos estao abertos.      #
######################################

function bpMultipath
{
        # Antes de mais nada, checar se pcmpath existe na maquina
        [ -f /usr/sbin/pcmpath ] || return 0

        # Variaveis estaticas
        statusCheck=0
        deviceIndex=0

        # Informacoes de pcmpath
        numberPaths=$(pcmpath query port | grep ^Active | cut -d: -f2)
        numberPCMDisks=$(lsdev -C | grep MPIO | wc -l | awk '{print $1}')

        # Qtdd de discos menos um para fins de comparacao com indice
        pcmDisks=$(($numberPCMDisks-1))

        # Inicio do check
        while [ $deviceIndex -le $pcmDisks ]
        do
                # Obter quantos caminhos OPEN este device possui
                thisDeviceOpen=$(pcmpath query device $deviceIndex | grep -cH OPEN)

                # Obter quantos caminhos este device possui
                thisDevicePaths=$(pcmpath query device $deviceIndex | grep fscsi | wc -l | awk '{print $1}')

                # Se a qtdd de OPEN for menor do que a qtdd de caminhos diponiveis, incrementa status
                [ $thisDeviceOpen -eq $numberPaths ] || statusCheck=$(($statusCheck+1))

                # Se a qtdd de caminhos for menos do que a qtdd de caminhos que ele deveria ter, incrementa status
                [ $thisDevicePaths -eq $numberPaths ] || statusCheck=$(($statusCheck+1))

                # Incrementa o indice pra seguir o loop
                deviceIndex=$(($deviceIndex+1))
        done

        # Agora se o status for maior que zero esse best practice nao esta atendido
        if [ $statusCheck -gt 0 ]
        then
                return 1
        else
                return 0
        fi
}

######################################
# Nome: bpRemoteConsole              #
#                                    #
# Autor: lfvsilva@br.ibm.com         #
#                                    #
# Descrição:                         #
#                                    #
# Verifica se este servidor tem HMC  #
######################################

function bpRemoteConsole
{
        # Obter IP da HMC
        HMC="$(lsrsrc IBM.MCP | egrep "KeyToken|HMCIPAddr" | awk '{ print $3}')"

        # Avaliar se vazio
        if [ -z "$HMC" ]
        then
                return 1
        else
                return 0
        fi
}

######################################
# Nome: bpNetworkRedundancy          #
#                                    #
# Autor: lfvsilva@br.ibm.com         #
#                                    #
# Descrição:                         #
#                                    #
# Verifica se as interfaces de rede  #
# deste servidor possuem algum tipo  #
# de redundancia. Sera presumido que #
# interfaces virtuais (VIO) que NAO  #
# fizerem parte de um etherchannel   #
# estao redundantes por sea failover #
# Caso nao esteja sera pego pelo BP  #
# no VIO que serve este servidor.    #
######################################

function bpNetworkRedundancy
{
        # Variaveis estaticas
        statusCheck=0

        # Pegar as interfaces de rede com IP (en)
        ifconfig -a | grep ^en | cut -d: -f1 | while read thisEn
        do
                # Transformar en em ent
                thisEnt=$(echo "$thisEn" | sed 's/en/ent/g')

                # Verificar se esse ent eh um etherchannel
                checkEtherchannel=$(lsdev -Cl $thisEnt | grep EtherChannel)

                # Se nao for EtherChannel, verificar se eh interface de VIO
                if [ -z "$checkEtherchannel" ]
                then
                        # Verificar se a interface eh VIO
                        checkInterfaceVIO=$(lsdev -Cl $thisEnt | grep Virtual)

                        # Se nao for VIO nem EtherChannel incrementa o status
                        [ -z "$checkInterfaceVIO" ] && statusCheck=$(($statusCheck+1))
                fi
        done

        # Agora se o status for maior que zero esse best practice nao esta atendido
        if [ $statusCheck -gt 0 ]
        then
                return 1
        else
                return 0
        fi
}

######################################
# Nome: bpPowerSupplyRedundancy      #
#                                    #
# Autor: lfvsilva@br.ibm.com         #
#                                    #
# Descrição:                         #
#                                    #
# Verifica se este servidor possui   #
# fontes redundantes.                #
######################################

function bpPowerSupplyRedundancy
{
        # Variaveis estaticas
        statusCheck=0

        # Em Ps pequena temos IBM AC PS (Power Supply)
        checkACPS=$(lscfg -vp | grep "AC PS" | wc -l)

        # Se o valor obtido for vazio, verificar se nao estamos numa P grande
        if [ -z "$checkACPS" ]
                then
                # Em Ps grandes temos BPA (Bulk Power Assembly)
                checkBulk=$(lscfg -vp | grep "BULK" | wc -l)
                # Se o valor obtido nao for maior que 1, incrementa status
                [ $checkBulk -le 1 ] && statusCheck=$(($statusCheck+1))
        else
                # Se o valor obtido nao for vazio e o valor for menor que 1, incrementa status
                [ $checkACPS -le 1 ] && statusCheck=$(($statusCheck+1))
        fi

        # Agora se o status for maior que zero esse best practice nao esta atendido
        if [ $statusCheck -gt 0 ]
        then
                return 1
        else
                return 0
        fi
}

######################################
# Nome: bpImageValidation            #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição:                         #
#                                    #
# Verifica pelo log do script de     #
# image se o mksysb executa correta  #
# mente e se o envio para o TSM foi  #
# OK                                 #
######################################


function bpImageValidation
{
        ChkMksysbLog=$(ls -tr $dirImage | tail -n 1)
        if [ -f "$dirImage/$ChkMksysbLog" ]
        then
                ChkMksysb=$(cat "$dirImage/$ChkMksysbLog" | grep "Backup Image OK")
                ChkTsm=$(cat "$dirImage/$ChkMksysbLog" | grep "The operation successfully complete.")
                if [ "$ChkMksysb" == "Backup Image OK! (100%)" ]
                then
                        if [ "$ChkTsm" == "The operation successfully complete." ]
                        then
                                return 0
                        else
                                return 1
                        fi
                else
                        return 1
                fi
        else
                return 1
        fi
}

######################################
# Nome: bpClusterCheck               #
#                                    #
# Autor: lfvsilva@br.ibm.com         #
#                                    #
# Descrição:                         #
#                                    #
# Verifica se este servidor possui   #
# cluster. Hacmp e Oracle RAC        #
######################################
function bpClusterCheck
{
        # Variaveis estaticas
        statusCheck=0

        # Caso for debugar, trocar pra 1
        debug=0

        # Check HACMP
        lssrc -g cluster >/dev/null 2>&1
        clusterGroupCheck=$?

        # Se o grupo de servicos cluster existe
        # essa maquina possui hacmp
        if [ $clusterGroupCheck -eq 0 ]
        then
                [ $debug -eq 1 ] && echo "Este servidor possui hacmp instalado"
                # Verificar o status dos servicos
                numActive=0
                lssrc -g cluster | while read thisLine
                do
                        testActive="$(echo "$thisLine" | grep active)"
                        [ -n "$testActive" ] && export numActive=$(($numActive+1))
                done
                # Caso nao hajam dois servicos ativos, ja nao ta legal
                if [ $numActive -lt 2 ]
                then
                        [ $debug -eq 1 ] && echo "Nem todos do grupo cluster estao ativos"
                        statusCheck=$(($statusCheck+1))
                else
                        [ $debug -eq 1 ] && echo "Todos no grupo cluster estao ativos"
                        # Se clstrmgrES esta Stable, dai nao ta legal mesmo
                        testStable=$(lssrc -ls clstrmgrES | head -n1 | awk '{print $NF}')
                        if [ "$testStable" = "ST_STABLE" ]
                        then
                                [ $debug -eq 1 ] && echo "clstrmgrES esta Stable"
                        else
                                [ $debug -eq 1 ] && echo "clstrmgrES NAO esta Stable"
                                statusCheck=$(($statusCheck+1))
                        fi
                fi
        else
                [ $debug -eq 1 ] && echo "Este servidor NAO possui hacmp instalado"
                # Se o grupo cluster nao existe
                # verificar se temos Oracle RAC
                if [ -d /etc/oracle/scls_scr ]
                then
                        [ $debug -eq 1 ] && echo "Este servidor possui Oracle rac instalado"
                        # Verificar se o Oracle RAC esta rodando
                        testRunningRAC=$(ps -ef | grep crsd.bin | grep -v grep | wc -l | awk '{print $1}')
                        if [ $testRunningRAC -lt 0 ]
                        then
                                [ $debug -eq 1 ] && echo "Oracle RAC NAO esta rodando"
                                statusCheck=$(($statusCheck+1))
                        else
                                [ $debug -eq 1 ] && echo "Oracle RAC esta rodando"
                        fi
                else
                        [ $debug -eq 1 ] && echo "Este servidor NAO possui Oracle rac instalado"
                        statusCheck=$(($statusCheck+1))
                fi
        fi

        # Agora se o status for maior que zero esse best practice nao esta atendido
        if [ $statusCheck -gt 0 ]
        then
                return 1
        else
                return 0
        fi

}

######################################
# Nome: bpdacmt                      #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# funcao dummy so pra contar como    #
# funcao                             #
######################################


function bpdacmt 
{

        var=dummy

}


######################################
# Nome: BestPractice                 #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Esta funcao reune os todas as      # 
# funcoes de Bestpractice            #
# checklist acima da quantidade      #
# configurada na variavel $rotate    #
######################################


function BestPractice
{
        testDirs
        # Executa as funcoes
        cat /dev/null > $bestPracticeFile
        echo "[INFO] Executando as funcoes de Best Practice"
        for i in bplspathEnable bpbootlist bpVscsiFastFail bpFscsiFastFail bphdiskClose bpAdapterFail bpAutoMountFileSystem bpAutoNegotiation bpPcmAdapterPath bpSysdumpCheck bpNmon bpTftp bpExcludeRootvg bpRootMirrorVg bpService bpSyslog bpInstFix bpMultipath bpRemoteConsole bpNetworkRedundancy bpPowerSupplyRedundancy bpClusterCheck bpCmdElements bpImageValidation 
        do
                $($i)
                print -n "$?;" >> $bestPracticeFile
        done
        chown scunix:staff $bestPracticeFile
}

######################################
# Nome: checklistDo                  #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Esta funcao coleta as informações  #
# do Sistema opercional e armazena   #
# em cada arquivo                    #
######################################

function checklistDo
{
        checkUID
        testDirs
        suporteFiles
        printTop
        sumarioHardware
        printGauge
        echo > $tempWebCheckFile

# suporte #
        cmd=suporte
        chkTittle="Descricao dos servidores"
        count=1
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        cat $dirSup/suporte.txt | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        cat $dirSup/preboot.txt | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        cat $dirSup/posboot.txt | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb


# lssrc #
        cmd=lssrc
        chkTittle="Servicos Ativos"
        count=1
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle 
        lssrc -a | grep active | awk '{ print $1}' | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Hosts #
        cmd=etc-hosts
        chkTittle="Hosts"
        count=1
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        cat /etc/hosts | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Variaveis #
        cmd=env
        chkTittle="Variaveis de Ambientes"
        count=2
        printHdr
        printTittle 
        env >> $dirLog/$cmd.$formatFile
        printBtm

# Resolv.conf #
        cmd=etc-resolv
        chkTittle="Configuracoes de DNS"
        count=3
        printHdr
        printTittle
        if [ -f /etc/resolv.conf ]
        then
        cat /etc/resolv.conf >> $dirLog/$cmd.$formatFile
        fi
        printBtm

# Devices  #
        cmd=lsdev
        chkTittle="Lista de Dispositivos"
        count=4
        printHdr
        printTittle
        lsdev >> $dirLog/$cmd.$formatFile
        printBtm

# Variaveis #
        cmd=etc-user
        chkTittle="Configuracoes de Limits"
        count=5
        printHdr
        printTittle
        cat /etc/security/user >> $dirLog/$cmd.$formatFile
        printBtm

# lspath #
        cmd=lspath
        chkTittle="Configuracoes de Paths"
        count=6
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        lspath | awk '{print $1,$2}' | sort -n | uniq -u >> $dirLog/$cmd.$formatFile
        printBtm
        printBtmWeb

# Inittab #
        cmd=inittab
        chkTittle="Configuracoes do Inittab"
        count=7
        printHdr
        printTittle
        lsitab -a >> $dirLog/$cmd.$formatFile
        printBtm

# NTP #
        cmd=ntp
        chkTittle="Configuracoes do NTP"
        count=8
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        cat /etc/ntp.conf |grep server |grep -v ^# >> $dirLog/$cmd.$formatFile
        printBtm
        printBtmWeb

# LPAR #

        cmd=lparstat
        chkTittle="Configuracao da LPAR"
        count=9
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        lparstat -i | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb


# Netstat #

        cmd=netstat
        chkTittle="Informacao de netstat"
        count=10
        printHdr
        printTittle
        netstat -an >> $dirLog/$cmd.$formatFile
        printBtm


# lscfg #

        cmd=lscfg
        chkTittle="Lista de Informacao do VTD"
        count=11
        printHdr
        printTittle
        lscfg -v >> $dirLog/$cmd.$formatFile
        printBtm

# Cluster #

rc=`lssrc -g cluster`
if [ $? -eq 0 ]
then
        cmd=cluster
        chkTittle="Status Atual do Cluster"
        count=12
        printHdr
        printTittle
        lssrc -l -s clstrmgrES | grep "Current state" >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllscf
        chkTittle="Verificando o cluster cllscf"
        count=13
        printHdr
        printTittle
        cllscf >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cltopinfo
        chkTittle="Verificando o cluster cltopinfo"
        count=14
        printHdr
        printTittle
        cltopinfo >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsserv
        chkTittle="Verificando o cluster cllsserv"
        count=15
        printHdr
        printTittle
        cllsserv >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsnode
        chkTittle="Verificando o cluster cllsnode"
        count=15
        printHdr
        printTittle
        cllsnode >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=clshowres
        chkTittle="Verificando o cluster clshowres"
        count=16
        printHdr
        printTittle
        clshowres >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsif
        chkTittle="Verificando o cluster cllsif"
        count=17
        printHdr
        printTittle
        cllsif >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsclstr
        chkTittle="Verificando o cluster cllsclstr"
        count=18
        printHdr
        printTittle
        cllsclstr >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsvgdata
        chkTittle="Verificando o cluster cllsvgdata"
        count=19
        printHdr
        printTittle
        cllsvgdata >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllssvcs
        chkTittle="Verificando o cluster cllssvcs"
        count=19
        printHdr
        printTittle
        cllssvcs >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsstbys
        chkTittle="Verificando o cluster cllsstbys"
        count=20
        printHdr
        printTittle
        cllsstbys >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsclstr
        chkTittle="Verificando o cluster cllsclstr"
        count=21
        printHdr
        printTittle
        cllsclstr >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsserv
        chkTittle="Verificando o cluster cllsserv"
        count=22
        printHdr
        printTittle
        cllsserv >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllssite
        chkTittle="Verificando o cluster cllssite"
        count=23
        printHdr
        printTittle
        cllssite >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsfs
        chkTittle="Verificando o cluster cllsfs"
        count=24
        printHdr
        printTittle
        cllsfs >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllsres
        chkTittle="Verificando o cluster cllsres"
        count=25
        printHdr
        printTittle
        cllsres >> $dirLog/$cmd.$formatFile
        printBtm

        cmd=cllslv
        chkTittle="Verificando o cluster cllslv"
        count=26
        printHdr
        printTittle
        cllslv >> $dirLog/$cmd.$formatFile
        printBtm
fi

# Uname #

        cmd=uname
        chkTittle="Informacao de Uname"
        count=27
        printHdr
        printTittle
        uname -a >> $dirLog/$cmd.$formatFile
        printBtm

# Bootlist #

        cmd=bootlist
        chkTittle="Informacao de Uname"
        count=28
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        bootlist -m normal -o | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# lslpp #

        cmd=lslpp
        chkTittle="Pacotes lslpp"
        count=30
        printHdrWeb "$cmd" "$chkTittle"
        printHdr
        printTittle
        lslpp -lc >> $dirLog/$cmd.$formatFile
        printBtm
        printBtmWeb


# Release do Sistema Operacional #

        cmd=oslevel
        chkTittle="Versao do sistema Operacional"
        count=31
        printHdr
        printTittle
        oslevel -s >> $dirLog/$cmd.$formatFile
        printBtm

# FileSystens montados #

        cmd=dfg
        chkTittle="Filesystems ativos"
        count=32
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        df -g | sort | grep -v "$(df -g|head -1)" | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Tabela de Rotas #

        cmd=route
        chkTittle="Tabelas de rotas"
        count=33
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        netstat -nr | egrep "^[0-9]|default" | awk '{print $1";"$2";"$6}' | sort -n | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

########################
# Configuracao de Rede #
########################

        cmd=ifconfig
        chkTittle="Interfaces de rede"
        count=34
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        ifconfig -a | grep -v tcp_sendspace | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Configuracao de Impressoras #

        cmd=etc-qconfig
        chkTittle="Arquivo de configuracoes de impressora"
        count=35
        printHdr
        printTittle
        cat /etc/qconfig >> $dirLog/$cmd.$formatFile
        printBtm

# Parametros de memoria #

        cmd=vmo
        chkTittle="Parametros de Tuning de memoria"
        count=36
        printHdr
        printTittle
        vmo -a >> $dirLog/$cmd.$formatFile
        printBtm

# Parametros de Rede #

        cmd=no
        chkTittle="Parametros de Tuning de Rede"
        count=37
        printHdr
        printTittle               
        no -a >> $dirLog/$cmd.$formatFile
        printBtm

# Parametros de I/O #

        cmd=ioo
        chkTittle="Parametros de I/O"
        count=38
        printHdr
        printTittle
        ioo -a >> $dirLog/$cmd.$formatFile
        printBtm

# Parametros de NFS #

        cmd=nfso
        chkTittle="Parametros de NFS"
        count=39
        printHdr
        printTittle
        nfso -a >> $dirLog/$cmd.$formatFile
        printBtm

# Parametros de Schedule #

        cmd=schedo
        chkTittle="Parametros de Schedule"
        count=40
        printHdr
        printTittle
        schedo -a 2> /dev/null >> $dirLog/$cmd.$formatFile
        printBtm

# RPM #

        cmd=rpm
        chkTittle="Pacotes RPM"
        count=41
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        rpm -qa --queryformat='%{NAME}-%{VERSION}.%{ARCH}.rpm \n' | sort >> $dirLog/$cmd.$formatFile
        printBtm
        printBtmWeb

# Tabela de discos #

        cmd=lspv
        chkTittle="Tabela de discos"
        count=42
        printHdr
        printTittle
        lspv 2>/dev/null >> $dirLog/$cmd.$formatFile
        printBtm

# Lista os VGs #

        cmd=lsvg
        chkTittle="Lista de VGs"
        count=43
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        lsvg 2>/dev/null | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Lista os VGs Ativos #

        cmd=lsvg-o
        chkTittle="Lista de VGs Ativos"
        count=44
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        lsvg -o 2>/dev/null | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Lista os LVs por VG #

        cmd=lsvg-l
        chkTittle="Lista de LVs por VG"
        count=45
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        for i in `lsvg -o | sort` ; do lsvg -l $i ; done | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Lista os PVs por VG #

        cmd=lsvg-p
        chkTittle="Lista de LVs por VG"
        count=46
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        for i in `lsvg -o | sort`
        do 
                lsvg -p $i
        done | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Lista as Propriedades de cada VG #

        cmd=lsvg-vg
        chkTittle="Lista de LVs por VG"
        count=47
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        for i in `lsvg -o | sort` 
        do
                lsvg $i
        done | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Rede #

        cmd=netstat-v
        chkTittle="Situacao de Link"
        count=48
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        for i in `lsdev -Cc if -t en | cut -d' ' -f1`
        do 
                echo $i
                netstat -v $i 2> /dev/null | grep Link
                netstat -v $i 2> /dev/null | grep "Device Type"
        done | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Lspath #

        cmd=lspath
        chkTittle="Lspath"
        count=49
        printHdr
        printTittle
        lspath -H >> $dirLog/$cmd.$formatFile
        printBtm

# Last #

        cmd=last
        chkTittle="Last"
        count=50
        printHdr
        printTittle
        last >> $dirLog/$cmd.$formatFile
        printBtm

# Crontab #

        cmd=crontab
        chkTittle="Crontab"
        count=51
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle

        for i in `ls /var/spool/cron/crontabs`
        do
                echo   "\n Crontab do Usuario $i \n\n"                  
                cat /var/spool/cron/crontabs/$i                         
        done | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile

        echo   "" >> $dirLog/$cmd.$formatFile

        for i in `ls /var/spool/cron/atjobs`
        do
                echo   "\n Crontab do Usuario $i \n\n"                  
                cat /var/spool/cron/atjobs/$i                           
        done | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# NFS #

        cmd=exports
        chkTittle="NFS - Server"
        count=52
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle                             
        if [ -f /etc/exports ]
        then
            cat /etc/exports | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        fi
        printBtm
        printBtmWeb

# PCMPATH #

        cmd=pcmpath
        chkTittle="PCMPATH"
        count=52
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle                            
        rc=`pcmpath 2> /dev/null`
        if [ $? -eq 0 ] 
        then
            pcmpath query essmap >> $dirLog/$cmd.$formatFile
            echo   "\n" >> $dirLog/$cmd.$formatFile
            pcmpath query device | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
            echo   "\n" >> $dirLog/$cmd.$formatFile
            pcmpath query adapter | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        fi
        printBtm
        printBtmWeb
           
# Errpt #

        cmd=errpt
        chkTittle="Errpt"
        count=53
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        errpt >> $dirLog/$cmd.$formatFile
        printBtm
        printBtmWeb

# GPFS  #

        rc=`lslpp -l | grep gpfs`
        if [ $? -eq 0 ]
        then
                cmd=mmlspv
                chkTittle="GPFS - mmlspv"
                count=54
                printHdr
                printTittle
                mmlspv >> $dirLog/$cmd.$formatFile
                printBtm

                cmd=mmlsconfig
                chkTittle="GPFS - mmlsconfig"
                count=53
                printHdr
                printTittle
                mmlsconfig >> $dirLog/$cmd.$formatFile
                printBtm

                cmd=mmlsmgr
                chkTittle="GPFS - mmlsmgr"
                count=54
                printHdr
                printTittle
                mmlsmgr >> $dirLog/$cmd.$formatFile
                printBtm

                cmd=mmlsnode
                chkTittle="GPFS - mmlsnode"
                count=55
                printHdr
                printTittle
                mmlsnode >> $dirLog/$cmd.$formatFile
                printBtm

                cmd=mmlsnsd
                chkTittle="GPFS - mmlsnsd"
                count=56
                printHdr
                printTittle
                mmlsnsd >> $dirLog/$cmd.$formatFile
                printBtm
        fi

# Conslog #

        cmd=conslog
        chkTittle="Conslog"
        count=57
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        if [ -f /var/adm/ras/conslog ]
        then
                cat /var/adm/ras/conslog >> $dirLog/$cmd.$formatFile
        fi
        printBtm
        printBtmWeb

# Sysdump #

        cmd=sysdump
        chkTittle="Sysdump"
        count=58
        printHdr
        printTittle
        sysdumpdev -l  >> $dirLog/$cmd.$formatFile
        printBtm

# lsfs #

        cmd=lsfs
        chkTittle="lsfs"
        count=59
        printHdr
        printHdrWeb "$cmd" "$chkTittle"
        printTittle
        lsfs | tee -a $dirLog/$cmd.$formatFile >> $tempWebCheckFile
        printBtm
        printBtmWeb

# Processos #

        cmd=processos
        chkTittle="Processos"
        count=60
        printHdr
        printTittle
        ps -elf >> $dirLog/$cmd.$formatFile
        printBtm

# Environment #

        cmd=environment
        chkTittle="Etc-Environment"
        count=61
        printHdr
        printTittle
        cat /etc/environment | grep -v ^# >> $dirLog/$cmd.$formatFile
        printBtm

# VIO #

        rc=`/usr/ios/cli/ioscli 2> /dev/null`
        if [ $? -eq 0 ]
        then
                chkTittle="SEA"
                cmd=sea
                count=61
                printHdr
                printTittle
                for i in `lsdev | grep ent | grep -i pci | awk '{print $1}' `; do lscfg -vl $i | grep ent ; done >> $dirLog/$cmd.$formatFile ; for i in `lsdev | grep -i Shared | cut -d" " -f1`; do echo "\nSEA: $i" >> $dirLog/$cmd.$formatFile ; echo "====VLANs====" >> $dirLog/$cmd.$formatFile ; netstat -v $i | grep -i "VLAN" >> $dirLog/$cmd.$formatFile ; echo "====Iface Fisica====" ; netstat -v $i | egrep  'State: [PB]|Media Speed|VLAN ID:|ETHERNET STATISTICS|Hardware Address|Link Status|Priority' ;  done 2> /dev/null >> $dirLog/$cmd.$formatFile
                 printBtm

# VIO - Lsmap #

                chkTittle="lsmap-disk"
                cmd=lsmap-disk
                count=62
                printHdr
                printHdrWeb "$cmd" "$chkTittle"
                printTittle
                /usr/ios/cli/ioscli lsmap -all | egrep -p "VTD|Backing"  >> $dirLog/$cmd.$formatFile
                printBtm
                printBtmWeb

                chkTittle="lsmap-npiv"
                cmd=lsmap-npiv
                count=62
                printHdr
                printTittle
                /usr/ios/cli/ioscli lsmap -all -npiv >> $dirLog/$cmd.$formatFile
                printBtm
        fi

        echo "Checklist executado com sucesso!"
        # Executa a rotação do checklist a cada execução
        cat $tempWebSumFile > $finalWebFile
        cat $tempWebCheckFile >> $finalWebFile
        chown scunix:soadmin $finalWebFile
        BestPractice
        checklistRotate
}

        ##########################################
        ### Descricao dos resultados das funcoes #

        # Cada função deve ser devidamente comentada e deve 
        # apresentar apenas 3 possiveis saidas:
        # 0 - Em caso de não encontrar problemas
        # 1 - Em caso de encontrar problemas
        # 2 - Em caso da funcao não se aplicar ao sistema

        ############################################################

        # TODO

        # Valida se os discos do rootvg sao locais e se estão mirrorados
        # Valida se o tamanho do sysdumpdev esta de acordo
        # Sugere o tamanho do Swap
        # Verifica as configuracoes de vscsi
        # Verifica os parametros de fast_fail
        # Verificar se ja fibras em DEGRADED (pcmpath e datapath)

        #
        ##################################

######################################
# Nome: checklistCompara             #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Esta função compara mudanças entre #
# 2 arquivos do mesmo item           #
######################################

function checklistCompare
{
        echo "Escolha a data do Primeiro checklist"
        select i in `ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq `
        do
                if [ -z "$i" ]
                then
                        echo "Opcao invalida selecione uma opcao valida"
                        exit 1
                else
                        echo "Primeiro checklist escolhido: $i"
                        break
                fi

        done
        echo "Escolha a data do Segundo checklist"
        select j in `ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq `
        do
                if [ -z "$i" ]
                then
                        echo "Opcao invalida selecione uma opcao valida"
                        exit 1
                else
                        echo "Segundo checklist escolhido: $i"
                        break
                fi
        break
        done
        if [ "$i" = "$j" ]
        then
                echo "As duas datas sao iguais ou nao ha numero suficiente de checklists"
                exit 1
        fi

        for chkFile in lssrc etc-hosts env etc-resolv lsdev inittab ntp lparstat netstat uname lslpp oslevel dfg route ifconfig etc-qconfig vmo no ioo nfso schedo lspv lsvg lsvg-o lsvg-l lsvg-p netstat-v last crontab exports errpt lsfs bootlist sysdump lspath rpm mmlspv mmlscluster mmlsconfig mmlsmgr mmlsnode mmlsnsd cluster environment
        do
                chkItem1=$chkFile.$i.$(hostname).checklist
                chkItem2=$chkFile.$j.$(hostname).checklist
                echo "------------------------------------------------------------------"
                echo "Comparando $chkItem1 -> $chkItem2"
                echo "------------------------------------------------------------------"
                echo ""
                if [ -f "$dirLog/$chkItem1" ] && [ -f "$dirLog/$chkItem2" ]
                then
                    diff $dirLog/$chkItem1 $dirLog/$chkItem2 | grep -E '^<|^>'
                    if [ $? -eq 0 ]
                    then
                        echo   "Checklist - NOK"
                        echo   ""
                    else
                        echo   "Checkklist - OK"
                        echo   ""
                    fi
                else
                    echo   "Arquivo de checklist nao gerado"
                    echo   ""
                fi
        done
}

######################################
# Nome: checklistBackup              #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# A partir de um arquivo txt com o   #
# caminho completo é criado um       #
# archive para ser utilizado como    #
# backup                             #
######################################

function checklistBackup
{
        cmd="backup"
                if [ -f "$backupFile" ]
                then
                        tar -cvL $backupFile -f $cmd.$formatFile.tar
                else
                        echo "O arquivo $backupFile nao foi encontrado ou sem permissao"
                fi
}

######################################
# Nome: checklistView                #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Esta função exibe todos os itens   #  
# do checklist apartir de uma        # 
# determina da data                  #
######################################

function checklistView
{
        echo "Escolha a data do checklist a ser visualizado"
        select i in `ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq `
        do
                echo "$i e $? "
                if [ -n "$i" ]
                then
                        echo "Opcao invalida selecione uma opcao valida"
                        exit 1
                else
                        echo "Checklist escolhido: $i"
                        cat $dirLog/*$i* | more
                        exit 0
                fi
        done
}

######################################
# Nome: checklistView                #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Esta função exibe todos os itens   #  
# do checklist apartir de uma        # 
# determina da data                  #
######################################

function checklistRemove
{
        select i in `ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq `
        do
                if [ -z "$i" ]
                then
                        echo "Opcao invalida ou checklist nao encontrado selecione uma opcao valida" 1>&2
                        exit 1
                else
                        echo "Checklist escolhido: $i"
                        rm -rf $dirLog/*$i*.checklist
                        #exit 0
                fi
        done
}

######################################
# Nome:  checklistZip                #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Esta função exibe todos os itens   #  
# do checklist apartir de uma        # 
# determina da data                  #
######################################

function checklistZip
{                    
        cmd="ZIP"    
        select i in `ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq `
        do                                                  
                if [ -z "$i" ]                              
                then                                        
                        echo "Opcao invalida ou checklist nao encontrado selecione uma opcao valida" 1>&2
                        exit 1                                                                           
                else                                                                                     
                        echo "Checklist escolhido: $i"                                                   
                        tar -cf $dirZip/$cmd.$i-$(hostname).tar $dirLog/*$i*                             
                        #exit 0                                                                          
                fi                                                                                       
        done                                                                                             
} 

######################################
# Nome: checklistRotate              #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descricao                          #
#                                    #
# Funcao com objetivo de compactar   #
# checklist acima da quantidade      #
# configurada na variavel $rotate    #
######################################

function checklistRotate
{
    checkUID
    testDirs
    maxRotate=$(($maxRotate + 1))
    qtdCheck=`ls -t $dirLog/*.checklist | cut -d"." -f 2 | uniq | wc -l`
            if [ $qtdCheck -lt $maxRotate ]
            then
                    echo  "[INFO] Nao ha checklists para rotacionar"
                    exit 1
            else
                    while [ $qtdCheck -gt $maxRotate ]
                    do
                            checklistRotate="CHECKLIST: `ls -t $dirLog/*.checklist | cut -d "." -f 2 | uniq | tail -1` Rotacionado para o diretorio $dirZip com sucesso"
                            echo $qtdCheck | checklistZip > /dev/null 2>&1
                            echo $qtdCheck | checklistRemove > /dev/null 2>&1
                            qtdCheck=`expr $qtdCheck - 1`
                    done
            fi
}

######################################
# Nome: changeLog                    #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Exibe a versão do checklist e as   #
# principais mudanças                #
######################################

function changeLog
{
        echo "V4.2.2 - 2013-11-05 - Removida a funcao lpstat a mesma congela ao verificar uma fila offline"
        echo "V4.2.0 - 2013-10-14 - Adicao da funcao de checagem de Image e commands elements da interface HBA"
        echo "V4.1.4 - 2013-09-26 - Bug fix - AutoMount agora verifica cluster e adicao do item lslpp na documentacao da lpar"
        echo "V4.1.3 - 2013-09-26 - Bug fix - Bug na hora de comparação de paths ativos no pcmpath."
        echo "V4.1.2 - 2013-09-25 - Bug fix - Bug do logrotate quando apontado para servidor remoto e Bug do rotacionamento do checklist." 
        echo "V4.1.0 - 2013-08-15 - Bug fixes. Best practice adicionados."
        echo "V4.0   - 2013-07-24 - Adicionada a função de Best practice de 17 itens e outras funcoes"
        echo "V3.0   - 2013-06-07 - Adicionada funcao de BestPractice e outros bugs fixes"
        echo "V2.1   - 2013-03-09 - Adicionado suporte aos arquivos suporte, preboot e posboot"
        echo "V2.0   - 2013-02-26 - Adicao do checklist web e correcao do bug do rotate"
        echo "V1.1   - 2012-09-09 - Muitas coisas"
        echo "V1.0   - 2010-10-30 - Versao inicial"
}

######################################
# Nome: usage                        #
#                                    #
# Autor: ldangelo@br.ibm.com         #
#                                    #
# Descrição                          #
#                                    #
# Função de ajuda, explicando a      #
# utilização do script               #
######################################

function usage
{
        echo "#######################"
        echo "# Selecione uma opcao #"
        echo "#######################"
        echo "--------------------------------------------------------------------------------------------------------------------------------"
        echo "-m = Cria um novo checklist"
        echo "-v = Visualiza um checklist especifico"
        echo "-c = Compara 2 checklists utilizando 2 datas"
        echo "-V = Exibe a versao do checklist"
        echo "-C = Exibe o changelog do checklist"
        echo "-b = Cria um tar com base nos caminhos contidos no arquivo 'chkpath.bck' deve estar no mesmo nivel do checklist"
        echo "-z = Cria um arquivo ZIP com um checklist de uma determinada data "
        echo "-d = Remove um checklist de uma data escolhida"
        echo "-B = Executa as funcoes de BestPractice"
        echo "--------------------------------------------------------------------------------------------------------------------------------"
        echo   "\n"
}

function version
{
        echo 4.2.2
}

[ -z "$1" ] && usage && exit 1
while getopts ":CVbcdhmrvzsB" OPT; do
    case "$OPT" in
    "C") changeLog ;;
    "V") version ;;
    "b") checklistBackup ;;
    "c") checklistCompare ;;
    "d") checklistRemove ;;
    "h") usage ;;
    "m") checklistDo ;;
    "r") checklistRotate ;;
    "v") checklistView ;;
    "z") checklistZip ;;
    "s") sumarioHardware ;;
    "B") BestPractice ;;
    \?) echo "Opcao invalida: -$OPTARG" >&2 && helpme >&2 && exit 1 ;;
    esac
done
