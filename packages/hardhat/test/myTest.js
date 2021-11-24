const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("OBP", function () {
  let OBPToken;
  let LogicLib;
  let Proxy;
  let OBPMain;
  let RefereeDeployer;
  let BettingOperatorDeployer;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  describe("OBPToken", function () {
    it("Should deploy OBPToken", async function () {
      const obpToken = await ethers.getContractFactory("OBPToken");
      OBPToken = await obpToken.deploy();
    });
  });
  describe("CourtLib", function () {
    it("Should deploy Proxy", async function () {
      const logicLib = await ethers.getContractFactory("CourtV1");
      LogicLib = await logicLib.deploy();
    });
  });
  describe("AdminUpgradeabilityProxy", function () {
    it("Should deploy Proxy", async function () {
      const proxy = await ethers.getContractFactory("AdminUpgradeabilityProxy");
      Proxy = await proxy.deploy(LogicLib.address, OBPToken.address, "0x");
    });
  });
  describe("OBPMain", function () {
    it("Should deploy OBPMain", async function () {
      const obpMain = await ethers.getContractFactory("OBPMain");
      OBPMain = await obpMain.deploy(OBPToken.address, Proxy.address);
    });
  });
  describe("RefereeDeployer", function () {
    it("Should deploy OBRefereeDeployerPMain", async function () {
      const refereeDeployer = await ethers.getContractFactory("RefereeDeployer");
      RefereeDeployer = await refereeDeployer.deploy();
    });
  });
  describe("BettingOperatorDeployer", function () {
    it("Should be able to deploy a new BettingOperatorDeployer", async function () {
      const bettingOperatorDeployer = await ethers.getContractFactory("BettingOperatorDeployer");
      BettingOperatorDeployer = await bettingOperatorDeployer.deploy();
    });
  });
  describe("setRefereDeployer", function () {
    it("Should be able to set a new RefereDeployer", async function () {
      await OBPMain.setRefereeOperatorDeployer(RefereeDeployer.address);
      expect(await OBPMain.IRDeployer()).to.equal(RefereeDeployer.address);
    });
  });
  describe("setBettingOperatorDeployer", function () {
    it("Should be able to set a new BettingOperatorDeployer", async function () {
      await OBPMain.setBettingOperatorDeployer(BettingOperatorDeployer.address);
      expect(await OBPMain.IBODeployer()).to.equal(BettingOperatorDeployer.address);
    });
  });
});
