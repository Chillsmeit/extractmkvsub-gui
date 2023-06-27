#!/bin/bash

# Install required packages if not installed
if ! command -v zenity &> /dev/null; then
	echo "Zenity is not installed. Installing Zenity..."
	sudo apt-get install -y zenity
fi

if ! command -v mkvmerge &> /dev/null; then
	echo "MKVToolNix is not installed. Installing MKVToolNix..."
	sudo apt-get install -y mkvtoolnix
fi

# Prompt user to choose an MKV file
mkv_file=$(zenity --file-selection --title="Choose an MKV file" --file-filter="MKV files (*.mkv) | *.mkv" --file-filter="All files | *")

# Chosen MKV file without extension
mkv_file_noext="${mkv_file%.*}"

# Get subtitle tracks information with JSON
subtitle_id=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "subtitles") | .id')
subtitle_language=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "subtitles") | .properties.language')
subtitle_codec=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "subtitles") | .codec')
subtitle_trackname=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "subtitles") | .properties.track_name')

# Check if there are subtitle tracks
if [[ -z $subtitle_id ]]; then
	zenity --error --text="No subtitle tracks found in the selected MKV file."
	exit 1
fi

# Prompt user to choose a subtitle track
mapfile -t id_array <<< "$subtitle_id"
mapfile -t subtitle_array <<< "$subtitle_language"
mapfile -t codec_array <<< "$subtitle_codec"
mapfile -t trackname_array <<< "$subtitle_trackname"

# Create an array of options for the Zenity list dialog
options=()
for ((i=0; i<${#id_array[@]}; i++)); do
	options+=("${id_array[i]}" "${subtitle_array[i]}" "${codec_array[i]}" "${trackname_array[i]}")
done

# Show the selected array values with Zenity list dialog
chosen_subtitle_id=$(zenity --list --title="Choose a subtitle" --column="ID" --column="Language" --column="Codec" --column="Track Name" --height=400 --width=600 "${options[@]}")

# Cancel program if user clicks "Cancel"
if [[ $? -eq 1 ]]; then
	exit 1
fi

# Check if user selected a subtitle ID
if [[ -z $chosen_subtitle_id ]]; then
	zenity --error --text="No subtitle ID selected."
	exit 1
fi

# Find the index of the chosen_subtitle_id in the id_array
index=-1
for ((i=0; i<${#id_array[@]}; i++)); do
	if [[ "${id_array[i]}" == "$chosen_subtitle_id" ]]; then
		index=$i
		break
	fi
done

# Extract the subtitle based on the chosen codec
if [[ $index -ne -1 ]]; then
	chosen_codec="${codec_array[index]}"
fi
echo $chosen_codec
if [[ $chosen_codec == "SubStationAlpha" ]]; then
	mkvextract tracks "$mkv_file" "${chosen_subtitle_id}":"$mkv_file_noext.ass"
elif [[ $chosen_codec == "HDVM PGS" ]]; then
	mkvextract tracks "$mkv_file" "${chosen_subtitle_id}":"$mkv_file_noext.sup"
elif [[ $chosen_codec == "SubRip/SRT" ]]; then
	mkvextract tracks "$mkv_file" "${chosen_subtitle_id}":"$mkv_file_noext.srt"
elif [[ $chosen_codec == "VobSub" ]]; then
	mkvextract tracks "$mkv_file" "${chosen_subtitle_id}":"$mkv_file_noext"
fi

# Show success message
zenity --info --text="Subtitle ID $chosen_subtitle_id extracted successfully"
