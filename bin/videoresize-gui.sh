#!/usr/bin/env bash
#
# Arquivo: videoresize-gui.sh
# Descrição: Script usando o YAD e ffmpeg para redimensionar arquivos de vídeo.
#
# Feito por Lucas Saliés Brum, a.k.a. sistematico <lucas@archlinux.com.br>
#
# Criado em:        2018-06-09 19:39:27
# Última alteração: 2018-07-20 12:42:55

titulo="Video Resize"
resolucoes=("1280" "1080" "720" "640" "480" "320")

command -v yad 1> /dev/null 2> /dev/null
if [ $? = 1 ]; then
	echo "yad não instalado."
	exit
fi

nome() {
	fl=$(basename -- "$1")
	ext="${fl##*.}"
	echo "${fl%.*}.$2.$$.${ext}"
}

caminho() {
    echo $(dirname "${1}")
}

echo "$(echo "${res}" | awk '{$1=$1};1')"
video=$(yad --title "$titulo" --separator=" " --width=400 --form --field="Arquivo:SFL" "$1" | awk '{$1=$1};1')
[[ -z $video ]] && exit 1

novo=$(dirname "${video}")/$(nome "$video" "resize")
largura=$(ffprobe -v quiet -show_format -show_streams "${video}" | grep '^width' | cut -d "=" -f 2)

for r in ${resolucoes[@]}; do
    if [ $r -lt $largura ]; then
        res+="${r}!"
    fi
done

resolucao=$(yad --form --width=400 --separator="!" --title "$titulo" --image=gnome-shutdown --button="gtk-close:1" --button="gtk-ok:0" --field="Arquivo:SFL" --field="Resolução:CB" "$novo" "$(echo ${res%?} | awk '{$1=$1};1')")
[[ -z $resolucao ]] && exit 1

 #| awk -F'!' '{printf "saida=\"%s\"\nre=%s", $1, $2}'

saida=$(echo $resolucao | awk -F'!' '{printf "%s", $1}')
resolucao=$(echo $resolucao | awk -F'!' '{printf "%s", $2}')

#[ -f $novo ] && mv "$novo" "$(dirname $novo)/$(nome $novo $$)"
#ffmpeg -vn -i "${video}" -filter:v scale=${resolucao}:-1 -c:a copy "${novo}" 2>&1 | yad --progress --pulsate

#ffmpeg -vn -y -i "${video}" -filter:v scale=$resolucao:-1 -c:a copy "${saida}" | yad --title "$titulo" --text="Redimensionando video..." --width=400 --progress --pulsate --auto-close


# ffframes ()
# {
	# same as what you had
	ff_length1=( $(ffmpeg -i "$video" 2>&1 | sed -n "s/.* Duration: \([^,]*\), start: .*/\1/p") )
	# here straight awk output of total length
	ff_length=( $(echo "$ff_length1" | awk -F':'  '{ print $1*3600 + $2*60 + $3 }'))
		
	ff_fps=( $(ffmpeg -i "$video" 2>&1 | sed -n "s/.*, \(.*\) tbr.*/\1/p") )
	# here we have total number of frames
	total_frames=( $(echo $ff_length $ff_fps | awk '{ printf( "%3.0f\n" ,($1*$2)) } '))
	
	#echo total-frames $total_frames 
# }


# ffframes


ffmpeg -vn -y -i "${video}" -filter:v scale=$resolucao:-1 -c:a copy "${saida}" 2>&1 | \
		awk -vRS="\r" '$1 ~ /frame/ {gsub(/frame=/," ");gsub(/fps=/," ");gsub(/kB/," ");gsub(/time=/," ");gsub(/ \(/," ");print "\n#Converting video : '"$fftfile"'.\\n\\nCurrent Frame :\\t\t"$1"\\t\t\tFrame rate (s) :\\t\t\t"$2"\\nFile size (mb) :\\t\t"int($5/1024)"."int((($5/1024)-(int($5/1024)))*10)"\\nDuration of video :\\t'$ff_length1'\\tTime elapsed in video :\\t"int($6/3600)":"int((($6/3600)-(int($6/3600)))*60)":"int((($6/60)-(int($6/60)))*60)"\\nTime Remaining :\\t"int((('$total_frames'-$1)/$2)/3600)":"int((((('$total_frames'-$1)/$2)/3600)-(int((('$total_frames'-$1)/$2)/3600)))*60)":"int((((('$total_frames'-$1)/$2)/60)-(int((('$total_frames'-$1)/$2)/60)))*60)"\\t\tPercent complete :\\t\t"int(($6/'$ff_length')*100) "%";}' | \
		zenity --progress \
			--auto-kill \
			--auto-close \
			--title="$title" \
			--width=500

# yad --text "$ff_length1 $ff_length $ff_fps $total_frames" --button=gtk-no:1

if [ $? -eq 0 ]; then
	yad --text "Video: $saida redimensionado com sucesso." --button=gtk-no:1
else
	yad --text "Falha no redimensionamento de: ${saida}." --button=gtk-no:1
fi


