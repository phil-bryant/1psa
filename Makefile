all: clean compile install

clean:
	rm -f 1psa

compile:
	go build -o bin/1psa

install:
	cp bin/1psa /usr/local/bin/

.PHONY: all clean compile install
