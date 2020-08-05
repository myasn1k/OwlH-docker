#!/bin/sh

cd /usr/local/owlh/src/owlhmaster
/usr/sbin/apachectl start
GOPATH=/usr/local/owlh /usr/local/owlh/src/owlhmaster/owlhmaster
