
all: install

install:	
	install -d $(DESTDIR)/var/lib/dpkg
	install -d $(DESTDIR)/usr/bin
	cp -a swim $(DESTDIR)/usr/bin/swim
	install -d $(DESTDIR)/usr/share/perl5/SWIM
	cp -fa SWIM/*pm $(DESTDIR)/usr/share/perl5/SWIM
	install -d $(DESTDIR)/usr/lib/SWIM 
	cp -fa bin/* $(DESTDIR)/usr/lib/SWIM
	install -d $(DESTDIR)/etc/swim
	cp -f swimrc $(DESTDIR)/etc/swim

remove:
	rm /usr/lib/perl5/SWIM/*
	rmdir /usr/lib/perl5/SWIM
	rm /usr/bin/swim
	rm /usr/lib/SWIM/*
	rmdir /usr/lib/SWIM



