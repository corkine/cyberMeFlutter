import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WireguardHelpView extends ConsumerWidget {
  const WireguardHelpView({super.key});

  final String content = """
# 在 Ubuntu 20.04 安装WireGuard VPN
WireGuard 是一种现代VPN虚拟私有网络技术，它利用最新的加密技术。

与其他流行的VPN解决方案，例如 Ipsec 和 OpenVPN 相比，WireGuard 更快，更易于配置并且占用空间更小。它是跨平台的，几乎可以在任何操作系统运行，包括 Linux，Windows，Android和macOS。Wireguard 是对等 VPN，它不使用 C/S 客户端/服务器模型。根据配置，对等方可以充当传统的服务器或客户端。它充当隧道，在每个对等设备上创建虚拟网络接口来工作。对等方通过交换和验证公钥，类似于使用SSH 公钥模式来相互认证。公钥与隧道中允许的 IP 地址列表进行映射。VPN流量封装在UDP中。

在本教程中，所有"接口"都表示为网卡，网卡是中国术语，接口通用的名词。Wireguard 可用于防御中间人攻击，匿名浏览网络，绕过受地域限制的内容或允许在家工作的同事安全地连接到公司网络。要遵循本教程，您登录的用户必须具有sudo权限。我们将首先在 Ubuntu Ubuntu 20.04 安装WireGuard，然后将其设置为服务器。我们还将说明如何配置WireGuard作为客户端的配置。WireGuard可从默认的Ubuntu软件源中获得。

要安装它，请运行apt命令，这将安装WireGuard模块和工具。WireGuard作为内核模块运行。

> sudo apt update && sudo apt install wireguard

wg 和 wg-quick 命令行工具可帮助您配置和管理 WireGuard 接口，WireGuard 接口是虚拟网卡。WireGuard VPN 网络中的每个设备都需要具有私钥和公钥。我们可以使用 wiregurad 的工具 wg genkey 和 wg pubkey 在 /etc/wireguard/ 目录中生成私钥 /etc/wireguard/privatekey 和公钥 /etc/wireguard/publickey。

以下命令将使用 wg genkey 和 wg pubkey，tee 命令以及管道同时生成私钥和公钥并存储在 /etc/wireguard/ 目录。

> wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey

您可以使用 cat 命令或 less 命令查看私钥和公钥文件的内容。请不要把私钥与任何人共享，并且应始终保证私钥的安全。Wireguard 还支持预共享密钥，这增加了对称密钥加密的附加层。预共享密钥是可选的，并且对于每个对等设备都必须是唯一的。

下一步是配置虚拟接口。可以使用 ip 命令和 wg 命令配置接口。使用你喜欢的文本编辑器创建配置文件 /etc/wireguard/wg0.conf，在本教程中我们将使用 vim创建文件。复制黏贴以下内容到 /etc/wireguard/wg0.conf 文件中，然后保存并退出 vim 编辑器。

> sudo vim /etc/wireguard/wg0.conf

```
[Interface]
Address = 10.0.0.1/24
SaveConfig = true
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE
```

接口的命名可以是任何你喜欢的名称，但是建议使用诸如 wg0 或 wgvpn0 之类的名称。可以让我们能快速分清是物理接口还是虚拟接口即可。这里说明一下 /etc/wireguard/wg0.conf 配置文件定义接口的每个字段含义。

Address wg0 接口的IP v4 或 IP v6 的地址。请使用保留给私有网络范围内的 IP 地址，比如10.0.0.0/8、172.16.0.0/12 或 192.168.0.0/16。
ListenPort 是接口监听的端口。PrivateKey 由 wg genkey 命令生成的私钥。你可以使用 sudo cat /etc/wireguard/privatekey 命令要查看私钥文件的内容。
SaveConfig 设置为 true 时，当关闭接口时将当前配置将保存到配置文件中。PostUp 在启动接口之前执行的命令或脚本。

在此示例中，在 PostUp 钩子启用 iptables 伪装。这允许流量离开服务器，使VPN客户端可以访问互联网。

请记得使用您可访问网络的接口名称替换-A POSTROUTING后面的ens3。您可以通过以下 ip 命令方式轻松找到可访问网络的接口。

> ip -o -4 route show to default | awk '{print \$5}'

在 PostDown 钩子，我们在关闭接口之前删除 iptables 伪装。一旦接口关闭，iptablesnat 转发规则将被删除。为了保证私钥的安全，请将 wg0.conf 和 privatekey 文件对普通用户不可读。运行 chmod 命令sudo chmod 600 /etc/wireguard/{privatekey,wg0.conf}。

> sudo chmod 600 /etc/wireguard/{privatekey,wg0.conf}

完成以上步骤后，我们可以通过 wg-quick 启动 wireguard 服务器。这在 wireguard 中就是将接口状态设置为开启，运行 wg-quick up 命令将启用 wg0 接口。

> sudo wg-quick up wg0

```
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.0.0.1/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
```

要检查接口状态和配置，请运行 wg show 命令。因为wg0是一个虚拟网卡，因此您也可以运行ip a show wg0 来验证 wg0 接口状态。

> sudo wg show wg0
> ipa show wg0

```
interface: wg0
  public key: r3imyh3MCYggaZACmkx+CxlD6uAmICI8pe/PGq8+qCg=
  private key: (hidden)
  listening port: 51820
```

wireguard 作为内核模块运行，默认情况 wireguard 会自动启动，但接口 wg0 虚拟网卡不会自动启动。你可以通过 systemctl 命令将 wg0 设置为自动启动。要在启动时启用 WireGuard 的wg0 接口。请运行 sudo systemctl enable wg-quick@wg0 命令。

> sudo systemctl enable wg-quick@wg0

在之前的步骤中我们在启动 wg0 接口 postup 前配置了一条 iptables 的 NAT 路由。为使 NAT 路由可正常工作，必须启用IP转发。

使用你喜欢的编辑器打开文件 /etc/sysctl.conf。在本教程中我们将使用vim打开文件。然后添加或取消注释行 net.ipv4.ip_forward。退出 vim 并保存文件。修改完成后，运行 sudo sysctl -p 命令启用新的内核属性配置。

> sudo vim /etc/sysctl.conf
> net.ipv4.ip_forward = 1
> sysctl -p
> sudo ufw allow 51820/udp

客户端一般使用 GUI，或者对等配置 Linux 客户端，之后在此服务端添加这些 Peer，设定公钥和其 IP 地址。

> sudo wg set wg0 peer CLIENT_PUBLIC_KEY allowed-ips 10.0.0.2
> sudo wg set wg0 peer 2V1FkL7kyUWXP+5Dh8EiXBPi8KVwskDXCFFULM48s20= allowed-ips 10.0.0.103

下面是根据日期自动变化端口的一个脚本，将其放在 change.sh 中，crontab -e 每天凌晨更改端口，注意，**设置此脚本前要先关闭由 wg-quick 管理的端口（wg-quick down wg0）**。

> 0 0 * * * /bin/bash /root/change.sh >> /root/cron.log

```
#!/bin/bash
echo "Wireguard port updater start at \$(date +%Y-%m-%d\ %H:%M:%S)"
port_now=\$(cat /etc/wireguard/wg0.conf | awk -F ' *= *' '/ListenPort/ {print \$2}')
echo "Now Port is \$port_now"
new_port=\$(expr `date '+%j'` + 52001)
echo "The New Port will be \$new_port"
/bin/systemctl stop wg-quick@wg0.service
sleep 1
sed -i '/^ListenPort =/s/^ListenPort =.*/ListenPort = '"\$new_port"'/' /etc/wireguard/wg0.conf
sleep 1
echo "Deny \$port_now on ufw, Allow \$new_port on ufw"
ufw deny \$port_now/udp
ufw allow \$new_port/udp
echo "Start Wireguard service"
/bin/systemctl start wg-quick@wg0.service
wg
echo "Done update port"
```

""";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(title: const Text("Deploy Help")),
        body: Markdown(data: content, selectable: true));
  }
}
