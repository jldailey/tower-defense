all: js/tower-defense.js js/bling.js js/coffee-script.js

js/tower-defense.js: tower-defense.coffee
	coffee -o js -c tower-defense.coffee

js/bling.js:
	mkdir -p js
	curl http://blingjs.com/js/bling.js > $@

js/coffee-script.js:
	mkdir -p js
	curl http://coffeescript.org/extras/coffee-script.js > $@



