
all: install

install:	
	install -d $(DESTDIR)/var/lib/dpkg
	install -d $(DESTDIR)/bin
	cp -a swim $(DESTDIR)/bin/swim
	install -d $(DESTDIR)/lib/perl5/SWIM
	cp -f Conf.pm $(DESTDIR)/lib/perl5/SWIM/Conf.pm
	cp -fa lib/* $(DESTDIR)/lib/perl5/SWIM
	install -d $(DESTDIR)/lib/SWIM 
	cp -fa bin/* $(DESTDIR)/lib/SWIM
	install -d $(DESTDIR)/etc/swim
	cp -f swimz.list $(DESTDIR)/etc/swim
	cp -f swimrc $(DESTDIR)/etc/swim

remove:
	rm /usr/lib/perl5/SWIM/*
	rmdir /usr/lib/perl5/SWIM
	rm /usr/bin/swim
	rm /usr/lib/SWIM/*
	rmdir /usr/lib/SWIM



