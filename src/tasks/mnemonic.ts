import { Wallet } from "ethers";
import { task } from "hardhat/config";

task("mnemonic", "Create a simple set of MNEMONIC").setAction(async () => {
  const mnemonic = Wallet.createRandom().mnemonic;
  console.log("MNEMONIC:", mnemonic);
});

export {};
