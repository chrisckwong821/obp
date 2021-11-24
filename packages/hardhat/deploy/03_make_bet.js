// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  const OBPToken = await ethers.getContract("OBPToken", deployer);
  const OBPMain = await ethers.getContract("OBPMain", deployer);

  const roothash = "ddaa1b004d25cfd8a5cc6503381eb11b1b2deaf02d17e8c18ba125649f186ef8";
  const operatorAddress = await OBPMain.allOperators(roothash);
  const Operator = await ethers.getContractAt("BettingOperator", operatorAddress);
  console.log(operatorAddress);

  //placeBet(uint item, uint amount, address bettor)
  // this is equivalent to bet on item 1 for 0.1 OBP under the address deployer
  
  const approveBetSize = 10000;
  const Router = await ethers.getContract("BettingRouter", deployer);
  //one-off allow the router to spend yr OBPToken
  const approve = await OBPToken.approve(Router.address, approveBetSize);

  const router = await ethers.getContractAt("BettingRouter", Router.address);
  // place bet through Router
  var item = 1;
  var betSize = 1000;
  var bettor = deployer;
  const makeBet_1 = await router.placeBet(operatorAddress, item, betSize, bettor);
  console.log("item ", item, "receive a bet of : ", betSize, " from bettor ", bettor);
  var item = 2;
  var betSize = 2000;
  var bettor = deployer;
  const makeBet_2 = await router.placeBet(operatorAddress, item, betSize, bettor);
  console.log("item ", item, "receive a bet of : ", betSize, " from bettor ", bettor);
  const totalBet = await Operator.totalOperatorBet();
  console.log("Total Pool Size in Opeartor :", totalBet);
  //const proxy = await ethers.getContractAt("CourtV1", AdminUpgradeabilityProxy.address);
  //console.log(proxy);
  //proxy.sue(aReferee, aBettingOperator);

  


  // Getting a previously deployed contract

  /*  await YourContract.setPurpose("Hello");
  
    To take ownership of yourContract using the ownable library uncomment next line and add the 
    address you want to be the owner. 
    // yourContract.transferOwnership(YOUR_ADDRESS_HERE);

    //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  */

  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */

  // Verify your contracts with Etherscan
  // You don't want to verify on localhost
  if (chainId !== localChainId) {
    await run("verify:verify", {
      address: YourContract.address,
      contract: "contracts/OBPToken.sol:OBPToken",
      contractArguments: [],
    });
  }
};
module.exports.tags = ["YourContract"];
