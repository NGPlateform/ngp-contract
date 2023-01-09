import { BigNumber, ContractReceipt, ethers } from "ethers";
import { ContractInfo } from "../utils/util_contractinfo";
import { logtools } from "../utils/util_log";
import { task } from "hardhat/config";
import Web3 from "web3";
import "@nomiclabs/hardhat-etherscan";
import * as fs from "fs";

export module extNGP {
  export function RegTasks() {
    task("NGP:mintNGP", "mintNGP").setAction(async ({}, _hre) => {
      logtools.logyellow("method == [NGP:mintNGP]");
      await ContractInfo.LoadFromFile(_hre);

      let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

      let tran = await contrat.mintNGP(1);
      let recipt: ContractReceipt = await tran.wait();
      logtools.loggreen("result = [");
      logtools.loggreen("     hash = " + recipt.transactionHash);
      logtools.loggreen("     status = " + recipt.status);
      logtools.loggreen("]");
      logtools.logcyan(
        "矿工费" +
          ethers.utils.formatUnits(
            recipt.gasUsed.mul(5000000000),
            BigNumber.from("18")
          )
      );
    });
  }
}
