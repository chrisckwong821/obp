// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();
  
  const OBPToken = await ethers.getContract("OBPToken", deployer);
  const OBPMain = await ethers.getContract("OBPMain", deployer);
  const RefereeDeployer = await ethers.getContract("RefereeDeployer", deployer);
  //const BettingOperatorDeployer = await ethers.getContract("BettingOperatorDeployer", deployer);


  // var R_length = await RefereeDeployer.allRefereesLength();
  // //const OB_length = await BettingOperatorDeployer.allOperatorsLength();
  // console.log(R_length, "number of referee");
   const deployedReferee = await OBPMain.deployReferee();
  // console.log(R_length, "number of referee after deployment");
  // // bond some OBP into the referee.
   const refereeAddress = await RefereeDeployer.getcreatedAddress(OBPMain.court(), deployer, OBPMain.OBPToken());
  // console.log( "deployed referee at : ", refereeAddress);

  
  const _amountToBound = 10000;
  const approve = await OBPToken.approve(refereeAddress, _amountToBound);
  const approveResult = await OBPToken.allowance(deployer, refereeAddress);
  const Referee = await ethers.getContractAt("Referee", refereeAddress);

  const bondedOBP = await Referee.participate(_amountToBound);
  console.log("deployer ", deployer, " bounded amountToBound : ",_amountToBound,  "at Referee", refereeAddress);


  const refereDeployer = await ethers.getContract("RefereeDeployer", deployer);

  //console.log(OB_length2, "number of referee after deployment");

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
