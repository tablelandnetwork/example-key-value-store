import { ethers, network, upgrades } from "hardhat";
import { writeFileSync } from "fs";
import * as dotenv from "dotenv";

async function main() {
  const Wedis = await ethers.getContractFactory("Wedis");
  const wedis = await upgrades.deployProxy(Wedis, [], {
    kind: "uups",
  });
  await wedis.deployed();

  console.log("proxy deployed to:", wedis.address, "on", network.name);

  const impl = await upgrades.erc1967.getImplementationAddress(wedis.address);
  console.log("New implementation address:", impl);

  console.log("running post deploy")
  await wedis._initRegistry();

  writeFileSync(`./.${network.name}.env`, `CONTRACT=${wedis.address}`, "utf-8");
  dotenv.config({path:`./.${network.name}.env`})
  console.log(process.env.CONTRACT, "added")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
