<<<<<<< HEAD
=======
# 🏗 Online Betting Protocol
Bet with optimal fee, no chance of rugpull.

##  Contracts deployed on Kovan Testnet
=======
[OBPMain](https://kovan.etherscan.io/address/0x3D80793CaB90A0FaCD1Cd4Ad9326A6c9eEdCcD56#code)
[OBPToken](https://kovan.etherscan.io/address/0xdC1BC2d84dFeF19478B843234c38b8696bfA81f7#code)
[CourtProxy](https://kovan.etherscan.io/address/0x07A561D151E963812e05a8a5639Ab7A61c402178#code)
[CourtLib(V1)](https://kovan.etherscan.io/address/0x983C70efc7aA04830A7093ec267dd8B2a6e3861a#code)
[BettingOperatorDeployer](https://kovan.etherscan.io/address/0x16210fF94FF33C59a9C61eB1Fa1Ef310856045Bb#code)
[RefereeDeployer](https://kovan.etherscan.io/address/0x0f4292c5fB9aFB0eED779522920D1f9d79a8BD41#code)
[BettingRouter](https://kovan.etherscan.io/address/0x39E7F6de3De7037f3eF48327C52Cc9336Ed80EAf#code)

## High-Level Overview
![Screenshot 2021-11-06 at 10 03 37 PM](https://user-images.githubusercontent.com/16856703/141306704-798f782e-03fa-45cf-846d-7f2f6af46795.png)


## Introduction:
=======
OBP = Online Betting Protocol for everyone!
There are billions of dollar being gambled on sport&Esport events every year. Yet people can hardly find a fair, decentralised and customized betting place for events they would like to bet. Result of sport events are exposed to everyone; rather than creating an oracle network when only whitelisted operator can run, OBP allows everyone to be a bettor, refereee, event operator, as well as a court member for keeping OBP as a fair place!


### OBPToken:
---
`OBPToken` is an ERC20 token that serves 3 functions:
1. Stake at court for getting **1%** of all total fee generated in all events deployed in the protocol.
2. Stakers are eligible to vote on cases where an refereee is sued for cheating/injecting wrong result for an event.
3. OBPToken is accepted as a betting token.


### OBPMain:
---
`OBPMain` is the hub of OBP protocols. It allows anyone to deploy a bettingOperator and a referee respectively.
This contracts:
1. Records all official referee(s) and betting operator(s) that are deployed through the official deployers.
2. Deploy Referee or Operator
3. Add/remove supported tokens for betting
4. Record the official court contract.


### BettingOperatorDeployer:
---
`BettingOperatorDeployer` deploys a bettingOperator. It should be only called indirectly through the OBPMain contracts so the deployed operator is registered in the OBPMain contract.


### BettingOperator
---
A `bettingOperator` contains a roothash when deployed, that is a hash of all its event logic and Pool Ids. A BettingOpeartor start to take bet once
it has received a bounding of OBP from a registered Referee. Then anyone can place bet on a Pool based on its Ids. Payout is claimable once the Referee closes the Pool and inject payout results. A betting operator takes 1% of total bet fee.


### RefereeDeployer:
---
`RefereeDeployer` deploys a referee. It should be only called indirectly through the OBPMain contracts so the deployed referee is registered in the OBPMain contract.


### Referee
---
A `Referee` takes the responsibility to bounds its staked OBP for betting Operator(s) to ensure it is injecting the precise payout result,
in return for **3%** of the total betting fee received in the bettingOperator.
### CourtProxy:
---
`CourtProxy` is an upgradable proxy that performs the court duty. It allows
1. staking for getting **1%** of total bet fee.
2. voting
3. upgradeability
4. consifacte staked OBP from a referee if its result is deemed corrupt.


### CourtLib(V1)
---
`CourtLib` is the logic library that handles the delegatd call from CourtProxy.



If you want to contribute, you can checkout [master-based-scaffoldETH](https://github.com/chrisckwong821/obp/tree/master-based-scaffoldETH) for setting up a development environment.


