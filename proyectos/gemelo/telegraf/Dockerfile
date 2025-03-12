# Usa la imagen oficial de Telegraf como base
FROM telegraf:latest

COPY telegraf.conf /etc/telegraf/telegraf.conf
EXPOSE 9273

ENTRYPOINT ["telegraf"]
CMD ["--config", "/etc/telegraf/telegraf.conf"]
