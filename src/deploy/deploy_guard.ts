import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  // Transaction: 0x62c1c3697401f7d2cf498bc50aa0e9682a61fef4e644245a84a3b8ce2c3ebe0a
  // Contract: 0x835257Be2CEBf1615631786cFe5DaAD5581Aa387
  console.log("deployer is:", deployer);
  await deploy("InternetNativeCompanyGuard", {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: true,
  });
};

deploy.tags = ["txguard"];
export default deploy;
