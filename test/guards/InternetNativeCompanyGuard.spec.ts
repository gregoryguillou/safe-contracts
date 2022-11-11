import { expect } from "chai";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import hre, { deployments, waffle } from "hardhat";
import { getMock, getSafeWithOwners } from "../utils/setup";
import {
  buildSafeTransaction,
  calculateSafeTransactionHash,
  executeContractCallWithSigners,
  executeTxWithSigners,
} from "../../src/utils/execution";
import { chainId } from "../utils/encoding";

describe("InternetNativeCompanyGuard", async () => {
  const [user1, user2] = waffle.provider.getWallets();

  const setupSimpleOwnerTests = deployments.createFixture(
    async ({ deployments }) => {
      await deployments.fixture();
      const safe = await getSafeWithOwners([user1.address]);
      const guardFactory = await hre.ethers.getContractFactory(
        "InternetNativeCompanyGuard",
        user1
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
    }
  );

  const setupDoubleOwnerTests = deployments.createFixture(
    async ({ deployments }) => {
      await deployments.fixture();
      const safe = await getSafeWithOwners([user1.address, user2.address]);
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
        [user1, user2]
      );
      return {
        safe,
        mock,
        guardFactory,
        guard,
      };
    }
  );

  describe("fallback", async () => {
    it("must NOT revert on fallback without value", async () => {
      const { guard } = await setupSimpleOwnerTests();
      await user1.sendTransaction({
        to: guard.address,
        data: "0xbaddad",
      });
    });
    it("should revert on fallback with value", async () => {
      const { guard } = await setupSimpleOwnerTests();
      await expect(
        user1.sendTransaction({
          to: guard.address,
          data: "0xbaddad",
          value: 1,
        })
      ).to.be.reverted;
    });
  });

  describe("checkTransaction", async () => {
    it("should fail with 1 signer", async () => {
      const { safe, mock, guard } = await setupSimpleOwnerTests();
      const nonce = await safe.nonce();
      const safeTx = buildSafeTransaction({
        to: mock.address,
        data: "0xbaddad42",
        nonce,
      });
      const safeTxHash = calculateSafeTransactionHash(
        safe,
        safeTx,
        await chainId()
      );

      await expect(executeTxWithSigners(safe, safeTx, [user1])).to.be.reverted;
    });

    it("should succeed with 1 signer and unlockedSafe", async () => {
      const { safe, mock, guard } = await setupSimpleOwnerTests();
      const nonce = await safe.nonce();
      const safeTx = buildSafeTransaction({
        to: mock.address,
        data: "0xbaddad42",
        nonce,
      });
      await expect(await guard.unlockSafe(safe.address))
        .to.emit(guard, "UnlockSafe")
        .withArgs(safe.address);
      const safeTxHash = calculateSafeTransactionHash(
        safe,
        safeTx,
        await chainId()
      );

      await expect(executeTxWithSigners(safe, safeTx, [user1])).not.to.be
        .reverted;
    });

    it("should succeed with 2 signers", async () => {
      const { safe, mock, guard } = await setupDoubleOwnerTests();
      const nonce = await safe.nonce();
      const safeTx = buildSafeTransaction({
        to: mock.address,
        data: "0xbaddad42",
        nonce,
      });
      const safeTxHash = calculateSafeTransactionHash(
        safe,
        safeTx,
        await chainId()
      );

      await expect(executeTxWithSigners(safe, safeTx, [user1, user2])).not.to.be
        .reverted;
    });
  });
});
