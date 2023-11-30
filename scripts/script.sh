#!/bin/bash

FILE="botmap.conf"
ROBOTSTXT="robots.txt"

wget -q -O - https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/_generator_lists/bad-user-agents.list > bad-user-agents.list

echo "map \$http_user_agent \$bad_client { " > ${FILE}
echo -e "\tdefault 0;" >> ${FILE}

while read -r ENTRY;
do
	echo -e "\t${ENTRY} 1;" >> ${FILE}
	echo "User-agent: ${ENTRY}" >> ${ROBOTSTXT}
	echo "Disallow: /" >> ${ROBOTSTXT}
done < bad-user-agents.list

echo "}" >> ${FILE}

sed -i s/"\\\ "/" "/g ${ROBOTSTXT}
sed -i s/"\\\ "/" "/g ${FILE}

