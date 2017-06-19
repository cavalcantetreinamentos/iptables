# Adicionar na inicialização #update-rc.d firewall.sh defaults

##Script de configuração básica do IPTABLES
#Definição da interfaces
INTERNA=eth1
EXTERNA=eth0

#Definição das redes
REDE_IP_INTERNA=172.17.0.0/24
REDE_IP_EXTERNA=192.168.0.0/24

#Habilitar roteamento
echo 1 > /proc/sys/net/ipv4/ip_forward

#Habilitar TCP SynCookie
echo 1 > /proc/sys/net/ipv4/tcp_syncookies

#Habilitar proteção ip spoofing
for i in /proc/sys/net/ipv4/conf/*/rp_filter
do
    echo 1 > $i
done

#LIMPAR AS TABELAS 
iptables -t filter -F
iptables -t filter -X
iptables -t filter -Z

iptables -t nat -F
iptables -t nat -X
iptables -t nat -Z

iptables -t mangle -F
iptables -t mangle -X
iptables -t mangle -Z

# Definir política padrão
iptables -t filter -P INPUT DROP
iptables -t filter -P FORWARD DROP
iptables -t filter -P OUTPUT ACCEPT

#Realizar NAT
iptables -t nat -A POSTROUTING -s $REDE_IP_INTERNA -o $EXTERNA -j MASQUERADE

# Bloquear pacotes inválidos
iptables -t filter -A INPUT -m conntrack --ctstate INVALID -j DROP
iptables -t filter -A FORWARD -m conntrack --ctstate INVALID -j DROP

# Bloquear algumas tentativas de scanner
iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL FIN,SYN -j DROP

#Permitir a máquina com IP 172.17.0.2 realizar ping para a interface do firewall
iptables -t filter -A INPUT -s 172.17.0.2/32 -d 172.17.0.1 -p icmp --icmp-type echo-request -m limit --limit 1/m -j ACCEPT
iptables -t filter -A INPUT -s 172.17.0.2/32 -d 172.17.0.1 -p icmp --icmp-type echo-request -j REJECT 

# Permitir tráfego na interface de loopback
iptables -t filter -A INPUT -i lo -j ACCEPT

#Permitir acesso ao facebook para o MAC 
iptables -t filter -A FORWARD -d www.facebook.com -m mac --mac-source 08:00:27:E7:6F:26 -j ACCEPT

# Bloquear facebook para todos
iptables -t filter -A FORWARD -d www.facebook.com  -j LOG --log-prefix "Bloqueio-Facebook"

iptables -t filter -A FORWARD -d www.facebook.com -j DROP

#Bloquear download de arquivos .exe
iptables -t filter -A FORWARD -p tcp -m multiport --dport 20,21,80,443 -m string --string ".exe" --algo bm -j LOG --log-prefix "Download arquivo executável"

iptables -t filter -I FORWARD -m string --string "facebook" --algo bm -j DROP

#Permitir a rede interna acessar os serviços DNS, ftp, http e https
iptables -t filter -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -t filter -A FORWARD -p tcp -m multiport --dport 20,21,80,443 -j ACCEPT

#Permitir a rede interna realizar ping para Internet
iptables -t filter -A FORWARD -s $REDE_IP_INTERNA -p icmp --icmp-type echo-request -j ACCEPT

#Permitir pacotes relacionados
iptables -t filter -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
































