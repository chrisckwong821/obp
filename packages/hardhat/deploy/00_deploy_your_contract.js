// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  await deploy("OBPToken", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
  });
  await deploy("CourtV1", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
  });
  const OBPToken = await ethers.getContract("OBPToken", deployer);
  const CourtV1 = await ethers.getContract("CourtV1", deployer);

  await deploy("AdminUpgradeabilityProxy", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [ CourtV1.address, OBPToken.address, "0x"],
    log: true,
  });
  const AdminUpgradeabilityProxy = await ethers.getContract("AdminUpgradeabilityProxy", deployer);

  await deploy("OBPMain", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [ OBPToken.address, AdminUpgradeabilityProxy.address],
    log: true,
  });

  await deploy("RefereeDeployer", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
  });
  await deploy("BettingOperatorDeployer", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
  });
  const OBPMain = await ethers.getContract("OBPMain", deployer);
  const RefereeDeployer = await ethers.getContract("RefereeDeployer", deployer);
  const BettingOperatorDeployer = await ethers.getContract("BettingOperatorDeployer", deployer);

  await OBPMain.setRefereeOperatorDeployer(RefereeDeployer.address);
  
  await OBPMain.setBettingOperatorDeployer(BettingOperatorDeployer.address);

  const R_length = await RefereeDeployer.allRefereesLength();
  const OB_length = await BettingOperatorDeployer.allOperatorsLength();
  console.log(R_length, "old");
  console.log(OB_length, "old");

  //console.log(RefereeDeployer);
  await OBPMain.deployReferee();
  await OBPMain.deployBettingOperator(123);
  //console.log(hash);
  const length_ = await RefereeDeployer.allRefereesLength();
  for (i = 0; i < length_; i++) {
    var allR = await RefereeDeployer.allReferees(i);
    console.log(allR);
  }
  const length__ = await BettingOperatorDeployer.allOperatorsLength();
  for (i = 0; i < length__; i++) {
    var allR = await BettingOperatorDeployer.allOperators(i);
    console.log(allR);
  }
  

  // const hashcode = await RefereeDeployer.refereeCodeHash();
  // console.log(hashcode);

  const proxy = await ethers.getContractAt("CourtV1", AdminUpgradeabilityProxy.address);
  //console.log(proxy);
  //proxy.sue(aReferee, aBettingOperator);


  const R_length2 = await RefereeDeployer.allRefereesLength();
  const OB_length2 = await BettingOperatorDeployer.allOperatorsLength();
  console.log(R_length2, "should be +1 from old");
  console.log(OB_length2, "should be +1 from old");


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
