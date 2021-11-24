// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");
//const {web3} = require('web3');
const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();
  
  const OBPToken = await ethers.getContract("OBPToken", deployer);
  const OBPMain = await ethers.getContract("OBPMain", deployer);
  const BettingOperatorDeployer = await ethers.getContract("BettingOperatorDeployer", deployer);
  const roothash = "1231234567";
  const operatorAddress = await OBPMain.allOperators(roothash);
  const Operator = await ethers.getContractAt("BettingOperator", operatorAddress);
  const refereeAddress = await Operator.referee();
  //result can be anounced; then close. Cosing an event allow winner to claim their payout
  //basically it means a payout of Pool1 {3} Pool2 {0}, last 8 bytes is a timestamp
  const prefix = "0x";
  const result1 = "00000000000000000000000000010000000000000000000000000b226190ac07"
  const result2 = "000000000000000000000000000200000000000000000000000000006190ac07"
  //web3.eth.abi.encodeParameter('bytes32[]', [result1, result2])
  const result = prefix + result1 + result2; //"0x0000000000000000000000000001000000000000000000000000000361904d560000000000000000000000000002000000000000000000000000000061904d56";
  const Referee = await ethers.getContractAt("Referee", refereeAddress);
   await Referee.anounceResult(operatorAddress, result);
   const checkResult = await Referee.results(operatorAddress);
   console.log("checking result for operator : ", operatorAddress, " : ", checkResult);
  // // after waiting for the arbitrationTime (1 sec in this demo);
  await new Promise(resolve => setTimeout(resolve, 1000));
  //await Referee.pushResult(operatorAddress, 1);
  //await Referee.pushResult(operatorAddress, 2);
  //await Referee.closeItem(operatorAddress, 1);
  //await Referee.closeItem(operatorAddress, 2);
  await Referee.pushResultBatch(operatorAddress);
  await Referee.closeItemBatch(operatorAddress);
  
  const Pool1 = await Operator.bettingItems(1);
  const Pool2 = await Operator.bettingItems(2);
  console.log("pool1 :  ", Pool1);
  console.log("pool1 :  ", Pool2);

   
  


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
