


stayawake: 
	gcc -lobjc -framework Foundation -framework IOKit -framework CoreServices  -o stayawake stayawake.m


install: stayawake
	install -m 0755 stayawake /usr/local/bin 

clean:
	rm stayawake
