install:
	mkdir -p ~/.local/bin/python
	cp ./vert ~/.local/bin/python
	chmod +x ~/.local/bin/python/vert
	pip install -r requirements.txt