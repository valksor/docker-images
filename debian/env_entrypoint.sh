#!/usr/bin/env bash
set -e

if [ -f /home/valksor/environment/environment.txt ]; then \
	while IFS= read -r line; do \
		export "$line"; \
	done < /home/valksor/environment/environment.txt; \
fi

echo "" > /home/valksor/container_env.sh

while IFS='=' read -r key value; do
	if [ -n "$key" ]; then
		echo "export $key=\"$value\"" >> /home/valksor/container_env.sh
	fi
done < /home/valksor/environment/environment.txt

chmod +x /home/valksor/container_env.sh

if [ -f /home/valksor/container_env.sh ]; then
    /home/valksor/container_env.sh
fi

if [ $# -eq 0 ]; then
    exec bash
else
    exec "$@"
fi
