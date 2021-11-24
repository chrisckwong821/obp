// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();
  
  const OBPToken = await ethers.getContract("OBPToken", deployer);
  const OBPMain = await ethers.getContract("OBPMain", deployer);
  var refereeLength;
  refereeLength = await OBPMain.allRefereesLength();
  console.log("refereeLength before : ",  refereeLength);
  await OBPMain.deployReferee();
  await new Promise(resolve => setTimeout(resolve, 10000));
  refereeLength = await OBPMain.allRefereesLength();
  console.log("refereeLength after  : ",  refereeLength);
  const refereeAddress = await OBPMain.allReferees(refereeLength-1);
  console.log("DEBUG**: ", refereeAddress);
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
  // if (chainId !== localChainId) {
  //   await run("verify:verify", {
  //     address: YourContract.address,
  //     contract: "contracts/OBPToken.sol:OBPToken",
  //     contractArguments: [],
  //   });
  // }
};
//module.exports.tags = ["YourContract"];
