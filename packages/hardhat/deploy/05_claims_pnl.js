// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

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
  //const proxy = await ethers.getContractAt("CourtV1", AdminUpgradeabilityProxy.address);
  //console.log(proxy);
  //proxy.sue(aReferee, aBettingOperator);
  //assume Pool1 has money to draw
  const WinPool = 1;
  const amountToDraw = await Operator.checkPayoutByAddress(deployer, WinPool);
  console.log("winning amount in Pool : ", WinPool, "for this amount :", amountToDraw);
  //draw money to myself
  await Operator.withdraw(WinPool, deployer);

  // Court, Operator, Refereee are all eligible to draw their portion:
  const unclaimedFeeToOperator = await Operator.unclaimedFeeToOperator();
  const unclaimedFeeToReferee = await Operator.unclaimedFeeToReferee();
  const unclaimedFeeToCourt = await Operator.unclaimedFeeToCourt();
  console.log("Operator can get : ", unclaimedFeeToOperator);
  console.log("Referee can get : ", unclaimedFeeToReferee);
  console.log("Court can get : ", unclaimedFeeToCourt);
  await Operator.withdrawRefereeFee(unclaimedFeeToReferee);
  await Operator.withdrawCourtFee(unclaimedFeeToOperator);
  await Operator.withdrawOperatorFee(unclaimedFeeToCourt, deployer);


  


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
