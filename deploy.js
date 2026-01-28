const hre = require("hardhat");

async function main() {
  const CrowdFund = await hre.ethers.getContractFactory("CrowdFund");
  const crowdFund = await CrowdFund.deploy();

  await crowdFund.waitForDeployment();

  console.log(`CrowdFund deployed to ${crowdFund.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
