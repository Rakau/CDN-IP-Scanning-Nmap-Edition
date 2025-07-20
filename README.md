# 脚本说明
1、自用

2、只在Debian 12上测试成功，其他版本未测

3、请确保Nmap已经正确安装

4、脚本只扫描打开的443端口并记录对应的IP

5、优选IP大部分情况下都不符合CDN服务商的服务条款，请自行负责使用优先IP后的一切后果

# 用法
以Root权限或者加上sudo运行以下脚本，然后根据提示输入CDN运营商的IPv4网段即可

```
bash <(curl -s https://raw.githubusercontent.com/Rakau/CDN-IP-Scanning-Nmap-Edition/main/cis.sh)
```

或者

```
bash <(wget -qO- https://raw.githubusercontent.com/Rakau/CDN-IP-Scanning-Nmap-Edition/main/cis.sh)
```
