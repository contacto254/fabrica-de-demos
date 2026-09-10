#!/usr/bin/env bash
# Script de arranque para el entorno en la nube de Claude Code (claude.ai/code).
#
# Se pega tal cual en el campo "Setup script" de la cloud environment. Corre una sola vez,
# antes de que arranque la sesion, y queda cacheado. Tiene un limite de 5 minutos y tiene
# que terminar bien, o la sesion no arranca.
set -e

echo "Preparando el entorno de la fabrica de demos..."

# El CLI de Railway no viene preinstalado en la maquina de la nube.
npm install -g @railway/cli

echo
echo "Instalado:"
echo "  node    $(node -v)"
echo "  npm     $(npm -v)"
echo "  railway $(railway --version 2>/dev/null || echo 'no responde')"
echo "  curl    $(curl --version | head -1 | awk '{print $2}')"

# Chequeos que no cortan el arranque, solo avisan en el registro.
if [ -z "${RAILWAY_API_TOKEN:-}" ]; then
  echo
  echo "  AVISO: falta RAILWAY_API_TOKEN en las variables del entorno."
fi
if [ -z "${CF_TOKEN:-}" ]; then
  echo "  AVISO: falta CF_TOKEN en las variables del entorno."
fi

echo
echo "Listo."
