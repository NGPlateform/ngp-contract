import { BigNumber, ContractReceipt, ethers } from "ethers";
import { ContractInfo } from "../utils/util_contractinfo";
import { logtools } from "../utils/util_log";
import { task } from "hardhat/config";
import Web3 from "web3";
import "@nomiclabs/hardhat-etherscan";
import * as fs from "fs";

let owners = [
  "0x75bC9FBD1F907695A5ab823772F78981bE0BFC83",
  "0x9868f351041a360EaEC4e7371797Da803ab23ADB",
  "0xf137a6ded9585bA57f0e6F8fe82F48bAA8Cda172",
];

let required = 2;

export module extFoundation {
  export function RegTasks() {
    task("Foundation:initialize", "initialize").setAction(async ({}, _hre) => {
      logtools.logyellow("method == [Foundation:initialize]");
      await ContractInfo.LoadFromFile(_hre);

      let contrat = await ContractInfo.getContract("Foundation");
      logtools.logblue("Foundation = " + contrat.address);

      let ngpAddr = await ContractInfo.getContractProxy("NGP", "NGPProxy");

      logtools.logblue("ngpAddr = " + ngpAddr.address);

      let tran = await contrat.initialize(owners, required, ngpAddr.address);
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
