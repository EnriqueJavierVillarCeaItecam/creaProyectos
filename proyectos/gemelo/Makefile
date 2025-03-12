run:
	docker compose down
	docker compose up -d

restart:
	docker compose down -v --rmi all
	make run

restart_full:
	docker compose down -v --rmi all
	rm -rfv data/grafama-storage data/influxdb-storage
	make run
