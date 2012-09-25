COFFEE=node_modules/.bin/coffee

all: js/tower-defense.js js/bling.js js/coffee-script.js

js/tower-defense.js: tower-defense.coffee $(COFFEE)
	$(COFFEE) -o js -c tower-defense.coffee

js/bling.js:
	mkdir -p js
	curl http://blingjs.com/js/bling.js > $@

js/coffee-script.js:
	mkdir -p js
	curl http://coffeescript.org/extras/coffee-script.js > $@

$(COFFEE):
	npm install coffee-script
	sed -i 's/path.exists/fs.exists/' node_modules/coffee-script/lib/coffee-script/command.js

clean:
	rm -rf js
	rm -rf node_modules
