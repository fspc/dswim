
all: install

install:	
	install -d /var/lib/dpkg
	install -d /usr/bin
	cp -a swim /usr/bin/swim
	install -d /usr/share/perl5/SWIM
	cp -fa SWIM/*pm /usr/share/perl5/SWIM
	install -d /usr/lib/SWIM 
	cp -fa bin/* /usr/lib/SWIM
	install -d /etc/swim
	cp -f swimrc /etc/swim

remove:
	rm /usr/share/perl5/SWIM/*
	rmdir /usr/share/perl5/SWIM
	rm /usr/bin/swim
	rm /usr/lib/SWIM/*swim
	rm -rf /usr/lib/SWIM



