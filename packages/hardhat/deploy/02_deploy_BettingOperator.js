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

  const roothash = "ddaa1b004d25cfd8a5cc6503381eb11b1b2deaf02d17e8c18ba125649f186ef8";
  //const R_length = await RefereeDeployer.allRefereesLength();
  await OBPMain.deployBettingOperator(roothash);

  const operatorAddress = await OBPMain.allOperators(roothash);
  console.log( "deployed betting operator at : ", operatorAddress);
  const RefereDeployer = await ethers.getContractAt("RefereeDeployer", OBPMain.IRDeployer());

  // const RefereeLength = await OBPMain.allRefereesLength();
  // for (i = 0; i < RefereeLength; i++) {
  //   var invitedReferee = await OBPMain.allReferees(i);
  //   console.log(invitedReferee);
  // }
  const refereeLength = await OBPMain.allRefereesLength();
  //const refereeAddress = await RefereeDeployer.getcreatedAddress(OBPMain.court(), deployer, OBPMain.OBPToken());
  var invitedReferee = await OBPMain.allReferees(refereeLength-1);
  const Operator = await ethers.getContractAt("BettingOperator", operatorAddress);
  //set the newly pushed referee as the referr of this operator
  await Operator.setReferee(invitedReferee);
  //use OBP token for betting for the sake of simplicity;
  await Operator.setBetToken(OBPMain.OBPToken());
  console.log("opertor : ", operatorAddress, "has set Referee at ",  invitedReferee);

  const valueAtStake = 10000;
  const maxBet = 10000;
  const Referee = await ethers.getContractAt("Referee", invitedReferee);
  const verify = await Referee.verify(operatorAddress, valueAtStake, maxBet, 0); 
  console.log('referee : ', invitedReferee, " has verified the operator at ",operatorAddress,  " for an valueAtStake of  :",  valueAtStake, " with a maxBet of : ", maxBet);
  // const hashcode = await RefereeDeployer.refereeCodeHash();
  // console.log(hashcode);

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
  // if (chainId !== localChainId) {
  //   await run("verify:verify", {
  //     address: YourContract.address,
  //     contract: "contracts/OBPToken.sol:OBPToken",
  //     contractArguments: [],
  //   });
  // }
};
//module.exports.tags = ["YourContract"];
