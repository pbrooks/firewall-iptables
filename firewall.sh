#!/bin/bash
EXT="eth0"
IPT="/sbin/iptables"
IPT6="/sbin/ip6tables"

function WRITE_RULES {
	IPTABLES=$1

	# Set policy
	$IPTABLES -P INPUT DROP
	$IPTABLES -P OUTPUT ACCEPT
	$IPTABLES -P FORWARD DROP
	$IPTABLES -F

	# Basic rules
	$IPTABLES -A INPUT -i lo -j ACCEPT
	$IPTABLES -A INPUT -p udp -i $EXT --sport 53 --dport 1024:65535 -j ACCEPT
	$IPTABLES -A INPUT -j ACCEPT -m state --state ESTABLISHED,RELATED  -i $EXT -p tcp

	# Blacklist
	$IPTABLES -X ipBlacklist
	$IPTABLES -N ipBlacklist
	$IPTABLES -A INPUT -j ipBlacklist

	# Whitelist
	$IPTABLES -X ipWhitelist
	$IPTABLES -N ipWhitelist
	$IPTABLES -A INPUT -j ipWhitelist

	# Checks
	$IPTABLES -X checks
	$IPTABLES -N checks
	$IPTABLES -A INPUT -j checks

	# SSH Rate limit
	$IPTABLES -X sshCheck
	$IPTABLES -N sshCheck
	$IPTABLES -A checks -p tcp --dport 22 -m state --state NEW -j sshCheck
	$IPTABLES -A sshCheck -m recent --set --name SSH
	$IPTABLES -A sshCheck -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

	# TCP services
	$IPTABLES -X tcpServ
	$IPTABLES -N tcpServ
	$IPTABLES -A INPUT -j tcpServ
	$IPTABLES -A tcpServ -p tcp --dport 22 -j ACCEPT

	# Forwarding
	$IPTABLES -t nat -I POSTROUTING -o eth0 -j MASQUERADE

}

WRITE_RULES $IPT
WRITE_RULES $IPT6

touch /etc/iptables/rules.v4
touch /etc/iptables/rules.v6
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
