# Description

This bash script allows you to extract subtiles from MKV media files in Linux.<br>
It uses zenity for a GUI, mkvextract for file extraction and jq to read the tracks info in JSON<br>

## Dependencies:
```
sudo apt-get update && sudo apt-get install zenity mkvtoolnix mkvtoolnix-gui jq
```

## Instructions:

Download the script in terminal with:
```
wget https://raw.githubusercontent.com/Chillsmeit/extractmkvsub-gui/main/extractmkvsub-gui.sh
```
Make the script executable:
```
chmod +x extractmkvsub-gui.sh
```
Run the script **without** sudo privileges:
```
./extractmkvsub-gui.sh
```
