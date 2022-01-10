const { expect } = require("chai");
const { ethers } = require("hardhat");

let DAO;
let dao;
let owner;
let addr1;
let addr2;
let addrs;

beforeEach(async function () {
  // Get the ContractFactory and Signers here.
  DAO = await ethers.getContractFactory("IlliquidDAOStaking");
  [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

  // To deploy our contract, we just have to call Token.deploy() and await
  // for it to be deployed(), which happens once its transaction has been
  // mined.
  dao = await DAO.deploy("0xb1224D9254dDe8efdA041d2F50C4a7CF3A22CD29", 1643500800, 31536000);
});

describe("IlliquidDAOStaking", function () {
  it("Should set the right owner", async function () {
    // Expect receives a value, and wraps it in an Assertion object. These
    // objects have a lot of utility methods to assert values.

    // This test expects the owner variable stored in the contract to be equal
    // to our Signer's owner.
    expect(await dao.owner()).to.equal(owner.address);
  });


  it("Adding reward", async function () {
    await dao.addRewardIlliquidDAO(100);
    let conf = await dao.config();
    expect(conf.totalReward).to.equal(100);
  });


  it("Enter test", async function () {
    await dao.addRewardIlliquidDAO(100);
    let conf = await dao.config();
    expect(conf.totalReward).to.equal(100);
  });


});

