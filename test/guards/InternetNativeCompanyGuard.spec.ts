import { expect } from "chai";
import hre, { deployments, waffle } from "hardhat";
import "@nomiclabs/hardhat-ethers";
import { getMock, getSafeWithOwners } from "../utils/setup";
import {
  buildSafeTransaction,
  calculateSafeTransactionHash,
  executeContractCallWithSigners,
  executeTxWithSigners,
} from "../../src/utils/execution";
import { chainId } from "../utils/encoding";

describe("InternetNativeCompanyGuard", async () => {
  const [user1] = waffle.provider.getWallets();

  const setupTests = deployments.createFixture(async ({ deployments }) => {
    await deployments.fixture();
    const safe = await getSafeWithOwners([user1.address]);
    const guardFactory = await hre.ethers.getContractFactory(
      "InternetNativeCompanyGuard"
    );
    const guard = await guardFactory.deploy();
    const mock = await getMock();
    await executeContractCallWithSigners(
      safe,
      safe,
      "setGuard",
      [guard.address],
      [user1]
    );
    return {
      safe,
      mock,
      guardFactory,
      guard,
    };
  });

  describe("fallback", async () => {
    it("must NOT revert on fallback without value", async () => {
      const { guard } = await setupTests();
      await user1.sendTransaction({
        to: guard.address,
        data: "0xbaddad",
      });
    });
    it("should revert on fallback with value", async () => {
      const { guard } = await setupTests();
      await expect(
        user1.sendTransaction({
          to: guard.address,
          data: "0xbaddad",
          value: 1,
        })
      ).to.be.reverted;
    });
  });
});
