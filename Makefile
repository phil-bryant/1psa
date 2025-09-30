all: clean compile install

clean:
	rm -f 1psa

compile:
	go build -o 1psa

install:
	cp 1psa /usr/local/bin/

.PHONY: all clean compile install
