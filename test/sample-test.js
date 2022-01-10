const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("IlliquidDAOStaking", function () {
  it("Should return the new greeting once it's changed", async function () {
    const DAO = await ethers.getContractFactory("IlliquidDAOStaking");
    const dao = await DAO.deploy("0x3b484b82567a09e2588A13D54D032153f0c0aEe0", 1643500800, 31536000);
    await dao.deployed();

    // expect(await greeter.greet()).to.equal("Hello, world!");

    // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // // wait until the transaction is mined
    // await setGreetingTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});

