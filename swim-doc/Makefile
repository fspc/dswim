
all:install

install:
	install -d /share/man/man8
	cp -f swim.8 /share/man/man8
	install -d /share/man/man5
	cp -f swimrc.5 /share/man/man5	
	install -d /share/doc/swim
	install -d /usr/share/doc/swim/swim.html
	cp -fa swim.html/* /usr/share/doc/swim/swim.html
	install -d /usr/share/doc/swim/swimrc.html
	cp -fa swimrc.html/* /usr/share/doc/swim/swimrc.html
	install -d /usr/share/doc/swim/examples
	cp -fa examples/* /usr/share/doc/swim/examples
	cp -a QUICKSTART.text /share/doc/swim
	cp -a REQUIREMENTS.text /share/doc/swim
	cp -a swim_by_example.html /share/doc/swim
	cp -a THEMES /share/doc/swim
	cp -a TODO /share/doc/swim 
	cp -a BUGS /share/doc/swim
	cp -a TODO /share/doc/swim
	cp -a COPYING /share/doc/swim
	cp -a contact_and_website /share/doc/swim
	cp -a changelog /share/doc/swim
	cp -a swim.text /share/doc/swim
	cp -a swimrc.text /share/doc/swim

remove:
	rm /usr/share/doc/swim/swim.html/*
	rmdir /usr/share/doc/swim/swim.html
	rm /usr/share/doc/swim/swimrc.html/*
	rmdir /usr/share/doc/swim/swimrc.html
	rm /usr/share/doc/swim/examples/*
	rmdir /usr/share/doc/swim/examples
	rm /usr/share/doc/swim/*
	rmdir /usr/share/doc/swim
	rm share/man/man5/swimrc.5
	rm share/man/man8/swim.8





