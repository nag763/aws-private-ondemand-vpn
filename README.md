# AWS Private ondemand VPN

Allocate a private VPN for few hours (or more), kill it, pay almost nothing


## Purpose

Most streaming services provide georestricted content, notably classical TV services providers.

Using a VPN-Provider to bypass this issue may not be a good enough solution while watching sport events on streaming platform, as the IP has most likely already been detected as a VPN one by the content provider, since most VPN uses shared instances.

To get around that, the solution purposed here is to have a dedicated VPN running for few hours, allowing you to watch georestricted content.

Besides, having a dedicated instance running for few hours will cost you way less than paying a monthly subscribtion.

## Backstory

Basicly, I am bored about not be able to watch Sports on TV while being remote.

## Prerequisites

* Having an AWS Account

* Being logged in with AWS Cli - ensure you have the right permissions -

* Having terraform installed

## Installation

1. Clone the project

```
git clone https://github.com/nag763/aws-private-ondemand-vpn
```

2. Init the terraform

```
terraform init
```

## How to start a server

1. Run

```
terraform apply
```

If you want to check what will be created forehand :

```
terraform plan

```

## How to kill the instance

```
terraform destroy
```

## Limitations

* Limited to AWS (so far?)

* WG Port is always the same - 51820 -, having a random value between 50000 and 70000 would be better for security purposes

* Instance location (so far?) limited to Paris

## Pricing comparison with traditional servers

Running this dedicated server the duration of a football game will cost you 0.02 given AWS Pricing calculator

In comparison, a VPN Subscribtion may cost you around 5 euros per month on an average

If you ever forget to kill the instance, it will only cost 9 USD per month

Using a t4g.nano may reduce prices per two