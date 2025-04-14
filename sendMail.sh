#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHIVO="$DIR/Reporte.txt"

# Comprobar que el archivo existe
if [ ! -f "$ARCHIVO" ]; then
  echo "El archivo Reporte.txt no existe"
  exit 1
fi


#AQUÍ SE COLOCA LA APIKEY DE SENDGRID
DESTINATARIO="wmarenco@ugb.edu.sv"
REMITENTE="hromeroperla77@gmail.com"
ASUNTO="Reporte de ventas"
MENSAJE="Le adjunto el archIvo Reporte.txt"

REPORTE_BASE64=$(base64 -w 0 "$ARCHIVO")

curl -X POST \
  --url https://api.sendgrid.com/v3/mail/send \
  --header "Authorization: Bearer $API_KEY" \
  --header "Content-Type: application/json" \
  --data '{
    "personalizations": [{
      "to": [{"email": "'"$DESTINATARIO"'"}]
    }],
    "from": {"email": "'"$REMITENTE"'"},
    "subject": "'"$ASUNTO"'",
    "content": [{
      "type": "text/plain",
      "value": "'"$MENSAJE"'"
    }],
    "attachments": [{
      "content": "'"$REPORTE_BASE64"'",
      "type": "text/plain",
      "filename": "Reporte.txt",
      "disposition": "attachment"
    }]
  }'

  echo "Correo enviado correctamente el $(date)" >> "$DIR/envio.log"
