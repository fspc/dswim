
all: install

install:	
	install -d /var/lib/dpkg
	install -d /usr/bin
	cp -a swim /usr/bin/swim
	install -d /usr/share/perl5/SWIM
	cp -fa SWIM/*pm /usr/share/perl5/SWIM
	install -d /usr/lib/dswim 
	cp -fa bin/*swim /usr/lib/dswim
	install -d /etc/swim
	cp -fa swimrc /etc/swim
	install -d /usr/share/man/man8
	cp -fa swim.8 /usr/share/man/man8
	install -d /usr/share/man/man5
	cp -fa swimrc.5 /usr/share/man/man5


remove:
	rm /usr/share/perl5/SWIM/*
	rmdir /usr/share/perl5/SWIM
	rm /usr/bin/swim
	rm /usr/lib/dswim/*swim
	rmdir /usr/lib/dswim
	rm /usr/share/man/man8/swim.8
	rm /usr/share/man/man5/swimrc.5



