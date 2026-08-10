## 2026-08-05 0.9.1
* Support fail instead of error when primary interface is missing

## 2026-08-05 0.9.0
* Support systemd-networkd

## 2026-03-18 0.8.1
* Don't hardcode bond0 as the master interface

## 2026-01-19 0.8.0
* Add support for bonded interfaces

## 2025-05-15 0.7.0
* Add new v4 puppet function network::get_addresses

## 2024-11-20 0.6.0
* drop legacy facts

## 2024-11-20 0.5.1
* Use old ruby syntax as we need to support older versions

## 2024-11-19 0.5.0
* Update to use modulesync
* switch to augeasproviders_sysctl

## 2024-08-21 0.4.1
* Use ignore-errors on ifup to ignore 'RTNETLINK answers: File exists'

## 2024-08-21 0.4.0
* Add motd

## 2024-02-21 0.3.3
* Require networking before masking networkd

## 2024-02-01 0.3.2
* install ifupdown once and only once

## 2024-02-01 0.3.0
* install ifupdown required by network scripts

## Release 0.1.0 2018 Jul 19
* initial port from icann-puppet repo
