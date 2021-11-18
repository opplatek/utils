# Connect bluetooth heaphones to Linux

Set of scripts stolen from other GitHub repos (`connect-audio.sh` from [here](https://gist.github.com/egelev/2e6b57d5a8ba62cf6df6fff2878c3fd4) and `connect-audio.py` from [here](https://askubuntu.com/questions/48001/connect-to-bluetooth-device-from-command-line)) to connect bluetooth headphones (Sony WH-1000XM3) to Linux (Ubuntu 16.04) or to correct their connection (audio sink).

`connect-audio.sh` fixes connection and sets the headphones as audio sink. However, headphones must be already connected. If they are not, use `python connect-audio.py` to connect it.

You can also use `connect-headphones.desktop` to make a quick launcher desktop app.
